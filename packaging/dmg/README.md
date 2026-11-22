# Pokelet DMG design

The installer uses a 720 × 432 point aubergine backdrop with a pale lavender drop area. The artwork uses the original **The Finger** vector from Pokelet, rendered in its Lilac palette. The application icon, Applications shortcut and their labels are real Finder items.

## Package a candidate

Use a new output directory. To repackage an already verified universal, ad hoc release bundle, pass its path as the third argument.

```sh
./script/package_dmg.sh --beta dist/premium-dmg-candidate /path/to/Pokelet.app
```

The command checks the app's identity, architectures and signatures, then verifies the mounted bundle and writes a new SHA-256 file. Omit the bundle path to build from the current checkout. The CI layout check uses the same template and runs without Finder. The image layout is repeatable from the checked-in template. Image filesystem metadata can change the SHA-256 between builds.

## Update the design

- [Background.swift](Background.swift) renders the 720 × 432 and 1440 × 864 illustrations into one TIFF with 72 and 144 DPI representations.
- [FinderLayout.applescript](FinderLayout.applescript) places 112-point icons and 13-point labels in icon view and hides the toolbar, sidebar, path bar and status bar.
- [InstallerTemplate.dmg](InstallerTemplate.dmg) is the only disk image tracked in Git. It contains the Finder-authored layout, artwork, volume icon, Applications symlink and empty icon-position placeholder. Packaging replaces the placeholder with the signed bundle and retains the original filesystem so Finder's background reference stays valid. Keep generated installers and screenshots in `dist/`.

Regenerate the template in a macOS desktop session with Xcode installed and Finder available for AppleScript. The HFS+ template reserves 32 MiB. Increase the size in the generator if a future bundle outgrows the image.

```sh
mkdir -p dist
./packaging/dmg/make-template.sh dist/InstallerTemplate.dmg
cp dist/InstallerTemplate.dmg packaging/dmg/InstallerTemplate.dmg
./script/package_dmg.sh --check-layout /path/to/Pokelet.app
```

After changing the artwork or layout, open a packaged image from Finder and check the icon alignment, label contrast and window chrome. Repeat after ejecting and reopen in Light and Dark Mode. Finder can fit the window to the available screen and apply user preferences such as showing filename extensions or hidden files.
