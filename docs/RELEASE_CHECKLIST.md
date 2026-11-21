# Public release checklist

## Verify the source candidate

- Obtain approval for the version, build and tag. Commit the approved version and build in the Xcode project, then record the release commit SHA and toolchain.
- Run the macOS workflow on that exact commit. It runs tests, builds and analyses Debug, builds and analyses universal Release, and verifies the ZIP and DMG layout. This workflow uses ad hoc signing and runs without Apple credentials.
- Confirm the `arm64` and `x86_64` slices target macOS 14.0. Confirm the extracted app signature, bundled licences and sounds, archive integrity and SHA-256 checksum. The package check rejects debug entitlements and acceptance flags in either slice.
- Record results in [VERIFICATION.md](../VERIFICATION.md). Release builds keep Presentation Mode disabled. [Live Presentation Mode input testing](INTERACTIVE_ACCEPTANCE.md) uses Debug and requires desktop owner approval.

## Rehearse with an ad hoc DMG

From a clean checkout, run `./script/package_dmg.sh --beta` for a local, ad hoc-signed DMG and SHA-256 checksum in `dist/beta/`. Verification mounts the image read-only and checks the Applications shortcut, app resources and signature. `./script/package_dmg.sh --check-layout dist/candidate/Pokelet.app` uses a temporary image. These checks establish package integrity. Use the trusted DMG and an isolated desktop for launch and upgrade acceptance.

The [public Beta 1](https://github.com/smcnab1/pokelet/releases/tag/v1.1.0-beta.1) used an ad hoc DMG. Follow its published checksum and [Apple’s per-app guidance](https://support.apple.com/102445) for any approved historical-installation test on a disposable system.

## Build the trusted DMG

Use a Mac with Xcode, a valid **Developer ID Application** identity and its private key in Keychain, and a `notarytool` Keychain profile for the same Apple Developer team. The account holder can arrange certificate issuance or import after approval. Use `xcrun notarytool store-credentials` with interactive prompts and a team-authorised credential. Keep credentials and private keys in the team's approved storage. [Developer ID guidance](https://developer.apple.com/developer-id/) · [Keychain profile setup](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)

Set `POKELET_DEVELOPER_ID` to the certificate fingerprint and `POKELET_NOTARY_PROFILE` to the Keychain profile name. `./script/package_dmg.sh --check-signing` checks the configured keychains and `notarytool` locally. Run the following command from the clean release commit with the approved version and build committed, after approval to submit to Apple.

```sh
env -u XCODE_XCCONFIG_FILE ./script/package_dmg.sh --notarise
```

The script checks access to the Notary service, builds the universal app and verifies Developer ID, hardened runtime and a secure timestamp on both slices. It signs the DMG under a distinct signing identifier, submits it to Apple, then staples and validates the ticket after acceptance. It assesses the disk image and mounted app with Gatekeeper and verifies the Applications shortcut and embedded executable. It writes the verified DMG, its checksum and the private Apple review log to `dist/notarised/`. Review the log before distribution.

If waiting, stapling or verification fails after submission, use the retained staging path and submission ID from `submission.plist`. Check the existing submission with `notarytool info` or `notarytool log` before considering a retry. Follow the full verification sequence on the same DMG if recovering an accepted submission.

## Publish a notarised release

1. On a separate test Mac or VM, browser-download the stapled DMG and verify quarantine and its checksum. Run the [fresh installation and upgrade exercises](BETA2_RELEASE_READINESS.md#disposable-desktop-acceptance).
2. After release approval, publish the matching version tag and GitHub prerelease with the verified DMG and checksum. Use [the changelog](../CHANGELOG.md) for the public notes and include the macOS minimum and Presentation Mode status.
3. Download the public DMG and verify it against the published checksum. Update the README and [landing page](site/index.html) to point to the verified download, then confirm the public website, release and installation links.

Apple’s [distribution guidance](https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution) describes signing the app and DMG, notarising the outer container and testing distribution on a separate Mac.
