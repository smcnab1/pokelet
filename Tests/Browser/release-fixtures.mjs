export const listing = "https://github.com/smcnab1/pokelet/releases";
export const api = "https://api.github.com/repos/smcnab1/pokelet/releases";

/** Build a representative public release with a deliberately independent asset name. */
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
export const newerBeta = release("v1.2.0-beta.2", "2026-12-03T10:00:00Z", "Pokelet Mac Preview.DMG", true);
export const stable = release("v2.0.0", "2026-12-12T10:00:00Z", "Mac Universal.dmg");
