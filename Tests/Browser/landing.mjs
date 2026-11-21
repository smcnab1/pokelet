import assert from "node:assert/strict";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { chromium, firefox, webkit, devices } = require("playwright");
const { default: AxeBuilder } = require("@axe-core/playwright");
const url = process.env.POKELET_SITE_URL ?? "http://127.0.0.1:4173/pokelet/";
const download = "https://github.com/smcnab1/pokelet/releases/download/v1.1.0-beta.1/Pokelet-1.1.0-unnotarised.dmg";

function collectErrors(page) {
  const errors = [];
  page.on("console", (message) => {
    if (message.type() === "error" || message.type() === "warning") errors.push(message.text());
  });
  page.on("pageerror", (error) => errors.push(error.message));
  page.on("response", (response) => {
    if (response.status() >= 400) errors.push(`${response.status()} ${response.url()}`);
  });
  return errors;
}

async function waitForCursor(page, name) {
  await page.waitForFunction((stem) =>
    getComputedStyle(document.querySelector(".play-target")).cursor.includes(`${stem}-cursor.png") 16 8`), name);
}

async function checkImages(page) {
  await page.evaluate(async () => {
    await Promise.all([...document.images].map((image) => {
      image.loading = "eager";
      return image.decode();
    }));
  });
}

// Snapshot the reaction on the click itself so assertions do not race the 245 ms animation.
async function observeClicks(page) {
  await page.locator(".play-target").evaluate((target) => {
    target.addEventListener("click", (event) => {
      const surface = target.parentElement;
      const live = surface.querySelector(".live-pointer");
      const image = live.querySelector("img");
      const poster = surface.querySelector(".stage-character");
      const impact = surface.querySelector(".impact").getAnimations()[0];
      const bounds = target.getBoundingClientRect();
      const point = live.getBoundingClientRect();
      const impactPosition = new DOMMatrixReadOnly(surface.querySelector(".impact").style.transform);
      target.dataset.observed = JSON.stringify({
        hidesCursor: getComputedStyle(target).cursor === "none",
        hotspot: [point.x - event.clientX, point.y - event.clientY],
        effectAtClick: Math.abs(impactPosition.e + bounds.left - event.clientX) < 0.5 &&
          Math.abs(impactPosition.f + bounds.top - event.clientY) < 0.5,
        pointerAnimation: image.getAnimations().length,
        posterAnimation: poster.getAnimations().length,
        reactionScale: (image.getAnimations()[0] ?? poster.getAnimations()[0])?.effect.getKeyframes()[1].scale,
        effect: impact?.effect.getKeyframes().at(-1),
      });
    });
  });
}

async function desktop(browser) {
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 }, colorScheme: "light" });
  const errors = collectErrors(page);
  page.setDefaultTimeout(10_000);
  try {
    assert.equal((await page.goto(url)).status(), 200);
    await checkImages(page);
    assert.equal(await page.title(), "Pokelet · Free animated cursor for macOS");
    assert.equal(await page.locator(".hero .button").getAttribute("href"), download);
    assert.equal(await page.locator(".nav-github").getAttribute("href"), "https://github.com/smcnab1/pokelet");
    assert.equal(await page.locator('link[rel="canonical"]').getAttribute("href"), "https://smcnab1.github.io/pokelet/");

    const hero = page.getByRole("button", { name: "Click to poke" });
    await hero.press("Enter");
    assert(await page.locator(".hero-character").first().evaluate((art) => art.getAnimations().length > 0));

    await page.getByRole("link", { name: "Try it in your browser" }).click();
    assert.equal(new URL(page.url()).hash, "#try");
    const target = page.getByRole("button", { name: "Play a click reaction" });
    assert(await page.locator("#play-hint").isVisible());
    assert.match(await page.locator("#play-hint").innerText(), /Click\s+anywhere in this area/);
    const colour = page.getByLabel("Colour", { exact: true });
    const response = page.getByLabel("Click response");
    const sound = page.getByLabel("Sound", { exact: true });
    assert.equal(await sound.isChecked(), false);

    for (const [label, stem] of [
      ["The Finger", "finger"], ["Cat Paw", "catPaw"], ["Foam Finger", "foamFinger"], ["Comic Arrow", "comicArrow"],
    ]) {
      await page.getByRole("radio", { name: label }).check();
      for (const variant of ["black", "white", "original"]) {
        await colour.selectOption(variant);
        await waitForCursor(page, `${stem}-${variant}`);
        await page.locator(".stage-character").evaluate((image) => image.decode());
        assert.match(await page.locator(".stage-character").getAttribute("src"), new RegExp(`${stem}-${variant}\\.webp$`));
      }
    }

    await page.getByRole("radio", { name: "The Finger" }).press("ArrowRight");
    assert(await page.getByRole("radio", { name: "Cat Paw" }).isChecked());
    await waitForCursor(page, "catPaw-original");
    await observeClicks(page);
    const observation = async () => JSON.parse(await target.getAttribute("data-observed"));

    await response.selectOption("0");
    await target.click({ position: { x: 109, y: 90 } });
    const soft = await observation();
    assert.equal(soft.pointerAnimation, 1);
    assert.equal(soft.posterAnimation, 0);
    assert.equal(soft.hidesCursor, true);
    assert(soft.effectAtClick);
    assert(soft.hotspot.every((offset) => Math.abs(offset) < 1));
    await page.waitForFunction(() => !document.querySelector(".play-target").classList.contains("is-animating"));

    await response.selectOption("4");
    await target.click({ position: { x: 112, y: 92 } });
    const strong = await observation();
    assert(Number(strong.reactionScale.split(" ")[0]) > Number(soft.reactionScale.split(" ")[0]));
    await target.click({ position: { x: 114, y: 94 } });
    assert(Number((await observation()).reactionScale.split(" ")[0]) > Number(strong.reactionScale.split(" ")[0]));

    await target.press("Space");
    const keyboard = await observation();
    assert.equal(keyboard.hidesCursor, false);
    assert.equal(keyboard.posterAnimation, 1);

    const audio = page.waitForResponse((result) => result.url().endsWith("/assets/tap.wav"));
    await sound.check();
    assert((await audio).ok());
    await sound.uncheck();

    const reset = page.getByRole("button", { name: "Use normal cursor" });
    await reset.click();
    assert.equal(await reset.getAttribute("aria-pressed"), "true");
    assert.equal(await target.evaluate((element) => getComputedStyle(element).cursor), "auto");
    assert(await target.isDisabled());
    assert(await page.getByText("Normal cursor active", { exact: true }).isVisible());
    await reset.click();
    await waitForCursor(page, "catPaw-original");

    await target.evaluate((button) => button.addEventListener("contextmenu", (event) => {
      button.dataset.contextMenuPreserved = String(!event.defaultPrevented);
    }));
    await target.click({ button: "right" });
    assert.equal(await target.getAttribute("data-context-menu-preserved"), "true");
    await page.keyboard.press("Escape");

    const text = page.locator("#try .section-heading p");
    await text.scrollIntoViewIfNeeded();
    const box = await text.boundingBox();
    await page.mouse.move(box.x + 2, box.y + box.height / 2);
    await page.mouse.down();
    await page.mouse.move(box.x + 168, box.y + box.height / 2, { steps: 8 });
    await page.mouse.up();
    assert.match(await page.evaluate(() => String(getSelection())), /Pick a character/);

    const downloadLink = page.getByRole("link", { name: "Download Pokelet" });
    await downloadLink.scrollIntoViewIfNeeded();
    await downloadLink.evaluate((link) => link.addEventListener("dragstart", (event) => {
      link.dataset.dragged = String(!event.defaultPrevented && event.dataTransfer.types.includes("text/uri-list"));
    }));
    const linkBox = await downloadLink.boundingBox();
    await page.mouse.move(linkBox.x + 50, linkBox.y + linkBox.height / 2);
    await page.mouse.down();
    await page.mouse.move(linkBox.x + linkBox.width + 30, linkBox.y + linkBox.height / 2, { steps: 6 });
    await page.mouse.up();
    assert.equal(await downloadLink.getAttribute("data-dragged"), "true");

    const faq = page.getByText("Does it need special permissions?", { exact: true });
    await faq.press("Enter");
    assert(await faq.locator("..").evaluate((details) => details.open));
    await faq.press("Enter");
    assert.equal(await faq.locator("..").evaluate((details) => details.open), false);

    const direct = new URL("#install", url).href;
    await page.goto(direct);
    assert([200, 304].includes((await page.reload()).status()));
    assert.equal(page.url(), direct);
    assert.equal(await page.locator("#install .button").getAttribute("href"), download);
    assert(await page.getByRole("heading", { name: "Install Pokelet" }).isVisible());
    assert((await page.request.get(new URL("sitemap.xml", url).href)).ok());
    assert((await page.request.get(new URL("assets/pokelet-social.jpg", url).href)).ok());

    await page.emulateMedia({ reducedMotion: "reduce" });
    // Full reload clears the click observer and restores the initial character.
    await observeClicks(page);
    await target.click({ position: { x: 100, y: 100 } });
    const reduced = await observation();
    assert.equal(reduced.hidesCursor, false);
    assert.equal(reduced.pointerAnimation + reduced.posterAnimation, 0);
    assert(!("scale" in reduced.effect));
    assert.deepEqual(errors, []);
  } finally {
    await page.close();
  }
}

async function responsive(browser) {
  for (const width of [375, 768, 1280, 1920]) {
    const page = await browser.newPage({ viewport: { width, height: 850 }, colorScheme: "light" });
    try {
      await page.goto(url);
      await checkImages(page);
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth), width);
      assert(await page.getByRole("heading", { level: 1 }).isVisible());
    } finally {
      await page.close();
    }
  }
}

async function touchscreen(browser) {
  const page = await browser.newPage({ ...devices["iPhone 13"], viewport: { width: 375, height: 812 } });
  const errors = collectErrors(page);
  try {
    await page.goto(url);
    const menu = page.getByRole("button", { name: "Menu" });
    await menu.tap();
    await page.getByRole("link", { name: "Try it", exact: true }).tap();
    assert.equal(await menu.getAttribute("aria-expanded"), "false");
    assert.equal(new URL(page.url()).hash, "#try");
    assert.equal(await page.locator("#try").evaluate((section) => section === document.activeElement), true);
    assert(await page.getByRole("button", { name: "Tap to poke" }).isVisible());
    assert(await page.locator("#play-hint").isVisible());
    assert.match(await page.locator("#play-hint").innerText(), /Tap\s+anywhere in this area/);
    await page.getByRole("radio", { name: "Foam Finger" }).tap();
    await page.locator(".stage-character").evaluate((image) => image.decode());
    await observeClicks(page);
    const target = page.getByRole("button", { name: "Play a click reaction" });
    await target.tap();
    const tap = JSON.parse(await target.getAttribute("data-observed"));
    assert.equal(tap.hidesCursor, false);
    assert.equal(tap.pointerAnimation, 0);
    assert.equal(tap.posterAnimation, 1);
    assert.deepEqual(errors, []);
  } finally {
    await page.close();
  }
}

async function accessibility(browser) {
  for (const colorScheme of ["light", "dark"]) {
    const context = await browser.newContext({ viewport: { width: 375, height: 812 }, colorScheme });
    try {
      const page = await context.newPage();
      await page.goto(url);
      await page.getByRole("button", { name: "Menu" }).click();
      const { violations } = await new AxeBuilder({ page })
        .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"])
        .analyze();
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
      await accessibility(browser);
      const noScript = await browser.newPage({ javaScriptEnabled: false, viewport: { width: 375, height: 812 } });
      await noScript.goto(url);
      assert(await noScript.getByRole("heading", { level: 1 }).isVisible());
      assert(await noScript.getByRole("link", { name: "Try it", exact: true }).isVisible());
      assert(await noScript.getByText("Enable JavaScript to try the cursor in your browser.").isVisible());
      await noScript.close();
    }
    console.log(`${name} ${browser.version()} passed`);
  } finally {
    await browser.close();
  }
}
