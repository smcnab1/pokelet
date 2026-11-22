# Pokelet website

The public landing page is plain HTML, CSS and JavaScript in [docs/site](site). The [GitHub Pages workflow](../.github/workflows/pages.yml) uploads that directory directly under `/pokelet/`. All interface assets are local to the site. The download links use public release metadata from GitHub. There is no bundler, backend or production JavaScript dependency.

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

The test tooling lives outside the production site. With Node.js 22 or later installed:

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
