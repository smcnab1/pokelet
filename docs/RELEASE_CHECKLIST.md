# Release checklist

Use this process for each proposed release. Record the candidate identity and results in the PR or release evidence, rather than editing this checklist for every version. [GitHub Releases](https://github.com/smcnab1/pokelet/releases) holds published notes and assets. The [changelog](../CHANGELOG.md) is the source for the release changes.

## 1. Identify and qualify the candidate

- Record the full source SHA, app version, build number, proposed unused tag, stable/prerelease status, package build source and packaging-input source.
- Require passing [macOS CI](../.github/workflows/macos.yml) for the intended source. Run the same [SwiftLint scan](../script/lint_swift.sh) for every proposed major production release. Resolve confirmed findings under the [security policy](../SECURITY.md).
- Build a universal candidate into a new directory with `./script/package_release.sh /path/to/new-candidate`. Inspect both architectures, bundle metadata, resources, licences, Release flags and signatures. Do not overwrite accepted packages or evidence.
- Run relevant [native and browser checks](../VERIFICATION.md), then record controlled desktop acceptance, actual hardware and any skipped checks. A universal build is not native Intel or minimum-macOS runtime acceptance.
- If the proposed tag follows the package build commit, compare the app, Xcode project, resources and packaging inputs. Document why the package still represents that source; resolve material differences before release.

## 2. Choose and disclose the distribution route

| Route | Local preparation | Required disclosure and evidence |
| --- | --- | --- |
| Ad hoc, unnotarised | `./script/package_dmg.sh --beta /path/to/new-output /path/to/Pokelet.app` | State that the app has no Apple Developer ID identity or notarisation. Obtain explicit approval of this distribution route and its limitations. |
| Developer ID and notarisation | Start with `./script/package_dmg.sh --check-signing`. Use the existing `--notarise` flow only with explicit approval and private credentials configured. | Verify the identity, hardened runtime, timestamp, notarisation log, stapled ticket and Gatekeeper result on the actual distributed DMG. |

See [DMG packaging](../packaging/dmg/README.md). Preserve the tracked installer template, background source and Finder layout. Filesystem metadata can change the DMG digest between builds: do not claim bit-for-bit reproducibility.

## 3. Verify the exact assets

Record the final installer filename and SHA-256. Generate its checksum and detached signature with the existing [signing script](../script/sign_release.sh), using the private key outside the repository and entering its passphrase only at the trusted Terminal prompt. Never replace a published signature or rename an accepted installer: its signed comment may name the file.

For a new candidate, signing requires its already-approved digest and a matching checksum sidecar:

```sh
./script/sign_release.sh /path/to/approved.dmg APPROVED_SHA256 /private/path/to/minisign.key
```

To verify without signing, use Bash and set `stage` and `dmg` to the approved asset directory and exact filename:

```bash
public_key="$PWD/security/pokelet-minisign.pub"
stage='/absolute/path/to/approved-assets'
dmg='EXACT-RELEASE-ASSET.dmg' # replace with the approved filename
(
  set -euo pipefail
  cd "$stage"
  test -f "$dmg" && test ! -L "$dmg"
  test -f "$dmg.sha256" && test ! -L "$dmg.sha256"
  test -f "$dmg.minisig" && test ! -L "$dmg.minisig"
  shasum -a 256 -c "$dmg.sha256"
  minisign -Vm "$dmg" -p "$public_key"
)
```

Check the staged file list against the approved asset list. Mount the DMG read-only and inspect the contained bundle, Applications shortcut, resources and signatures. Installation, audible output and live cursor recovery need separate observed results. [User verification instructions](VERIFYING_RELEASES.md)

## 4. Prepare notes and obtain approval

- Describe changes, upgrade behaviour, requirements, exact assets, verification instructions, signing/notarisation status and known limitations. Include any publicly known vulnerability identifiers fixed by the release.
- Use the same change bullets in GitHub Releases and What’s New. Export them from the changelog with `swiftc Pokelet/Models/ReleaseNotes.swift script/export_release_notes.swift -o /tmp/pokelet-release-notes`, then `/tmp/pokelet-release-notes CHANGELOG.md TAG BUILD`. Add installation and verification details to the GitHub release body.
- Disclose outstanding Intel, minimum-macOS, display or accessibility checks. Keep automated, owner-reported and directly observed evidence distinct.
- Link [installation guidance](https://github.com/smcnab1/pokelet/wiki/Installation), the [verification guide](VERIFYING_RELEASES.md), [privacy](../PRIVACY.md) and [feedback](https://github.com/smcnab1/pokelet/issues/new/choose).
- For an unnotarised build, link [Apple’s per-app first-launch guidance](https://support.apple.com/102445). Never advise disabling Gatekeeper. Damage, malware or failed verification is a stop condition.
- Obtain explicit owner approval of the source SHA, tag, exact assets/digests, notes and distribution route **before tagging, publishing or deploying**. Approval of a past release is not approval of the next one.

## 5. Publish only after approval

1. Refresh `origin/main`, confirm the approved commit and CI, and stop if the proposed tag or release already exists. Do not move existing tags or replace published assets.
2. Create and push only the approved tag. Verify its remote target. Create a draft release with the agreed prerelease status and approved files. Stop on any collision or upload failure; inspect the existing state before recovery.
3. Download draft assets into a new directory. Compare the file list and digests with the approved manifest, then repeat checksum and signature verification on the downloaded bytes.
4. Publish only within the explicit approval. Download published assets into another new directory and repeat the checks. Record release URL, source SHA and verified digests.
5. Check the public website resolves the intended release and DMG, including prereleases. Release discovery is automatic; README, Wiki navigation and website labels should not need version edits. Retain a link to the release listing as fallback.

Merging changes under `docs/site` or the Pages workflow deploys the website from `main`; obtain the required approval separately. Publishing a release also changes the existing website’s dynamically selected download.

## Signed Sparkle updates

Normal local and CI releases use the current ad hoc signing path. They include offline version history and direct users to GitHub Releases for manual updates. The updater is compiled into Debug for isolated acceptance and into Release when deliberately packaging a signed update candidate. Hardened ad hoc Release cannot load Sparkle on the tested macOS host because library validation rejects the framework. The manual-download build keeps Hardened Runtime and library validation intact. The first update-enabled build must be installed manually from the verified release.

Use the dedicated Pokelet key for signed feeds and ZIPs containing a Pokelet app bundle. Sparkle’s [package installer advisory](https://github.com/sparkle-project/Sparkle/security/advisories/GHSA-gcjm-h3jh-p2vc) concerns `.pkg` and `.mpkg` updates. Check upstream advisories again before activating the feed.

### Prepare

1. Decide whether to activate updates for a stable release. The maintainer must supply a **Developer ID Application** identity and a notary profile for the opt-in distribution path. Keep using the existing ad hoc manual-download path if you want to release without those credentials.
2. Download the [pinned Sparkle command-line tools](https://github.com/sparkle-project/Sparkle/releases/tag/2.10.1) and verify the SHA-256 of `Sparkle-2.10.1.tar.xz` against the upstream release digest `1a856d2a9edb8e628de88121d7be04cf0e2167f8641650b78fca00b14244cf27`. Run `generate_keys --account pokelet-stable` on the maintainer’s signing Mac. Back up the private key securely and offline. Do not add it to Git, Pages or Actions. The package script reads the public key from the named Keychain entry. The Minisign signing key remains separate.
3. Set the approved marketing version, then increase the integer build across all releases, including betas. Move the applicable notes from **Unreleased** to the top dated changelog entry. Use a heading such as `## [v1.3.0] - YYYY-MM-DD`, then `Build:`, `Title:` and non-empty `### Added`, `### Changed`, `### Fixed` or `### Security` sections with single-line bullets as applicable. Future versions can skip earlier releases. The app matches notes by bundle version and build. Existing users with saved settings can see the offer on their first upgrade from a build that predates release history tracking.
4. Run the package and verification commands below against clean approved source. The same bundle identifier and signing team apply to the app and embedded Sparkle code. Separately submit the candidate ZIP for notarisation with `xcrun notarytool submit … --keychain-profile … --wait`. Check that the submission was accepted. Staple the resulting ticket to the candidate **app** with `xcrun stapler staple`, then verify it with `xcrun stapler validate` and the macOS distribution check. The ZIP prepared before stapling is the notarisation input. Create the public update ZIP from the stapled app.
5. Run the staging tool. It uses Sparkle to generate and verify the appcast, Markdown notes and ZIP, and writes their checksums. It checks the stable tag, bundle, build, signatures, archive URLs and release-note URLs. Use the same exported release notes in the GitHub release body, then add the assets, verification and compatibility details there. Build the DMG from the same stapled app using `./script/package_dmg.sh --notarise dist/update-installer dist/update-candidate/Pokelet.app` and the approved notary profile. Follow the existing checksum and Minisign procedure for the final DMG.

```sh
export POKELET_SPARKLE_TOOLS=/absolute/path/to/Sparkle/bin
export POKELET_SPARKLE_KEYCHAIN_ACCOUNT=pokelet-stable
export POKELET_DEVELOPER_ID=APPROVED_CERTIFICATE_FINGERPRINT
./script/package_release.sh --developer-id dist/update-candidate
# Notarise the candidate ZIP and staple the candidate app before staging.
python3 script/prepare_sparkle_release.py \
  --app dist/update-candidate/Pokelet.app --tag v1.3.0 \
  --sparkle-tools "$POKELET_SPARKLE_TOOLS" \
  --keychain-account "$POKELET_SPARKLE_KEYCHAIN_ACCOUNT" \
  --output dist/sparkle-v1.3.0
```

### Qualify and publish

- Test a manually installed initial build and an upgrade to a higher build in a disposable macOS environment. Cover a dockless background check, signed installation and relaunch, bad signatures, no update, offline recovery, suppression of prereleases, saved preferences and restoration of the system pointer. Also verify the official installer from a quarantined download. The Debug acceptance bundle identifier is `uk.co.sammcnab.Pokelet.UpdateAcceptance`. Only that Debug bundle accepts `http://127.0.0.1:<port>/appcast.xml`. Build two versions with that identifier, `POKELET_UPDATE_FEED_URL` and a disposable `POKELET_UPDATE_PUBLIC_KEY`, then stage a signed ZIP and appcast with the matching test key. Keep the test feed and key isolated from release inputs.
- Keep prereleases available through manual GitHub downloads. The public updater uses Sparkle’s default stable channel. The staging tool rejects prerelease tags. After owner approval, publish the stable GitHub Release archive at the exact versioned URL and compare the re-downloaded bytes with `SHA256SUMS`.
- In a separately approved Pages change, publish only the signed `appcast.xml` and versioned Markdown notes under `docs/site/updates/`. Retain older notes for clients that already fetched an earlier appcast. Check the public HTTPS feed at `https://smcnab1.github.io/pokelet/updates/appcast.xml` and every enclosure and notes URL against locally verified bytes. Re-sign through Sparkle if the feed or notes change; edits invalidate the signature. Full ZIPs support direct, skipped-version updates across the supported platform range.
- Sparkle requires signatures before extraction and validates signed feeds and release notes. Feed-signature expiry recovery is disabled. If the private key is lost, keep the invalid feed offline and plan an explicitly approved recovery or verified manual reinstall. Consult [Sparkle’s key rotation rules](https://sparkle-project.org/documentation/#rotating-signing-keys) before changing the built-in key.

## Historical records

The [Beta 2 acceptance](BETA2_ACCEPTANCE.md), [readiness](BETA2_RELEASE_READINESS.md) and [original release checklist](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/RELEASE_CHECKLIST.md) preserve the earlier one-off decision and package provenance. They are evidence for that release only.

Future workflow attestations should describe the exact distributed bytes and the workflow that produced them. CI validation of source alone does not attest a locally built installer. [GitHub artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations)
