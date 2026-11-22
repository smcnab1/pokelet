# Public release checklist

**Current decision (22 November 2026):** Release an explicitly experimental, **ad hoc-signed, unnotarised** Beta 2 without purchasing Apple Developer Program membership. The owner has accepted nine manual installation and runtime checks. A Developer ID and notarisation are **not** preconditions for this particular beta. Do not silently restore the superseded notarisation gate.

**Planned identity:** Pokelet **1.2.0 Beta 2**, app version `1.2.0`, build `3`, planned tag `v1.2.0-beta.1`. The tag is not yet published. See the [changelog](../CHANGELOG.md), the historical [readiness report](BETA2_RELEASE_READINESS.md), and the [OpenSSF assessment](OPENSSF_ASSESSMENT.md).

## Qualify the exact source and packaged app

1. Confirm the chosen final source commit, version, build and tag before writing the tag. Record whether any documentation-only or CI changes were committed after the app was packaged.
2. Require passing CI on the intended source commit. The [macOS build](../.github/workflows/macos.yml) runs SwiftLint, the Swift suite, Debug and Release analysis, and universal package checks. Apply the same [SwiftLint check](../script/lint_swift.sh) to any proposed major production release before publishing. Handle confirmed findings under the [security policy](../SECURITY.md). Universal packaging verifies the binary targets and architectures. Native Intel and macOS 14 runtime checks need separate evidence.
3. Check that the distributed DMG embeds the **approved 1.2.0 (3) app** and its expected `arm64` and `x86_64` slices; verify bundled resources, third-party licences, Release-only flags and native cursor recovery evidence.
4. Record the proposed tag commit and the provenance of the approved package. If the tag points to a later commit, compare its app, Xcode project, bundled resources and packaging inputs to the build commit. Resolve any material mismatch before publication.
5. Confirm the owner's nine accepted Beta 2 manual results dated 22 November 2026 in the release notes. Do not require a second extensive cursor matrix, additional macOS user or VM without a newly discovered defect.

## Sign the accepted installer

Beta 2’s approved local installer is `Pokelet-1.2.0-build-3-Premium-Final-Test.dmg`. Its SHA-256 is `083546c4ad764a57332a8ec1757974631ebaf17b5a78f96a6c3b027c372193aa`. The recorded build used [`b86c060`](https://github.com/smcnab1/pokelet/commit/b86c0608958094e2190f24733b84fce08fcaeb80) ([build CI](https://github.com/smcnab1/pokelet/actions/runs/45010609557)) with the app source from [`6ce0f30`](https://github.com/smcnab1/pokelet/commit/6ce0f3039e2c770ad743e0850039446f98c50e21). The app and packaging inputs match those on [reviewed main `f23663d`](https://github.com/smcnab1/pokelet/commit/f23663d9344d9d342ac0b6ab5b072eb06bcc728f). The later third-party notice addition covers the website font.

1. Keep the accepted DMG and its existing `.sha256` sidecar together. For a new release, generate the sidecar from the DMG’s directory with `shasum -a 256 -- "$dmg" > "$dmg.sha256"`, where `dmg` is the basename. Record the independently approved digest.
2. In a local Terminal, run the following with the exact paths. Enter the passphrase only at the Minisign prompt.

   ```sh
   ./script/sign_release.sh "$approved_dmg" "$approved_sha256" "$private_key_path"
   ```

3. The script checks the approved digest and existing sidecar before signing. It confirms the new signature with the [repository public key](../security/pokelet-minisign.pub), rejects a throwaway modified copy and writes the `.minisig` beside the DMG. Re-running the command verifies an existing signature without overwriting it. Stop on any failed check.
4. Keep the private key and passphrase on the maintainer’s Mac. Put only the DMG, checksum and detached signature in the release assets. The [user verification guide](VERIFYING_RELEASES.md) explains how to verify them.

## Distribution and installation disclosures

- The beta's ad hoc code signature is **not publisher authentication**. No Apple notarisation is claimed.
- Link to [Apple's per-app Open Anyway instructions](https://support.apple.com/102445). Users should only proceed if they trust the source and verification has succeeded; **never advise disabling Gatekeeper globally**. A macOS warning about damage or malware is a stop condition.
- Public Release builds exclude experimental Presentation Mode click suppression. Ordinary pointer features do not require Accessibility or Input Monitoring. Interactive-only sound behaviour may need an already-granted Accessibility permission and remains partially tested.
- Disclose incomplete native Intel, macOS 14, multi-display, VoiceOver and full keyboard-traversal testing. Universal build compatibility is not the same as verified runtime coverage.
- Keep local preferences and audio private; there is no account, usage telemetry or background updater.

## Owner-approved Beta 2 publication

1. Review the PRs, exact commit, CI results, DMG checksum and release notes; request **explicit final publication approval**.
2. Only after approval, create `v1.2.0-beta.1` on the agreed source commit and publish a **GitHub prerelease** named **Pokelet 1.2.0 Beta 2** with the exact approved DMG, checksum and Minisign signature. Keep their basenames together.
3. Download all three assets from GitHub Releases. Verify the published DMG’s checksum and signature again and confirm the release notes name the correct file and build.
4. Update README feature descriptions, Studio screenshot and installation references to the now-published Beta 2. Update the [website](site/index.html) and let the existing Pages workflow deploy after approval. Do not change public download links before the actual release asset exists.
5. GitHub's `/releases/latest` may exclude prereleases. Use a **verified exact prerelease asset URL** until a release-link strategy is implemented and hosted-tested.
6. Smoke-test GitHub release links, the hosted website download, mobile navigation, screenshot resources, SEO metadata and first-launch guidance. Retain technical acceptance evidence outside the README.

## Packaging commands for an unnotarised beta

`./script/package_release.sh` builds and checks a local universal app and ZIP in `dist/candidate/`. `./script/package_dmg.sh --beta` produces an ad hoc-signed beta DMG in `dist/beta/` with a checksum. The premium installer has a separate approved local candidate; do not assume this command reproduces its artwork without checking the exact current script and template. Compare package provenance before distribution.

## Optional future Developer ID and notarisation

For a later trusted distribution, enrol in the Apple Developer Program, obtain a **Developer ID Application** identity, configure a private `notarytool` credential profile, then execute the existing `./script/package_dmg.sh --notarise` flow only after specific approval. Validate the signing identity, hardened runtime, timestamp, notarisation log, stapled ticket and Gatekeeper assessment on the **actual DMG**. Keep private keys out of GitHub and avoid unnecessary CI secrets.

See [Apple's Developer ID certificate guidance](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/) and [notarisation guidance](https://developer.apple.com/documentation/technotes/tn3147-migrating-to-the-latest-notarization-tool). Apple notarisation would materially improve ordinary macOS installation trust, but is not claimed or required for this free public beta.

## Future build provenance

GitHub artifact attestations could bind a future premium DMG’s digest to the source commit and workflow that actually produced it. Consider that only when a trusted workflow builds and packages the exact DMG distributed to users. CI validates the source and packaging for this beta, while the accepted installer was built locally. Use the detached Minisign signature for its publisher verification. [GitHub’s artifact attestation guidance](https://docs.github.com/en/actions/concepts/security/artifact-attestations)
