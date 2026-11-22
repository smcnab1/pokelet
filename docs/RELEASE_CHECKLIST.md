# Public release checklist

**Current decision (22 November 2026):** Release an explicitly experimental, **ad hoc-signed, unnotarised** Beta 2 without purchasing Apple Developer Program membership. The owner has accepted nine manual installation and runtime checks. A Developer ID and notarisation are **not** preconditions for this particular beta. Do not silently restore the superseded notarisation gate.

**Release identity:** Pokelet **1.2.0 Beta 2**, app version `1.2.0`, build `3`, tag `v1.2.0-beta.1`. See the [changelog](../CHANGELOG.md), the historical [readiness report](BETA2_RELEASE_READINESS.md) and the [OpenSSF assessment](OPENSSF_ASSESSMENT.md).

## Qualify the exact source and packaged app

1. Confirm the chosen final source commit, version, build and tag before writing the tag. Record whether any documentation-only or CI changes were committed after the app was packaged.
2. Require passing CI on the intended source commit. The [macOS build](../.github/workflows/macos.yml) runs SwiftLint, the Swift suite, Debug and Release analysis, and universal package checks. Apply the same [SwiftLint check](../script/lint_swift.sh) to any proposed major production release before publishing. Handle confirmed findings under the [security policy](../SECURITY.md). Universal packaging verifies the binary targets and architectures. Native Intel and macOS 14 runtime checks need separate evidence.
3. Check that the distributed DMG embeds the **approved 1.2.0 (3) app** and its expected `arm64` and `x86_64` slices; verify bundled resources, third-party licences, Release-only flags and native cursor recovery evidence.
4. Record the proposed tag commit and the provenance of the approved package. If the tag points to a later commit, compare its app, Xcode project, bundled resources and packaging inputs to the build commit. Resolve any material mismatch before publication.
5. Refer to the [owner-confirmed Beta 2 acceptance record](BETA2_ACCEPTANCE.md) dated 22 November 2026. Repeat the relevant manual check if a new defect changes the evidence.

## Verify the accepted installer

Beta 2’s approved installer is `Pokelet-1.2.0-build-3-Premium-Final-Test.dmg`. Its SHA-256 is `083546c4ad764a57332a8ec1757974631ebaf17b5a78f96a6c3b027c372193aa`. The recorded local build used app source from [`6ce0f30`](https://github.com/smcnab1/pokelet/commit/6ce0f3039e2c770ad743e0850039446f98c50e21) and packaging inputs from [`b86c060`](https://github.com/smcnab1/pokelet/commit/b86c0608958094e2190f24733b84fce08fcaeb80). The packaging branch tip `812c315` has the same tracked tree as `b86c060`. The later third-party notice addition covers the website font. Keep the accepted filename because the signed Minisign comment names it.

The three public assets go in `dist/release-staging/v1.2.0-beta.1/`. Keep test evidence in `build/` and the signing key outside the repository. From the repository root, verify the staged assets with Bash:

```bash
tag=v1.2.0-beta.1
dmg=Pokelet-1.2.0-build-3-Premium-Final-Test.dmg
digest=083546c4ad764a57332a8ec1757974631ebaf17b5a78f96a6c3b027c372193aa
public_key="$PWD/security/pokelet-minisign.pub"
stage="$PWD/dist/release-staging/$tag"

verify_assets() (
  set -u -o pipefail
  cd "$1" || exit 1
  shopt -s dotglob nullglob
  files=(*)
  test "${#files[@]}" -eq 3 || exit 1
  for asset in "$dmg" "$dmg.sha256" "$dmg.minisig"; do
    test -f "$asset" && test ! -L "$asset" || exit 1
  done
  printf '%s  %s\n' "$digest" "$dmg" | cmp - "$dmg.sha256" || exit 1
  shasum -a 256 -c "$dmg.sha256" || exit 1
  minisign -Vm "$dmg" -p "$public_key"
)

verify_assets "$stage"
```

The public key is sufficient for these checks. For a future unsigned candidate, use the local [signing script](../script/sign_release.sh) from a trusted Terminal and enter the passphrase only at the Minisign prompt.

## Distribution and installation disclosures

- The beta's ad hoc code signature is **not publisher authentication**. No Apple notarisation is claimed.
- Link to [Apple's per-app Open Anyway instructions](https://support.apple.com/102445). Users should only proceed if they trust the source and verification has succeeded; **never advise disabling Gatekeeper globally**. A macOS warning about damage or malware is a stop condition.
- Public Release builds exclude experimental Presentation Mode click suppression. Ordinary pointer features do not require Accessibility or Input Monitoring. Interactive-only sound behaviour may need an already-granted Accessibility permission and remains partially tested.
- Disclose incomplete native Intel, macOS 14, multi-display, VoiceOver and full keyboard-traversal testing. Universal build compatibility is not the same as verified runtime coverage.
- Keep local preferences and audio private; there is no account, usage telemetry or background updater.

## Owner-approved Beta 2 publication

1. Fetch `origin`, confirm the approved full SHA is current `origin/main` and its CI is green. Compare the app and packaging tree to `b86c060`, check the tag and release are unused, and run `verify_assets "$stage"`. Review the [release notes](BETA2_RELEASE_NOTES_DRAFT.md) and obtain **explicit owner approval** of the SHA, tag, assets and notes.
2. After approval, create the annotated tag at the approved full SHA with `git tag -a "$tag" "$approved_sha" -m "Pokelet 1.2.0 Beta 2"`. Push only that tag with `git push origin "refs/tags/$tag"` and verify the remote's peeled tag points to the approved SHA. Stop on any collision or failure.
3. Create a draft prerelease with all three verified assets. Use the prepared release branch for the notes. Stop if the draft or an upload fails. Inspect any existing draft and recover explicitly before continuing.

   ```bash
   verify_assets "$stage" &&
     gh release create "$tag" --verify-tag --draft --prerelease \
       --title "Pokelet 1.2.0 Beta 2" --notes-file docs/BETA2_RELEASE_NOTES_DRAFT.md \
       "$stage/$dmg" "$stage/$dmg.sha256" "$stage/$dmg.minisig"
   ```

4. Confirm the draft has exactly the three expected assets. Download them to a new directory with `gh release download "$tag" --pattern "$dmg*" --dir "$draft_download"` and run `verify_assets "$draft_download"`. Only after both checks pass, publish with `gh release edit "$tag" --draft=false --prerelease`. Use a second new directory to download and verify the published assets.
5. After successful public verification, merge the prepared website and docs PR. Pages deploys from `main`. Confirm the hosted download resolves to Beta 2 via the release listing API, then check the Studio image, mobile navigation, first-launch guidance, README links and public badges.

## Packaging commands for an unnotarised beta

`./script/package_release.sh` builds and checks a local universal app and ZIP in `dist/candidate/`. `./script/package_dmg.sh --beta` produces an ad hoc-signed beta DMG in `dist/beta/` with a checksum. The premium installer has a separate approved local candidate; do not assume this command reproduces its artwork without checking the exact current script and template. Compare package provenance before distribution.

## Optional future Developer ID and notarisation

For a later trusted distribution, enrol in the Apple Developer Program, obtain a **Developer ID Application** identity, configure a private `notarytool` credential profile, then execute the existing `./script/package_dmg.sh --notarise` flow only after specific approval. Validate the signing identity, hardened runtime, timestamp, notarisation log, stapled ticket and Gatekeeper assessment on the **actual DMG**. Keep private keys out of GitHub and avoid unnecessary CI secrets.

See [Apple's Developer ID certificate guidance](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/) and [notarisation guidance](https://developer.apple.com/documentation/technotes/tn3147-migrating-to-the-latest-notarization-tool). Apple notarisation would materially improve ordinary macOS installation trust, but is not claimed or required for this free public beta.

## Future build provenance

GitHub artifact attestations could bind a future premium DMG’s digest to the source commit and workflow that actually produced it. Consider that only when a trusted workflow builds and packages the exact DMG distributed to users. CI validates the source and packaging for this beta, while the accepted installer was built locally. Use the detached Minisign signature for its publisher verification. [GitHub’s artifact attestation guidance](https://docs.github.com/en/actions/concepts/security/artifact-attestations)
