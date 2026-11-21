// @ts-check
const listing = "https://github.com/smcnab1/pokelet/releases";
const endpoint = "https://api.github.com/repos/smcnab1/pokelet/releases";
const cacheKey = "pokelet-release-v1";
const lifetime = 5 * 60_000;

/** @param {unknown} value */
function asRecord(value) {
  return typeof value === "object" && value !== null ? /** @type {Record<string, unknown>} */ (value) : {};
}

/** @param {unknown} value @param {string} path */
function verifiedLink(value, path) {
  if (typeof value !== "string") return;
  try {
    const url = new URL(value);
    if (url.origin === "https://github.com" && !url.username && !url.password && !url.search && !url.hash &&
        decodeURIComponent(url.pathname) === "/smcnab1/pokelet/releases/" + path) return url.href;
  } catch {
    // Invalid GitHub metadata preserves the Releases fallback.
  }
}

/** @param {unknown} data */
export function selectDownload(data) {
  if (!Array.isArray(data)) return;
  return selectPublished(data.map(asRecord));
}

/** @param {Record<string, unknown>[]} releases */
function selectPublished(releases) {
  const newest = releases.flatMap((release) => {
    const time = typeof release.published_at === "string" ? Date.parse(release.published_at) : NaN;
    return release.draft === false && Number.isFinite(time) ? [{ release, time, order: Number(release.id) || 0 }] : [];
  }).sort((a, b) => b.time - a.time || b.order - a.order)[0]?.release;

  if (!newest || typeof newest.tag_name !== "string" || !newest.tag_name.trim() || !Array.isArray(newest.assets)) return;
  const tag = newest.tag_name;
  const notes = verifiedLink(newest.html_url, "tag/" + tag);
  if (!notes) return;

  const candidates = newest.assets.flatMap((value) => {
    const asset = asRecord(value);
    const name = asset.name;
    if (typeof name !== "string" || !/^[^/\\]+\.dmg$/i.test(name) || asset.state !== "uploaded" ||
        typeof asset.size !== "number" || !Number.isSafeInteger(asset.size) || asset.size <= 0) return [];
    const url = verifiedLink(asset.browser_download_url, "download/" + tag + "/" + name);
    return url ? [{ asset, url }] : [];
  });
  if (candidates.length !== 1) return;

  const [{ asset, url }] = candidates;
  const snapshot = {
    id: newest.id, draft: false, published_at: newest.published_at, tag_name: tag,
    html_url: notes, assets: [asset],
  };
  return { tag, notes, url, snapshot };
}

/** @param {AbortSignal} signal */
async function discover(signal) {
  const releases = [];
  for (let page = 1; ; page += 1) {
    const url = endpoint + "?per_page=100&page=" + page;
    const response = await fetch(url, { signal, cache: "no-cache", credentials: "omit" });
    if (!response.ok) throw new Error("Release listing unavailable");
    const data = await response.json();
    if (!Array.isArray(data)) throw new Error("Invalid release listing");
    releases.push(...data);

    const next = response.headers.get("Link")?.match(/<([^>]+)>;\s*rel="next"/)?.[1];
    if (!next) break;
    const parsed = new URL(next);
    if (parsed.origin !== "https://api.github.com" || parsed.searchParams.get("page") !== String(page + 1)) {
      throw new Error("Invalid release pagination");
    }
  }
  return selectDownload(releases);
}

export function initialiseDownloads() {
  const buttons = document.querySelectorAll("a[data-download]");
  const notes = document.querySelectorAll("a[data-release-notes]");
  const caption = document.querySelector("[data-release-caption]");
  const fallbackLabels = Array.from(buttons, (link) => link.querySelector(".download-label")?.textContent ?? "");
  let refreshAt = 0;
  let timer = 0;
  let pending = false;

  /** @param {ReturnType<typeof selectDownload>} release */
  const display = (release) => {
    buttons.forEach((link, index) => {
      if (!(link instanceof HTMLAnchorElement)) return;
      link.href = release?.url ?? listing;
      const label = link.querySelector(".download-label");
      if (label) label.textContent = release ? (link.dataset.download ?? fallbackLabels[index]) : fallbackLabels[index];
    });
    notes.forEach((link) => link.setAttribute("href", release?.notes ?? listing));
    if (caption) caption.textContent = release ? release.tag + " release notes" : "GitHub Releases";
  };

  try {
    const cached = asRecord(JSON.parse(sessionStorage.getItem(cacheKey) ?? "null"));
    const age = typeof cached.savedAt === "number" ? Date.now() - cached.savedAt : Infinity;
    const release = age >= 0 && age < lifetime ? selectDownload([cached.release]) : undefined;
    if (release) {
      refreshAt = Date.now() + lifetime - age;
      display(release);
    }
  } catch {
    // Storage can be unavailable in private or restricted browsing.
  }

  const refresh = async () => {
    if (document.hidden || pending) return;
    window.clearTimeout(timer);
    if (Date.now() < refreshAt) {
      timer = window.setTimeout(refresh, refreshAt - Date.now());
      return;
    }

    pending = true;
    const controller = new AbortController();
    const timeout = window.setTimeout(() => controller.abort(), 5000);
    try {
      const release = await discover(controller.signal);
      display(release);
      refreshAt = Date.now() + (release ? lifetime : 60_000);
      if (release) sessionStorage.setItem(cacheKey, JSON.stringify({ savedAt: Date.now(), release: release.snapshot }));
      else sessionStorage.removeItem(cacheKey);
    } catch {
      // Keep a resolved link if only the optional storage write failed.
      if (refreshAt <= Date.now()) {
        display(undefined);
        refreshAt = Date.now() + 60_000;
      }
    } finally {
      window.clearTimeout(timeout);
      pending = false;
      if (!document.hidden) timer = window.setTimeout(refresh, Math.max(0, refreshAt - Date.now()));
    }
  };

  // Begin after the initial render. Refocus and back/forward restoration respect the same expiry.
  window.setTimeout(refresh, 0);
  window.addEventListener("pageshow", refresh);
  document.addEventListener("visibilitychange", refresh);
}
