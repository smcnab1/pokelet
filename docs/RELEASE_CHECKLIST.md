# Public release checklist

## Verify the source candidate

- Run the macOS workflow on the exact release commit. It runs tests, builds and analyses Debug, then verifies a universal Release ZIP and the DMG layout.
- Confirm the `arm64` and `x86_64` slices target macOS 14.0. Confirm the extracted app signature, bundled licences and sounds, archive integrity and the SHA-256 checksum.
- Record results in [VERIFICATION.md](../VERIFICATION.md). Keep Presentation Mode disabled in Release builds while the [live input recovery checks](INTERACTIVE_ACCEPTANCE.md) remain open. Run those tests on a desktop only with the owner’s approval.

## Build the public beta DMG

From the clean release commit, run `./script/package_dmg.sh --beta`. The script verifies both architectures, the ad hoc app signature, the DMG layout, the bundled resources and the SHA-256 checksum. It writes the unnotarised DMG and checksum to `dist/beta/`. Mounting for verification is read-only and does not open Finder or launch Pokelet.

Publish both files in a GitHub prerelease tagged at the build commit. State the ad hoc signing and lack of notarisation before installation instructions. Point users to [Apple’s Open Anyway guidance](https://support.apple.com/102445) for the per-app option where available. Once published, download the public DMG and compare its checksum. Record live installation coverage only if observed on an approved desktop.

## Build the trusted DMG

Use a Mac with Xcode, a valid **Developer ID Application** identity and its private key in Keychain, and a `notarytool` Keychain profile linked to the Apple Developer team. If Keychain lacks the identity, the Apple Developer Program account holder should create or import it for the team. Use Apple’s [Developer ID guidance](https://developer.apple.com/developer-id/) and [notarytool Keychain instructions](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow) to configure credentials locally.

From the clean, verified release commit, set `POKELET_DEVELOPER_ID` to the certificate fingerprint and `POKELET_NOTARY_PROFILE` to the Keychain profile name. Then run:

```sh
./script/package_dmg.sh --notarise
```

The script builds the universal app, signs the app with hardened runtime and a secure timestamp, signs the DMG, waits for Apple to accept it, and staples the DMG ticket. It checks the disk image signature and Gatekeeper assessment, mounts the DMG read-only without opening Finder, and verifies the mounted app, the Applications shortcut and the exact executable. It writes the DMG and its SHA-256 checksum to `dist/notarised/` after those checks pass. Supply a fresh output directory to repeat the process.

For a local layout test with the candidate build, run `./script/package_dmg.sh --check-layout dist/candidate/Pokelet.app`. The image is temporary. CI uses this mode without signing credentials and retains only explicitly requested, short-lived ad hoc ZIP artefacts.

## Publish a notarised release

1. On a separate test Mac or VM, download the staged DMG through a browser and install by dragging to Applications. Check launch, the default permission experience, pointer restoration, and a repeat launch from Applications.
2. When Apple acceptance, Gatekeeper and the applicable safety checks are verified, publish the matching version tag and GitHub Release with the DMG and checksum. Use [the changelog](../CHANGELOG.md) to write short release notes. Include the macOS minimum and the current Presentation Mode status.
3. Update the README and [landing page](site/index.html) to show the verified download prominently. Download the public asset again and verify it against the published checksum. Confirm the public website, release and installation links.

Apple’s [distribution guidance](https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution) describes signing the app and DMG, notarising the outer container and testing distribution on a separate Mac.
