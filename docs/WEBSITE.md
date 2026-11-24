# Pokelet website

The public site uses plain HTML, CSS and JavaScript in [docs/site](site). The [GitHub Pages workflow](../.github/workflows/pages.yml) uploads that directory directly under `/pokelet/` from `main`. Cursor artwork, Studio screenshots, fonts and sounds are local. Directory badges load from their respective providers. The landing page uses public release metadata from GitHub to resolve download links. There is no bundler, backend or production JavaScript dependency.

## Design and interaction

| Element | Direction |
| --- | --- |
| Type and colour | Geist, warm paper, plum ink and violet accents. The darker palette follows the system appearance. |
| Hero | A composition of the four native characters on a dotted lilac backdrop. Each character can be selected directly. |
| Cursor | A compact header selector sets the character, colour, click response and sound. **Use normal cursor** switches the site effects off. |
| Motion | Short reactions across the page. Editable fields and native controls retain their usual cursors. Touch and keyboard activations use local feedback. Reduced Motion uses opacity feedback. |
| Product details | Native Studio screenshot, automatic downloads, installation guidance and a native FAQ disclosure. |

The browser preview offers Original, White and Black, five response levels and the built-in Soft Tap sound. Its pointer uses a 52 px transparent PNG with a hotspot at (16, 8), derived from the app’s 104-point canvas. The larger artwork uses WebP. The page remembers the cursor selection in local storage when available. Sound starts muted on every load. The native input acceptance page is at [Tests/Interactive/InputTargets.html](../Tests/Interactive/InputTargets.html).

## Preview locally

From the repository root:

```sh
preview_dir=$(mktemp -d)
ditto docs/site "$preview_dir/pokelet"
python3 -m http.server 4173 --bind 127.0.0.1 --directory "$preview_dir"
```

Visit [the local landing page](http://127.0.0.1:4173/pokelet/). Serving it under `/pokelet/` reproduces the Pages asset paths.

## Run the browser checks

The test tooling lives outside the production site. Use Node.js 22 or later.

The release-selection unit tests use only Node's built-in test runner and run in the required macOS CI job. They need no browser installation, npm packages, network or credentials. The full browser suite below remains a separate local check.

```sh
qa_dir=$(mktemp -d)
npm install --prefix "$qa_dir" playwright @axe-core/playwright
"$qa_dir/node_modules/.bin/playwright" install chromium firefox webkit
node --test Tests/Browser/releases.test.mjs
NODE_PATH="$qa_dir/node_modules" node Tests/Browser/landing.mjs
```

Set `POKELET_SITE_URL` for a different local server, or `POKELET_CHROME_CHANNEL=chrome` to use installed Google Chrome. The suite covers cursor variants across the page, alignment, mouse and keyboard reactions, restoration, touch, dragging, text editing, responsive navigation and automated accessibility. It also checks mobile navigation and download links when JavaScript is disabled or the site script fails to load. Release fixtures cover beta and stable downloads, asset validation, pagination, cache expiry, API failures and recovery.

## How downloads are selected

The site checks the [public GitHub Releases API](https://docs.github.com/en/rest/releases/releases#list-releases). It sorts non-draft releases by publication time, including beta and stable releases, and uses the newest one. The release must have exactly one uploaded, non-empty DMG with a GitHub download URL matching the repository, release tag and asset name. A missing or ambiguous DMG, blocked request or unavailable JavaScript sends visitors to the [releases listing](https://github.com/smcnab1/pokelet/releases).

The current result is cached for five minutes in the browser tab. An open page refreshes at expiry when visible and checks freshness when it returns to view. Publishing a new release needs no website change.

## Google Search Console

Complete these steps after the website changes have been approved and published. The [sitemap](site/sitemap.xml) lists the three public pages at their canonical URLs. Keep the sitemap, canonical tags and internal links in sync when changing a page path.

### Verify the URL-prefix property

1. Sign in to [Google Search Console](https://search.google.com/search-console/) with the Google account that will own the property.
2. Open the property selector, choose **Add property**, then choose **URL prefix**. Enter `https://smcnab1.github.io/pokelet/` including the trailing slash, and click **Continue**. Select that exact property if it already exists.
3. Choose **HTML tag** under the verification methods. Compare the tag Google provides with the `google-site-verification` tag in the `<head>` of the live [Pokelet homepage](https://smcnab1.github.io/pokelet/). Use **View Page Source** in a private browser window to check the public HTML. If your account’s tag is missing, add the exact tag provided by Google to `docs/site/index.html` through the usual site PR and approved publication process. Keep tags still used by other owners.
4. Once the tag is in the live HTML, click **Verify** in Search Console. Check **Settings → Ownership verification** and keep the tag in the published homepage so Google can recheck ownership.

[Google’s ownership verification guide](https://support.google.com/webmasters/answer/9008080)

### Submit the sitemap and request indexing

1. Open [the live sitemap](https://smcnab1.github.io/pokelet/sitemap.xml) in a private window. Confirm it loads and lists the three canonical HTTPS URLs below.
2. In the verified property, open **Sitemaps**. Under **Add a new sitemap**, enter `sitemap.xml` after the displayed property prefix, then click **Submit**. If the field has no prefix, enter `https://smcnab1.github.io/pokelet/sitemap.xml`. Check **Submitted sitemaps** for **Success** after processing.
3. In **URL Inspection**, paste each full URL below. Click **Test live URL**. Check that the page can be fetched and indexing is allowed, then click **Request indexing**. If the live test reports a blocking issue, correct it and repeat the test before requesting indexing.

   - `https://smcnab1.github.io/pokelet/`
   - `https://smcnab1.github.io/pokelet/animated-cursors-for-mac/`
   - `https://smcnab1.github.io/pokelet/presentation-pointer-for-mac/`

4. Revisit **URL Inspection** after Google processes the requests. Check **Page indexing** and compare the Google-selected canonical with the expected URL. Sitemap submission and indexing requests help discovery. Google decides when and whether to index each page.

[Sitemaps report guide](https://support.google.com/webmasters/answer/7451001) · [URL Inspection guide](https://support.google.com/webmasters/answer/9012289)

Google reads robots rules from `https://smcnab1.github.io/robots.txt`. This project site publishes under `/pokelet/`, so use the Search Console sitemap submission above for discovery. [Google’s robots.txt specification](https://developers.google.com/crawling/docs/robots-txt/robots-txt-spec)

## Update artwork

Run the [native artwork exporter](../script/make_site_art.swift) on macOS. The example uses Pillow to encode the large previews as WebP and copies the cursor PNGs directly.

```sh
art_dir=$(mktemp -d)
swiftc Pokelet/Models/{Preferences,KeyCodeNames,CursorGeometry,ClickCadence}.swift \
  Pokelet/Cursor/{PointerArt,PointerLayer,PresenterArm}.swift script/make_site_art.swift -o "$art_dir/render"
"$art_dir/render" "$art_dir/png"
python3 - "$art_dir/png" <<'PY'
from pathlib import Path
from shutil import copyfile
from PIL import Image
import sys

destination = Path("docs/site/assets/characters")
for source in Path(sys.argv[1]).glob("*.png"):
    if source.stem.endswith("-cursor"):
        copyfile(source, destination / source.name)
    else:
        with Image.open(source) as artwork:
            artwork.save(destination / f"{source.stem}.webp", quality=88, method=6)
PY
```

The app icon and Soft Tap sound also come from the repository. The Studio image uses the [compact light](screenshots/pokelet-studio-presenter-compact-light.png) and [wide dark](screenshots/pokelet-studio-presenter-preview-dark.png) captures of Presenter Arm. The site serves WebP copies at their original aspect ratios. Phones use the compact capture for larger controls and text. The social preview is a 1,200 × 630 composition of the hero and original character art.
