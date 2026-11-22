# Pokelet 1.2.0 Beta 2 - release notes draft

**Status:** Prepared, **not published**. Publish only after the owner approves the exact tag, release asset, source commit, SHA-256 checksum and detached signature.

**Planned Git tag:** `v1.2.0-beta.1`
**Application:** Pokelet `1.2.0`, build `3`
**Platform:** macOS 14 or later; universal Apple silicon and Intel binary (native Intel and macOS 14 runtime validation remain incomplete)

Pokelet is a free, open-source macOS cursor companion with four original animated characters, adjustable appearance, click effects and optional sounds.

## What's new

- **Pokelet Studio:** A refreshed, resizable workspace with live pointer preview, compact character picker, section shortcuts and an optional larger-text setting.
- **Presenter Arm:** A white cartoon glove and black sleeve, available as a Studio preview or across apps while keeping the native Mac pointer visible.
- **More accurate clicks:** Improved primary and secondary click alignment, including rapid clicks. Companion, Click-only and Replace in Studio modes remain distinct.
- **More flexible audio:** Play sounds on every click or, where Accessibility information is available, only on interactive controls.
- **Simpler app controls:** More consistent Dock and menu-bar behaviour, and improved reporting links and copyable system information.

## Upgrading

Existing character, colour, sound, and saved shortcut preferences remain intact. With fresh or reset settings, the default pointer shortcut is **Option–Command–P**. Existing customised shortcuts are preserved. Finder may use the same shortcut for its path bar.

## Installation and important disclosures

1. After publication, download the DMG, `.sha256` and `.minisig` from this exact GitHub prerelease. Follow the [release verification guide](VERIFYING_RELEASES.md) to check both the checksum and signature.
2. Open the DMG, drag Pokelet to Applications, and eject the disk image.
3. This free beta is **ad hoc signed, not Developer ID signed or Apple-notarised**. macOS may prevent first launch. Only if you trust the source and both checks succeed, use Apple's **System Settings → Privacy & Security → Open Anyway** option where offered. Do not disable Gatekeeper globally; stop for damage or malware warnings.
4. Open Pokelet from Applications and enable the pointer from the menu bar or Studio.

Presentation Mode's click-suppression control is **experimental and disabled in public Release builds**. Ordinary pointer use requires neither Accessibility nor Input Monitoring. Interactive-only sound behaviour relies on Accessibility information and is partially tested; if it is unavailable, choose Every click instead.

## Verified acceptance and remaining limits

The owner completed all nine final DMG and desktop acceptance checks on **22 November 2026**, covering installation, first launch, Studio, Dock/menu bar, characters and Presenter Arm, click effects and audio, cursor recovery, and retained preferences.

Previous automated qualification included 46 SwiftPM tests on Apple silicon and under Rosetta, Debug/Release analysis and universal package verification. The exact tag's CI must be checked before publication.

Remaining beta limitations include incomplete native Intel and macOS 14 runtime coverage, limited multiple-display testing, and incomplete full VoiceOver/keyboard-traversal and Accessibility-dependent sound coverage.

See the [privacy policy](../PRIVACY.md), [security reporting policy](../SECURITY.md) and [release checklist](RELEASE_CHECKLIST.md).

## Must complete before posting these notes

- [ ] Compare the intended tag SHA against the recorded build and packaging source in the [release checklist](RELEASE_CHECKLIST.md).
- [ ] Verify the final **uploaded** DMG is the accepted Pokelet 1.2.0 (3) premium installer.
- [ ] Verify its published filename, SHA-256 value, checksum sidecar and detached Minisign signature.
- [ ] Replace general download instructions with the confirmed GitHub release asset link after upload.
- [ ] Obtain the owner's explicit release approval and only then publish the prerelease.
