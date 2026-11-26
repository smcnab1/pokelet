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
5. Check the public website resolves the intended release and DMG, preferring stable once available. Release discovery is automatic; README, Wiki navigation and website labels should not need version edits. Retain a link to the release listing as fallback.

Merging changes under `docs/site` or the Pages workflow deploys the website from `main`; obtain the required approval separately. Publishing a release also changes the existing website’s dynamically selected download.

## Optional usage analytics

Release packaging explicitly clears the TelemetryDeck app ID and namespace for both channels. Complete the [privacy review](ANALYTICS.md#before-enabling-reporting) before proposing a change to enable reporting.

## Signed Sparkle updates

Default local and CI builds use manual downloads. They retain offline version history and have no appcast or public key. Install the first update-enabled build manually from the verified installer. Existing manual-download builds, including Beta 3, continue to use GitHub Releases.

| Channel | Release tag example | Keychain account | Appcast directory |
| --- | --- | --- | --- |
| Beta | `v1.3.1-beta.1` | `pokelet-beta` | `docs/site/updates/beta/` |
| Stable | `v1.3.1` | `pokelet-stable` | `docs/site/updates/` |

Each channel uses a separate key and HTTPS URL. Beta entries carry Sparkle’s `beta` channel marker. Stable builds accept only default-channel entries from the stable feed, verified with the stable key. Keep these keypairs separate when generating, backing up or recovering them. The optional background check still requires opt-in and installation requires user action.

### Create and back up a signing key

Verify the [Sparkle 2.10.1 tool archive](https://github.com/sparkle-project/Sparkle/releases/tag/2.10.1) before extracting it. The upstream SHA-256 for `Sparkle-2.10.1.tar.xz` is `1a856d2a9edb8e628de88121d7be04cf0e2167f8641650b78fca00b14244cf27`.

Run this on the signing Mac from the directory containing the verified archive. Use a fresh directory on an encrypted removable volume you control. Set `channel=stable` when preparing the stable account and backup.

```sh
printf '%s  %s\n' 1a856d2a9edb8e628de88121d7be04cf0e2167f8641650b78fca00b14244cf27 Sparkle-2.10.1.tar.xz | shasum -a 256 -c - || exit 1
mkdir sparkle-2.10.1
tar -xJf Sparkle-2.10.1.tar.xz -C sparkle-2.10.1
export POKELET_SPARKLE_TOOLS="$PWD/sparkle-2.10.1/bin"
channel=beta
export POKELET_SPARKLE_KEYCHAIN_ACCOUNT="pokelet-$channel"
"$POKELET_SPARKLE_TOOLS/generate_keys" --account "$POKELET_SPARKLE_KEYCHAIN_ACCOUNT"
(
  set -eu
  umask 077
  backup="/Volumes/YOUR-ENCRYPTED-OFFLINE-VOLUME/$POKELET_SPARKLE_KEYCHAIN_ACCOUNT"
  mkdir "$backup"
  "$POKELET_SPARKLE_TOOLS/generate_keys" --account "$POKELET_SPARKLE_KEYCHAIN_ACCOUNT" -x "$backup/private-key"
  test -s "$backup/private-key"
)
```

Sparkle retains an existing key and prints only its public key in the generation step. The export writes sensitive bytes directly to the encrypted volume. Eject the volume and keep it offline in secure custody. After confirming the backup, set `POKELET_SPARKLE_BACKUP_CONFIRMED` to the account name for the packaging command. Keep private keys out of Git, Pages, Actions and cloud storage. The DMG Minisign key is separate. To restore to a fresh Keychain account, use `generate_keys --account ACCOUNT -f /path/to/offline/private-key` and verify the public key with `generate_keys --account ACCOUNT -p` against the previously distributed app.

### Stage from approved source

1. Set the approved marketing version and increase the integer build across releases, including betas. Compare it with the latest published builds. Move the applicable changes from **Unreleased** into a dated top entry with the exact tag, `Build:`, `Title:` and non-empty `Added`, `Changed`, `Fixed` or `Security` sections. The app matches bundled notes by marketing version and build.
2. Build into a new directory. For the free route, use `--ad-hoc-updates`. This retains Hardened Runtime and grants only `com.apple.security.cs.disable-library-validation` to the main Pokelet executable. Ad hoc signatures have no Team ID. The entitlement relaxes the process’s check on loaded libraries, including third-party libraries, so it can load the embedded Sparkle framework. Package verification checks the nested code signatures. Apple publisher verification and notarisation are unavailable on this route. [Apple’s library validation guidance](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.cs.disable-library-validation) · [Sparkle’s setup guide](https://sparkle-project.org/documentation/)
3. For the optional Developer ID route, set `POKELET_DEVELOPER_ID` to the approved certificate fingerprint and substitute `--developer-id`. Before staging, submit the package ZIP with `xcrun notarytool submit ZIP --keychain-profile PROFILE --wait`. After acceptance, run `xcrun stapler staple APP` and `xcrun stapler validate APP` on the candidate app. Package the installer with `--notarise` from that app.
4. Stage the signed update ZIP, appcast and Markdown release notes with the same account that supplied the bundle’s public key. Staging verifies all signatures, the expected channel and URLs, and writes `SHA256SUMS`. For the free route, build the manual-install DMG with `--beta` from the same candidate app and follow the usual checksum and Minisign procedure.

```sh
# From the repository, with the tools and account set above.
channel=beta
tag=v1.3.1-beta.1 # replace with the approved unused tag
export POKELET_SPARKLE_BACKUP_CONFIRMED="$POKELET_SPARKLE_KEYCHAIN_ACCOUNT"
./script/package_release.sh --ad-hoc-updates --channel "$channel" "dist/$tag-candidate"
python3 script/prepare_sparkle_release.py \
  --app "dist/$tag-candidate/Pokelet.app" --tag "$tag" --channel "$channel" \
  --sparkle-tools "$POKELET_SPARKLE_TOOLS" \
  --keychain-account "$POKELET_SPARKLE_KEYCHAIN_ACCOUNT" --output "dist/$tag-sparkle"
./script/package_dmg.sh --beta "dist/$tag-installer" "dist/$tag-candidate/Pokelet.app"
```

### Verify and activate the public feed

1. Qualify two universal **Release** builds with increasing builds and a disposable EdDSA key. For the local test only, pass Xcode `PRODUCT_BUNDLE_IDENTIFIER=uk.co.sammcnab.Pokelet.UpdateAcceptance`, `POKELET_UPDATE_COMPILATION='POKELET_SIGNED_UPDATES POKELET_UPDATE_ACCEPTANCE'`, `CODE_SIGN_ENTITLEMENTS=packaging/AdHocUpdates.entitlements`, `CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO`, `POKELET_UPDATE_FEED_URL=http://127.0.0.1:PORT/appcast.xml` and the disposable `POKELET_UPDATE_PUBLIC_KEY`. Use Sparkle’s `generate_appcast` with `--maximum-deltas 0` and loopback download and notes URL prefixes. Exercise offline recovery, tampered feed and archive rejection, installation, relaunch, preferences and older-build rejection. Use the separate bundle identity and a disposable install directory. Public Release packaging rejects this test profile.
2. Check current [upstream Sparkle advisories](https://github.com/sparkle-project/Sparkle/security/advisories). Pokelet stages ZIPs of app bundles. Sparkle’s [installer package advisory](https://github.com/sparkle-project/Sparkle/security/advisories/GHSA-gcjm-h3jh-p2vc) concerns `.pkg` and `.mpkg` updates.
3. Obtain separate approval to publish the versioned ZIP at the exact GitHub Release enclosure URL. Mark beta releases as prereleases. Download the public ZIP and compare it with `SHA256SUMS`. For the first rollout, hold the bootstrap DMG until feed verification is complete.
4. With separate approval for Pages, copy the signed `appcast.xml` and versioned Markdown notes into the directory for that channel. Retain earlier notes. The existing Pages workflow publishes this directory from `main`. Fetch the deployed HTTPS appcast, notes and enclosure and compare each with the staged bytes using `shasum -a 256 -c SHA256SUMS` in the directory containing the downloads and the local manifest. Use `curl --fail --location --proto '=https' --proto-redir '=https'` for each download. Confirm the expected channel, key, URLs and builds before distributing the verified first-install DMG. Check that stable clients cannot see the beta item.
5. Serve only the exact signed bytes. Sparkle verifies appcasts and release notes and verifies archives before extraction. Keep the feed-signature fallback disabled. If a private key is lost or suspected compromised, take the affected feed offline and plan recovery or a verified manual reinstall. Review [Sparkle’s key rotation rules](https://sparkle-project.org/documentation/#rotating-signing-keys) before changing the built-in key.

### Proposed Wiki wording for feed launch

Update **Installation** and **FAQ** once the corresponding feed is live. In a signed-update build, open **Studio → Updates** to check the installed channel. You can opt into automatic checks and choose when to install. Builds with manual updates use **GitHub Releases**. Installing the first update-enabled ad hoc build still uses the verified manual download and Apple’s per-app first-launch guidance, where macOS offers it.

## Historical records

The [Beta 2 acceptance](BETA2_ACCEPTANCE.md), [readiness](BETA2_RELEASE_READINESS.md) and [original release checklist](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/RELEASE_CHECKLIST.md) preserve the earlier one-off decision and package provenance. They are evidence for that release only.

Future workflow attestations should describe the exact distributed bytes and the workflow that produced them. CI validation of source alone does not attest a locally built installer. [GitHub artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations)
