# Pokelet documentation

[Download Beta 1](https://github.com/smcnab1/pokelet/releases/tag/v1.1.0-beta.1) · [Verify and install](VERIFYING_RELEASES.md) · [Report an issue](https://github.com/smcnab1/pokelet/issues/new/choose)

## Use Pokelet

Open the hand icon in the menu bar and select **Enable Pointer**. Beta 1 uses **Control–Option–P** by default. Change the shortcut in **Settings → General**.

| Setting | What it does |
| --- | --- |
| **Pointer** | Choose Finger, Cat Paw, Foam Finger or Comic Arrow. Set the size and use the original colour, white, black or a custom colour. Companion follows beside the Mac cursor. Replacement is limited to eligible areas in Pokelet’s Settings window. |
| **Animations** | Adjust the click intensity or choose click-only behaviour so the character appears only when you click. Pokelet follows macOS Reduce Motion. |
| **Sounds** | Enable a built-in sound or import a short local audio clip. Sounds start muted. |
| **General** | Change the shortcut, restore the pointer’s last state on launch or enable **Launch at login**. |

For a recording or screen share, choose an entire display to include the cursor overlay. Window-only capture usually excludes it. Recording click sounds depends on your recorder’s audio settings.

To uninstall, quit Pokelet and move it from Applications to the Bin. Before quitting, use **Settings → General → Reset Settings…** if you want to clear local preferences, imported audio and the login item. Remove any optional grants in **System Settings → Privacy & Security**.

## What changes in Beta 2

Beta 2 is unpublished. The [Studio guide](STUDIO.md) covers Companion, Click-only, Replace in Studio, Presenter Arm and Accessibility-dependent click sounds.

The default shortcut for fresh or reset settings changes to **Option–Command–P**. Upgrades keep your saved shortcut. Finder uses the same key combination for its path bar, so review the shortcut in General if it conflicts.

## Compatibility

The universal build targets macOS 14 Sonoma and later on Apple silicon and Intel. Native Intel and macOS 14 runtime testing is incomplete. See the [verification record](../VERIFICATION.md) for current coverage, including displays and accessibility.

Ordinary pointer use requires neither Accessibility nor Input Monitoring. Experimental Presentation Mode click suppression is disabled in public Release builds. See [privacy and permissions](../PRIVACY.md).

## Project resources

- [Build from source or contribute](../CONTRIBUTING.md) · [Work on the website](WEBSITE.md)
- [Report a vulnerability privately](../SECURITY.md) · [Verify a release](VERIFYING_RELEASES.md)
- [Changelog](../CHANGELOG.md) · [MIT licence](../LICENSE) · [Third-party notices](../THIRD_PARTY_NOTICES.md)
- [OpenSSF assessment](OPENSSF_ASSESSMENT.md) · [Beta 2 acceptance](BETA2_ACCEPTANCE.md) · [Maintainer release checklist](RELEASE_CHECKLIST.md)

Pokelet is independent of Pokey and has no affiliation with its developer. It adapts MIT-licensed Quiet Pointer code and uses original character artwork and sounds.
