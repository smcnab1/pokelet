import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { api, listing, beta, newerBeta, stable } from "./release-fixtures.mjs";

const require = createRequire(import.meta.url);
const { chromium, firefox, webkit, devices } = require("playwright");
const { default: AxeBuilder } = require("@axe-core/playwright");
const url = process.env.POKELET_SITE_URL ?? "http://127.0.0.1:4173/pokelet/";

async function mockReleases(page, data = [beta]) {
  await page.route(`${api}?*`, (route) => route.fulfill({ json: data, headers: { "Access-Control-Allow-Origin": "*" } }));
}

function collectErrors(page) {
  const errors = [];
  page.on("console", (message) => {
    if (message.type() === "error" || message.type() === "warning") errors.push(`${message.location().url} ${message.text()}`.trim());
  });
  page.on("pageerror", (error) => errors.push(error.message));
  page.on("response", (response) => {
    if (response.status() >= 400) errors.push(`${response.status()} ${response.url()}`);
  });
  return errors;
}

async function waitForCursor(page, name) {
  await page.waitForFunction((stem) => {
    const selectors = ["header .brand", ".hero h1", ".feature-copy", "#install a", ".faq-list summary", ".site-footer a"];
    return selectors.every((selector) =>
      getComputedStyle(document.querySelector(selector)).cursor.includes(`${stem}-cursor.png") 16 8`));
  }, name);
}

async function waitForDownload(page, href) {
  await page.waitForFunction((expected) =>
    [...document.querySelectorAll("a[data-download]")].every((link) => link.href === expected), href);
}

async function observeClicks(page) {
  await page.evaluate(() => {
    for (const type of ["click", "contextmenu", "dblclick"]) {
      document.addEventListener(type, (event) => {
        const sprite = document.querySelector(".live-pointer");
        const art = sprite.querySelector("img");
        const effect = document.querySelector(".impact svg").getAnimations()[0];
        const point = new DOMMatrixReadOnly(sprite.style.transform);
        document.body.dataset.observed = JSON.stringify({
          type, preventsDefault: event.defaultPrevented,
          hidesCursor: getComputedStyle(event.target).cursor === "none",
          capturesEvents: getComputedStyle(sprite).pointerEvents !== "none",
          hotspot: [point.e - event.clientX, point.f - event.clientY],
          characterAnimation: art.getAnimations().length,
          characterScale: art.getAnimations()[0]?.effect.getKeyframes()[1].scale,
          effect: effect?.effect.getKeyframes().at(-1),
        });
      });
    }
  });
}

const observed = async (page) => JSON.parse(await page.locator("body").getAttribute("data-observed"));
const picker = (page) => page.locator(".cursor-picker summary");

async function desktop(browser) {
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 }, colorScheme: "light", deviceScaleFactor: 2 });
  page.setDefaultTimeout(12_000);
  const errors = collectErrors(page);
  try {
    await mockReleases(page);
    assert.equal((await page.goto(url)).status(), 200);
    await waitForDownload(page, beta.assets[0].browser_download_url);
    assert.equal(await page.title(), "Pokelet · Free animated cursor for macOS");
    await waitForCursor(page, "finger-original");
    await observeClicks(page);

    await page.locator(".intro").click();
    const first = await observed(page);
    assert.equal(first.hidesCursor, true);
    assert.equal(first.capturesEvents, false);
    assert.equal(first.characterAnimation, 1);
    assert(first.hotspot.every((offset) => Math.abs(offset) < 1));

    await page.mouse.move(-5, -5);
    await page.waitForFunction(() => !document.documentElement.hasAttribute("data-cursor-reaction"));
    await page.mouse.move(8, 90);
    await waitForCursor(page, "finger-original");
    await page.locator(".intro").dblclick();
    assert.equal((await observed(page)).type, "dblclick");
    await page.evaluate(() => getSelection().removeAllRanges());

    await picker(page).press("Enter");
    const colour = page.getByLabel("Colour", { exact: true });
    assert(await colour.isVisible());
    assert(!((await colour.evaluate((select) => getComputedStyle(select).cursor)).includes("url(")));
    assert.equal(await page.getByLabel("Sound", { exact: true }).isChecked(), false);
    const response = page.getByLabel("Click response");
    await response.selectOption("4");
    await page.locator(".intro").click();
    assert(Number((await observed(page)).characterScale.split(" ")[0]) > Number(first.characterScale.split(" ")[0]));
    await picker(page).press("Enter");
    await response.selectOption("2");

    for (const [label, stem] of [["The Finger", "finger"], ["Cat Paw", "catPaw"], ["Foam Finger", "foamFinger"], ["Comic Arrow", "comicArrow"]]) {
      await page.getByRole("radio", { name: label }).check();
      for (const variant of ["black", "white", "original"]) {
        await colour.selectOption(variant);
        await waitForCursor(page, `${stem}-${variant}`);
        const artwork = await page.locator(`[data-character="${stem}"] img`).evaluate((image) => image.src);
        assert(artwork.endsWith(`/assets/characters/${stem}-${variant}.webp`));
      }
    }
    await page.getByRole("radio", { name: "The Finger" }).press("ArrowRight");
    assert(await page.getByRole("radio", { name: "Cat Paw" }).isChecked());
    await waitForCursor(page, "catPaw-original");
    const soundResponse = page.waitForResponse((response) => response.url().endsWith("/assets/tap.wav"));
    await page.getByLabel("Sound", { exact: true }).check();
    assert((await soundResponse).ok());
    await page.getByLabel("Sound", { exact: true }).uncheck();

    const reset = page.getByRole("button", { name: "Use normal cursor" });
    await reset.click();
    assert.equal(await reset.getAttribute("aria-pressed"), "true");
    assert.equal(await page.locator("html").getAttribute("data-pokelet"), null);
    await page.reload();
    assert.equal(await page.locator("html").getAttribute("data-pokelet"), null);
    await picker(page).press("Enter");
    assert.equal(await reset.getAttribute("aria-pressed"), "true");
    await reset.click();
    await waitForCursor(page, "catPaw-original");
    await page.keyboard.press("Escape");
    assert.equal(await colour.isVisible(), false);
    assert.equal(await picker(page).evaluate((summary) => document.activeElement === summary), true);

    await observeClicks(page);
    await page.locator(".intro").click({ button: "right" });
    const right = await observed(page);
    assert.equal(right.type, "contextmenu");
    assert.equal(right.preventsDefault, false);
    assert.equal(right.hidesCursor, false);
    await page.keyboard.press("Escape");

    const copy = page.locator(".intro");
    const copyBox = await copy.boundingBox();
    await page.mouse.move(copyBox.x + 2, copyBox.y + 12);
    await page.mouse.down();
    await page.mouse.move(copyBox.x + 174, copyBox.y + 12, { steps: 8 });
    await page.mouse.up();
    assert.match(await page.evaluate(() => String(getSelection())), /Four animated/);
    await page.evaluate(() => getSelection().removeAllRanges());

    const download = page.locator(".hero a[data-download]");
    await download.evaluate((link) => link.addEventListener("dragstart", (event) => {
      link.dataset.dragged = String(!event.defaultPrevented && event.dataTransfer.types.includes("text/uri-list"));
    }));
    const box = await download.boundingBox();
    await page.mouse.move(box.x + 35, box.y + box.height / 2);
    await page.mouse.down();
    await page.mouse.move(box.x + box.width + 30, box.y + box.height / 2, { steps: 8 });
    await page.mouse.up();
    assert.equal(await download.getAttribute("data-dragged"), "true");

    // The fixture catches CSS inheritance and native editing regressions without adding a public input box.
    await page.locator(".hero-copy").evaluate((copy) => {
      const input = document.createElement("input");
      input.setAttribute("aria-label", "Test editor");
      copy.append(input);
    });
    const editor = page.getByRole("textbox", { name: "Test editor" });
    assert.equal(await editor.evaluate((input) => getComputedStyle(input).cursor), "text");
    await editor.fill("Native editing");
    assert.equal(await editor.inputValue(), "Native editing");
    await editor.evaluate((input) => input.remove());

    await page.getByRole("link", { name: "Installation", exact: true }).click();
    assert.equal(new URL(page.url()).hash, "#install");
    assert([200, 304].includes((await page.reload()).status()));
    await waitForCursor(page, "catPaw-original");
    await waitForDownload(page, beta.assets[0].browser_download_url);
    const faq = page.getByText("Does it need special permissions?", { exact: true });
    await faq.press("Enter");
    assert(await faq.locator("..").evaluate((details) => details.open));

    await observeClicks(page);
    await page.emulateMedia({ reducedMotion: "reduce" });
    await faq.click();
    const reduced = await observed(page);
    assert.equal(reduced.hidesCursor, false);
    assert.equal(reduced.characterAnimation, 0);
    assert(!("scale" in reduced.effect));
    assert.deepEqual(errors, []);
  } finally {
    await page.close();
  }
}

async function responsive(browser) {
  for (const width of [320, 375, 768, 1280, 1920]) {
    const page = await browser.newPage({ viewport: { width, height: 850 } });
    try {
      await mockReleases(page);
      await page.goto(url);
      await picker(page).click();
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth), width);
      assert(await page.getByLabel("Colour", { exact: true }).isVisible());
    } finally {
      await page.close();
    }
  }
}

async function touchscreen(browser) {
  const page = await browser.newPage({ ...devices["iPhone 13"], viewport: { width: 375, height: 812 } });
  const errors = collectErrors(page);
  try {
    await mockReleases(page);
    await page.goto(url);
    await observeClicks(page);
    await page.locator(".hero-cat").tap();
    assert.equal(await page.locator(".hero-cat").getAttribute("aria-pressed"), "true");
    const tap = await observed(page);
    assert.equal(tap.hidesCursor, false);
    assert.equal(tap.characterAnimation, 0);
    assert(tap.effect);
    assert.equal(await page.locator("html").getAttribute("data-pokelet"), null);
    await page.getByRole("button", { name: "Menu" }).tap();
    await page.getByRole("link", { name: "Features", exact: true }).tap();
    assert.equal(new URL(page.url()).hash, "#features");
    assert.deepEqual(errors, []);
  } finally {
    await page.close();
  }
}

async function downloads(browser) {
  const page = await browser.newPage();
  try {
    await page.clock.install();
    let requests = 0;
    let state = "beta";
    await page.route(`${api}?*`, (route) => {
      requests += 1;
      const headers = { "Access-Control-Allow-Origin": "*", "Access-Control-Expose-Headers": "Link" };
      const nextPage = new URL(route.request().url()).searchParams.get("page") === "2";
      if (state === "failure") return route.fulfill({ status: 503, body: "Service unavailable", headers });
      if (state === "stable" && !nextPage) headers.Link = '<https://api.github.com/repositories/123/releases?page=2>; rel="next"';
      const json = state === "beta" ? [beta] : state === "new" ? [beta, newerBeta] : nextPage ? [stable] : [newerBeta];
      return route.fulfill({ json, headers });
    });
    await page.goto(url);
    await waitForDownload(page, beta.assets[0].browser_download_url);
    await page.reload();
    await waitForDownload(page, beta.assets[0].browser_download_url);
    assert.equal(requests, 1);
    state = "new";
    await page.clock.fastForward(300_100);
    await waitForDownload(page, newerBeta.assets[0].browser_download_url);
    assert.equal(requests, 2);
    state = "stable";
    await page.clock.fastForward(300_100);
    await waitForDownload(page, stable.assets[0].browser_download_url);
    assert.equal(requests, 4);
    state = "failure";
    await page.clock.fastForward(300_100);
    await waitForDownload(page, listing);
    assert.equal(await page.locator(".hero .download-label").textContent(), "Get Pokelet");
  } finally {
    await page.close();
  }
}

async function accessibility(browser) {
  for (const colorScheme of ["light", "dark"]) {
    const context = await browser.newContext({ viewport: { width: 375, height: 812 }, colorScheme });
    try {
      const page = await context.newPage();
      await mockReleases(page);
      await page.goto(url);
      await picker(page).click();
      const { violations } = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"]).analyze();
      assert.deepEqual(violations.map(({ id, nodes }) => ({ id, targets: nodes.map(({ target }) => target) })), []);
    } finally {
      await context.close();
    }
  }
}

for (const [name, engine] of [["Chromium", chromium], ["Firefox", firefox], ["WebKit", webkit]]) {
  const channel = engine === chromium ? process.env.POKELET_CHROME_CHANNEL : undefined;
  const browser = await engine.launch({ channel });
  try {
    await desktop(browser);
    await responsive(browser);
    if (engine !== firefox) await touchscreen(browser);
    if (engine === chromium) {
      await downloads(browser);
      await accessibility(browser);
      const noScript = await browser.newPage({ javaScriptEnabled: false });
      await noScript.goto(url);
      await waitForDownload(noScript, listing);
      assert.equal(await picker(noScript).isVisible(), false);
      await noScript.close();
    }
    console.log(`${name} ${browser.version()} passed`);
  } finally {
    await browser.close();
  }
}
