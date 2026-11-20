# Changelog

## Unreleased

- Add Companion mode, with an offset character and the native cursor kept visible. Replace the cursor only over exposed content in Pokelet’s active Settings window.
- Add White, true Black and Custom to every character. Keep the existing tints and preferences.
- Redesign Settings with six panes, a light and dark character gallery and isolated left and right click previews.
- Harden Presentation Mode with readiness checks, gesture pairing, shortcuts, a fixed-width pause indicator with click-to-exit and a 15-minute limit. Ordinary launches keep it disabled while the remaining recovery checks are open.
- Make custom audio import atomic and validate files before replacing the user’s existing sound. Keep preview playback separate.
- Add headless tests and universal archive packaging with SHA-256 checksums.

## 1.0.0

- Initial local build with four vector characters, five animation intensities, click-only mode, click sounds and a menu bar shortcut.
