# Pokelet documentation

[Download Beta 2](https://github.com/smcnab1/pokelet/releases/tag/v1.2.0-beta.1) · [Verify and install](VERIFYING_RELEASES.md) · [Report an issue](https://github.com/smcnab1/pokelet/issues/new/choose)

## Use Pokelet

Open the hand icon in the menu bar and select **Enable Pointer**. Select **Open Pokelet Studio** from the same menu to set up the pointer.

| Where to go | What you can do |
| --- | --- |
| **Studio** | Pick Finger, Cat Paw, Foam Finger or Comic Arrow. Adjust the size and colour, try the live preview, or enable **Presenter Arm**. |
| **Animations** | Adjust click intensity or enable **Click-only mode**. Pokelet follows macOS Reduce Motion. |
| **Sounds** | Pick a built-in sound or import a short audio clip. Sounds start off. If **Interactive clicks only** stays silent, check Accessibility access or choose **Every click**. |
| **General** | Change the shortcut, restore the last pointer state or enable **Launch at login**. |

Use **Option–Command–P** with fresh or reset settings. Upgrades keep your saved shortcut. Finder uses the same key combination for its path bar, so change it under **General** if it conflicts. See the [Studio guide](STUDIO.md) for Companion, Click-only, Replace in Studio, Presenter Arm and click sound options.

For a recording or screen share, select the entire display and check the overlay in the recorder’s preview. Recording click sounds depends on your recorder’s audio settings.

To uninstall, quit Pokelet and move it from Applications to the Bin. Before quitting, use **General → Reset Settings…** in Pokelet Studio if you want to clear local preferences, imported audio and the login item. Remove any optional grants in **System Settings → Privacy & Security**.

## Compatibility

The universal build targets macOS 14 Sonoma and later on Apple silicon and Intel. Native Intel and macOS 14 runtime testing is incomplete. See the [verification record](../VERIFICATION.md) for current coverage, including displays and accessibility.

Ordinary pointer use requires neither Accessibility nor Input Monitoring. Experimental Presentation Mode click suppression is disabled in public Release builds. See [privacy and permissions](../PRIVACY.md).

## Project resources

- [Build from source or contribute](../CONTRIBUTING.md) · [Work on the website](WEBSITE.md)
- [Report a vulnerability privately](../SECURITY.md) · [Verify a release](VERIFYING_RELEASES.md)
- [Changelog](../CHANGELOG.md) · [MIT licence](../LICENSE) · [Third-party notices](../THIRD_PARTY_NOTICES.md)
- [OpenSSF assessment](OPENSSF_ASSESSMENT.md) · [Beta 2 acceptance](BETA2_ACCEPTANCE.md) · [Maintainer release checklist](RELEASE_CHECKLIST.md)

Pokelet is independent of Pokey and has no affiliation with its developer. It adapts MIT-licensed Quiet Pointer code and uses original character artwork and sounds.
