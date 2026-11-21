# Changelog

## Unreleased

- Open Settings to Pokelet Studio, a resizable workspace with a cursor-tracking preview, a compact character picker and quick pointer controls.
- Use the floating navigation rail or Command–1 through Command–6 to open Studio, Animations, Sounds, Presentation, General and About.
- Preview both click responses, choose sounds without playing them, and find Presentation Mode recovery shortcuts at the top of its page.
- Turn on **Larger Studio text** in General to enlarge the interface labels and headings.
- Keep animation intensity names readable when **Larger Studio text** is enabled.
- Close Studio with Command–W or toggle full screen with Control–Command–F.
- Use Option–Command–P to toggle the pointer with fresh or reset settings. Existing saved shortcuts are preserved.

## 1.1.0-beta.1

- Add Companion mode, with an offset character and the native cursor kept visible. Replace the cursor only over exposed content in Pokelet’s active Settings window.
- Add White, true Black and Custom to every character. Keep the existing tints and preferences.
- Redesign Settings with six panes, a light and dark character gallery and isolated left and right click previews.
- Restrict click-suppressing Presentation Mode to local Debug acceptance builds while live recovery checks remain open.
- Make custom audio import atomic and validate files before replacing the user’s existing sound. Keep preview playback separate.
- Add headless tests and publish a universal, ad hoc-signed beta DMG with a SHA-256 checksum.

## 1.0.0

- Initial local build with four vector characters, five animation intensities, click-only mode, click sounds and a menu bar shortcut.
