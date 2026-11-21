# Changelog

## Unreleased

### Studio

- Open Settings to a resizable Studio with a live preview, quick pointer controls and a compact character picker. Use Command–1 through Command–6 to switch panes.
- Turn on **Larger Studio text** in General. Use Command–M to minimise, Command–W to close and Control–Command–F to toggle full screen.
- Open Studio from the menu bar or Dock. By default, the Dock icon follows Studio when the menu bar item is available. General lets you keep the Dock icon visible or hide the menu bar item.

### Pointer and sounds

- Try **Presenter Arm** in Studio or use it across apps with the Mac pointer visible. Turning it off restores your selected character.
- See click effects at each mouse-down position, including secondary and rapid clicks. Replace in Studio and Click-only align the character with the click. Companion keeps the character beside the Mac pointer.
- Choose **Every click** or **Interactive clicks only** in Sounds. The latter pauses when Accessibility access is unavailable and offers a switch to **Every click**.
- Use Option–Command–P to toggle the pointer with fresh or reset settings. Pokelet retains shortcuts already saved by earlier versions.

### Feedback and release controls

- Open the updated GitHub forms from **About → Help & Feedback**. Review the system information in the bug report or copy it for pasting.
- Public Release builds keep Presentation Mode click suppression unavailable. Acceptance profiles are available in Debug builds.

## 1.1.0-beta.1

- Add Companion mode, with an offset character and the native cursor kept visible. Replace the cursor only over exposed content in Pokelet’s active Settings window.
- Add White, true Black and Custom to every character. Keep the existing tints and preferences.
- Redesign Settings with six panes, a light and dark character gallery and isolated left and right click previews.
- Restrict click-suppressing Presentation Mode to local Debug acceptance builds while live recovery checks remain open.
- Make custom audio import atomic and validate files before replacing the user’s existing sound. Keep preview playback separate.
- Add headless tests and publish a universal, ad hoc-signed beta DMG with a SHA-256 checksum.

## 1.0.0

- Initial local build with four vector characters, five animation intensities, click-only mode, click sounds and a menu bar shortcut.
