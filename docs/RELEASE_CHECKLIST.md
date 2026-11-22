# Public release checklist

**Current decision (22 November 2026):** Release an explicitly experimental, **ad hoc-signed, unnotarised** Beta 2 without purchasing Apple Developer Program membership. The owner has accepted nine manual installation and runtime checks. A Developer ID and notarisation are **not** preconditions for this particular beta. Do not silently restore the superseded notarisation gate.

**Planned identity:** Pokelet **1.2.0 Beta 2**, app version `1.2.0`, build `3`, planned tag `v1.2.0-beta.1`. The tag is not yet published. See the [changelog](../CHANGELOG.md), the historical [readiness report](BETA2_RELEASE_READINESS.md), and the [OpenSSF assessment](OPENSSF_ASSESSMENT.md).

## Qualify the exact source and packaged app

1. Confirm the chosen final source commit, version, build and tag before writing the tag. Record whether any documentation-only or CI changes were committed after the app was packaged.
2. Require passing CI on the intended source commit. The [macOS build](../.github/workflows/macos.yml) runs SwiftLint, the Swift suite, Debug and Release analysis, and universal package checks. Apply the same [SwiftLint check](../script/lint_swift.sh) to any proposed major production release before publishing. Handle confirmed findings under the [security policy](../SECURITY.md). Universal packaging verifies the binary targets and architectures. Native Intel and macOS 14 runtime checks need separate evidence.
3. Check that the distributed DMG embeds the **approved 1.2.0 (3) app** and its expected `arm64` and `x86_64` slices; verify bundled resources, third-party licences, Release-only flags and native cursor recovery evidence.
4. Verify `shasum -a 256` for the **actual uploaded DMG** and publish a matching `.sha256` file. An existing locally recorded candidate is not sufficient evidence if packaging or the DMG itself changes.
5. Record the tagged commit and the provenance of the approved package. If the release tag points to a subsequent documentation/security commit, explicitly confirm the earlier build source is identical for the packaged application; otherwise rebuild and requalify. Do not attest a locally built DMG using unrelated CI output.
6. Confirm the owner's nine accepted Beta 2 manual results dated 22 November 2026 in the release notes. Do not require a second extensive cursor matrix, additional macOS user or VM without a newly discovered defect.

## Distribution and installation disclosures

- The beta's ad hoc code signature is **not publisher authentication**. No Apple notarisation is claimed.
- Link to [Apple's per-app Open Anyway instructions](https://support.apple.com/102445). Users should only proceed if they trust the source and have verified the checksum; **never advise disabling Gatekeeper globally**. A macOS warning about damage or malware is a stop condition.
- Public Release builds exclude experimental Presentation Mode click suppression. Ordinary pointer features do not require Accessibility or Input Monitoring. Interactive-only sound behaviour may need an already-granted Accessibility permission and remains partially tested.
- Disclose incomplete native Intel, macOS 14, multi-display, VoiceOver and full keyboard-traversal testing. Universal build compatibility is not the same as verified runtime coverage.
- Keep local preferences and audio private; there is no account, usage telemetry or background updater.

## Owner-approved Beta 2 publication

1. Review the PRs, exact commit, CI results, DMG checksum and release notes; request **explicit final publication approval**.
2. Only after approval, create `v1.2.0-beta.1` on the agreed source commit and publish a **GitHub prerelease** named **Pokelet 1.2.0 Beta 2** with the exact approved DMG and checksum.
3. Download the public asset and checksum from GitHub Releases and compare them, inspect its filename and verify that the release notes describe the actual build.
4. Update README feature descriptions, Studio screenshot and installation references to the now-published Beta 2. Update the [website](site/index.html) and let the existing Pages workflow deploy after approval. Do not change public download links before the actual release asset exists.
5. GitHub's `/releases/latest` may exclude prereleases. Use a **verified exact prerelease asset URL** until a release-link strategy is implemented and hosted-tested.
6. Smoke-test GitHub release links, the hosted website download, mobile navigation, screenshot resources, SEO metadata and first-launch guidance. Retain technical acceptance evidence outside the README.

## Packaging commands for an unnotarised beta

`./script/package_release.sh` builds and checks a local universal app and ZIP in `dist/candidate/`. `./script/package_dmg.sh --beta` produces an ad hoc-signed beta DMG in `dist/beta/` with a checksum. The premium installer has a separate approved local candidate; do not assume this command reproduces its artwork without checking the exact current script and template. Compare package provenance before distribution.

## Optional future Developer ID and notarisation

For a later trusted distribution, enrol in the Apple Developer Program, obtain a **Developer ID Application** identity, configure a private `notarytool` credential profile, then execute the existing `./script/package_dmg.sh --notarise` flow only after specific approval. Validate the signing identity, hardened runtime, timestamp, notarisation log, stapled ticket and Gatekeeper assessment on the **actual DMG**. Keep private keys out of GitHub and avoid unnecessary CI secrets.

See [Apple's Developer ID certificate guidance](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/) and [notarisation guidance](https://developer.apple.com/documentation/technotes/tn3147-migrating-to-the-latest-notarization-tool). Apple notarisation would materially improve ordinary macOS installation trust, but is not claimed or required for this free public beta.
