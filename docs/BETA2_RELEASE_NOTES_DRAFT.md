# Pokelet 1.2.0 Beta 2

Pokelet Studio brings the live pointer preview, character picker and settings into one resizable window. Try four original characters, from the pointing finger to the comic arrow, and adjust their colour, size and outline before turning on the pointer.

- **Presenter Arm** adds a cartoon glove that reaches up from the bottom of the display while keeping the Mac pointer visible. Try it in Studio or use it across apps.
- **More precise click effects** follow primary, secondary and rapid clicks. Choose Companion to follow beside the Mac pointer, Click-only to reveal the character at each click, or Replace in Studio to swap the cursor within eligible areas of the active Studio window.
- **Optional click sounds** can play on every click or only over interactive controls that macOS can identify. Use a built-in sound or import a short audio clip. Interactive-only playback stays silent if the control cannot be identified or Accessibility access is unavailable.

If you’re upgrading, Pokelet keeps your saved settings and shortcut. The default for fresh or reset settings is **Option–Command–P**. Finder may use that shortcut for its path bar.

## Install and verify

1. From this release’s **Assets**, download `Pokelet-1.2.0-build-3-Premium-Final-Test.dmg` and its matching `.sha256` and `.minisig` files. Follow the [release verification guide](https://github.com/smcnab1/pokelet/blob/main/docs/VERIFYING_RELEASES.md) to check the SHA-256 checksum and verify the Minisign signature against the Pokelet public key.
2. Open the verified DMG, drag **Pokelet** to **Applications**, then eject the disk image.
3. Open Pokelet from **Applications**. This beta is **ad hoc signed and unnotarised**, so macOS may block first launch. If you trust the source and both checks passed, use **Open Anyway** in **System Settings → Privacy & Security** when offered. Keep Gatekeeper enabled and stop if macOS reports damage or malware. [Apple’s first-launch guidance](https://support.apple.com/102445)
4. Select **Enable Pointer** from the hand icon in the menu bar.

## Compatibility and known limitations

This is app version **1.2.0 (build 3)**, distributed as a universal build for **macOS 14 Sonoma or later** on Apple silicon and Intel. Native Intel and macOS 14 runtime testing remain outstanding. Multiple-display, VoiceOver and keyboard coverage is limited.

Ordinary pointer features require neither Accessibility nor Input Monitoring. Experimental Presentation Mode click suppression is disabled in this build. For recording or screen sharing, choose the entire display and check that the pointer appears in your recorder’s preview.
