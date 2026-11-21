# Pokelet website

The public landing page is plain HTML, CSS and JavaScript in [docs/site](site). The [GitHub Pages workflow](../.github/workflows/pages.yml) uploads that directory directly under `/pokelet/`. All runtime assets are local to the site. There is no bundler, backend or production JavaScript dependency.

## Design and interaction

| Element | Direction |
| --- | --- |
| Type and colour | Geist, warm paper, plum ink and violet accents. The darker palette follows the system appearance. |
| Hero | An interactive character composition built from the four native drawings on lilac dotted paper. |
| Playground | A character picker next to a dedicated demo surface. The default pointer returns on exit, and the toggle restores it while you stay in the demo. |
| Motion | Short, click-triggered reactions. Reduced Motion uses opacity feedback. Keyboard activation and touch animate the artwork inside the stage. |
| Product details | Native settings screenshot, a beta download and installation guide, and native disclosures for the FAQ. |

The browser preview offers Original, White and Black, five response levels and the built-in Soft Tap sound. Its pointer uses a 52 px transparent PNG with a hotspot at (16, 8), derived from the app’s 104-point canvas. The larger artwork uses WebP. The native input acceptance page remains at [Tests/Interactive/InputTargets.html](../Tests/Interactive/InputTargets.html).

## Preview locally

From the repository root:

```sh
preview_dir=$(mktemp -d)
ditto docs/site "$preview_dir/pokelet"
python3 -m http.server 4173 --bind 127.0.0.1 --directory "$preview_dir"
```

Visit [the local landing page](http://127.0.0.1:4173/pokelet/). Serving it under `/pokelet/` reproduces the Pages asset paths.

## Run the browser checks

The test tooling lives outside the production site. With Node.js installed:

```sh
qa_dir=$(mktemp -d)
npm install --prefix "$qa_dir" playwright @axe-core/playwright
"$qa_dir/node_modules/.bin/playwright" install chromium firefox webkit
NODE_PATH="$qa_dir/node_modules" node Tests/Browser/landing.mjs
```

Set `POKELET_SITE_URL` for a different local server, or `POKELET_CHROME_CHANNEL=chrome` to use installed Google Chrome. The suite covers cursor variants and alignment, click and keyboard reactions, reset, touch, mobile navigation, disclosures, reduced motion and automated accessibility in both colour schemes.

## Update artwork or the beta download

Run the [native artwork exporter](../script/make_site_art.swift) on macOS. The example uses Pillow to encode the large previews as WebP and copies the cursor PNGs directly.

```sh
art_dir=$(mktemp -d)
swiftc Pokelet/Models/{Preferences,KeyCodeNames,CursorGeometry}.swift \
  Pokelet/Cursor/PointerArt.swift script/make_site_art.swift -o "$art_dir/render"
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

The app icon, Soft Tap sound and [Pointer settings screenshot](screenshots/pokelet-settings-pointer-dark.png) also come from the repository. The social preview is a 1,200 × 630 composition of the hero and original character art.

When publishing a new beta, update the DMG and release-note links in the landing page and README, the structured download URL, the DMG size in the installation panel, and the browser test’s expected release URL. Verify the published checksum, minimum macOS version, supported architectures and signing status against the release asset.
