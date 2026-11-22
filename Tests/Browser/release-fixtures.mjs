export const listing = "https://github.com/smcnab1/pokelet/releases";
export const api = "https://api.github.com/repos/smcnab1/pokelet/releases";

/** Build a representative public release with an asset name independent of the tag. */
export function release(tag, published, name, prerelease = false) {
  return {
    draft: false, prerelease, published_at: published, tag_name: tag,
    html_url: `${listing}/tag/${tag}`,
    assets: [{
      name, state: "uploaded", size: 1586629, content_type: "application/x-apple-diskimage",
      browser_download_url: `${listing}/download/${tag}/${encodeURIComponent(name)}`,
    }],
  };
}

export const beta = release("v1.1.0-beta.1", "2026-11-20T15:11:35Z", "Pokelet-1.1.0-unnotarised.dmg", true);
export const newerBeta = release("v1.2.0-beta.1", "2026-12-03T10:00:00Z", "Pokelet-1.2.0-build-3-Premium-Final-Test.dmg", true);
const beta2DMG = newerBeta.assets[0];
for (const suffix of [".sha256", ".minisig"]) {
  newerBeta.assets.push({
    ...beta2DMG, name: beta2DMG.name + suffix, browser_download_url: beta2DMG.browser_download_url + suffix,
  });
}
export const stable = release("v2.0.0", "2026-12-12T10:00:00Z", "Mac Universal.dmg");
