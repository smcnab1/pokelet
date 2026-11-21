# Beta 2 release readiness

**21 November 2026 · NO-GO for public publication.** The release metadata is approved. Local build, package integrity and data rehearsals passed. A Developer ID-signed, notarised DMG and first-launch acceptance on a disposable system are still required.

| Release input | Value |
| --- | --- |
| Starting source | `fix/native-studio` at `1e8d751abc51d10286b4eeec80e4bc71a0a2e989` |
| Application source used for the earlier offline upgrade rehearsal | `9f2004475ddd2f014e40e90c3903b35b9cf2417a`, built with temporary version and build overrides |
| Reviewed base | Local and remote `main` at `1c07754137844bf2fac1103fa7cc09c694db4f59`, an ancestor of the candidate |
| Approved metadata | **Pokelet 1.2.0 Beta 2**, version `1.2.0`, build `3`, planned tag `v1.2.0-beta.1`. Debug and Release use the committed Xcode settings, and About reads the generated bundle's version and build. The tag is unused and reserved for the eventual approved release commit. |
| Verification host | Apple M2, macOS 27.3 (26C5047e), Xcode 27.2 (27B52), one 2× display |

## Publication gates

| Gate | Status |
| --- | --- |
| Release identity | **Approved.** Debug and Release use version `1.2.0` and build `3`. Qualify the eventual release SHA before tagging. |
| Apple signing | **Blocked.** The configured keychains have one valid Apple Development identity, zero Developer ID Application identities and zero matching Developer ID Application certificates. The team’s Developer Program membership and certificate inventory outside this Mac are unverified. |
| Notary service | **Pending.** `notarytool` 1.1.4 is available. No Pokelet notary profile is configured in the release environment. A Keychain profile may already exist under an owner-known name. Confirm the team and profile, validate access, then submit the approved DMG, inspect Apple’s log and verify the stapled ticket. |
| Trusted installation and upgrade | **Pending.** Requires the signed, notarised DMG and a clean macOS VM snapshot, spare Mac or approved isolated test account. Qualify first launch, upgrade, menu bar and Dock paths, and post-install pointer recovery. |
| GitHub and exact-commit CI | **Pending.** PR creation is approved. Merge and publication each require separate approval. Verify the deployed forms after merge. |
| Accessibility and compatibility | **Partial.** Complete the desktop checks below or agree the coverage limits for a controlled beta. |

See the [release checklist](RELEASE_CHECKLIST.md) for signing, submission recovery and publishing commands. The Xcode project uses manual ad hoc signing and hardened runtime. The Developer ID private key and `notarytool` profile belong in Keychain. The GitHub workflow needs no Apple credentials. GitHub showed no repository Actions secrets or variables, and the only configured environment was `github-pages`.

## Local qualification

| Check | Result |
| --- | --- |
| Swift and static checks | **PASS.** 46 SwiftPM tests on arm64 and 46 x86_64 XCTest cases under Rosetta, with warnings treated as errors during compilation. Debug build and analysis, universal Release build and analysis, Actionlint, ShellCheck, Bash syntax, documentation links and diff whitespace checks passed. |
| Layout and rendering | **PASS.** Native Studio layout in both widths, appearances and text sizes and the 72-case pointer renderer fixture passed. The isolated Debug Studio reopened three times in the same process and quit. The [prior autonomous desktop matrix](BETA2_ACCEPTANCE.md#autonomous-desktop-acceptance) covers actual clicks in all three display modes and recovery on normal and unexpected exit. |
| ZIP and DMG | **PASS.** Both slices target macOS 14.0 and advertise hardened runtime. Strict signature verification, ZIP extraction, image integrity, both checksums, mounted layout, Applications shortcut, exact executable and bundled licences, icon and four WAV files passed. The candidate signature is ad hoc. |
| Experimental controls | **PASS for Release.** Both Release slices exclude all three Debug acceptance flags and the `get-task-allow` entitlement. The native model smoke verified that passing all three flags leaves Presentation Mode and test profiles disabled. The Presentation pane marks click suppression unavailable. The Debug-only recovery driver compiled. A fresh live run would post a global hotkey and remains outside this rehearsal. |
| Hosted CI | **Pending for this branch.** The latest [macOS workflow on `main`](https://github.com/smcnab1/pokelet/actions/runs/44761331064) passed. The candidate’s local workflow checks passed, and CI now includes Release analysis. The Pages workflow watches changes to `docs/site/` and its own workflow on `main`. This PR changes neither path. |

Local rehearsal artefacts and logs are under `build/beta2-release-prep/`. The proposed ad hoc DMG SHA-256 is `d3780f69bf9fbec2dce675f171b366b319c81c8d13809783cd8b2b1b13456ec2`. Generate the trusted DMG and its own checksum from the approved release commit.

## Installation and upgrade results

| Check | Result |
| --- | --- |
| Fresh installation rehearsal | **PASS for bundle copy and defaults.** The candidate copied from its read-only DMG into disposable `Applications`, with the correct bundle ID, version and build. A source-level fresh profile loaded Companion, pointer disabled, sounds muted, Option–Command–P and default menu bar and Dock preferences. |
| Public Beta 1 to proposed Beta 2 | **PASS offline.** The actual public Beta 1 DMG matched its published SHA-256. Its app (`1.1.0` build `2`) was staged and replaced with the Beta 2 app (`1.2.0` build `3`) under the same bundle identifier. Beta 1 source generated the preference and custom WAV fixtures. Beta 2 read and round-tripped the values, retained both a saved Beta 1 default shortcut and a custom shortcut, and decoded the same WAV bytes. The real Pokelet preferences plist matched its preflight checksum. |
| Gatekeeper | **Expected rejection.** With assessments enabled, `spctl` rejected both ad hoc app bundles and both unsigned DMGs. Browser quarantine, Finder first launch and acceptance of the trusted DMG remain pending. |
| Menu bar, Dock and recovery after installation | **Pending on the installed trusted app.** The earlier isolated desktop matrix verified the Dock fallback and pointer restoration. The native status menu was inaccessible to its probe while the existing menu utilities were running. |

### Disposable desktop acceptance

Use a clean macOS VM snapshot or a spare Mac. Keep the production installation and profile outside the test environment. Use the test copy’s exact bundle URL and PID when verifying termination. Keep a keyboard-accessible recovery route and a simple local click target. Record the OS, architecture, display count and scale, download source, SHA-256, signature, quarantine and each observed result.

1. **Fresh** → Browser-download the stapled DMG from approved private staging. Compare its checksum and check the download with `xattr -p com.apple.quarantine`. Mount it in Finder, drag Pokelet to Applications, eject and open from Applications. Confirm the normal Gatekeeper first-launch experience, no unexpected permission prompts, pointer off, Companion, muted sound and Option–Command–P. Quit and reopen.
2. **Upgrade** → Restore a clean snapshot. Install the checksum-verified [public Beta 1](https://github.com/smcnab1/pokelet/releases/tag/v1.1.0-beta.1) using its documented per-app procedure if needed. Set a recognisable character and size, import a short test WAV, assign a recognisable shortcut and leave restore-on-launch off. Quit, retain the guest snapshot, then replace the app in the same location with Beta 2. Verify settings, actual shortcut activation, custom sound playback and persistence after relaunch.
3. **Menu bar, Dock and pointer** → In each scenario confirm the menu opens Studio, its Quit command exits, and Dock presence follows General and Studio visibility. Verify the first ordinary click after disabling, closing and quitting. In the disposable session, repeat with Replace active and terminate only the verified test PID while the native arrow is hidden. Confirm that the arrow returns and the click target works.
4. **Accessibility** → On the approved test desktop, exercise Tab and Shift–Tab through all panes, keyboard activation and focus after navigation. With VoiceOver, check announcements for the pane rail, picker, preview, switches and shortcut recorder. Repeat representative layouts and movement with system Reduce Motion and Reduce Transparency enabled, then restore the test environment.

## Accessibility and hardware coverage

- **Observed:** The read-only probe reported VoiceOver, Reduce Motion and Reduce Transparency off. Native layout covered larger text and both colour schemes. Prior desktop evidence covers Studio shortcuts, named AX controls and Dock reopen. Dedicated tests cover reduced-motion rendering and the permission-unavailable interactive-sound fallback.
- **Outstanding:** Full Tab traversal, spoken VoiceOver output, system Reduce Motion and Reduce Transparency enabled, physical menu bar access with the existing menu utilities, audio playback with Accessibility granted and acoustic output. Any live change to permissions, settings or another app requires separate approval.
- **Hardware limits:** One 2× Apple silicon display was available. The 1× raster fixture and Rosetta XCTest run provide renderer and translated-code coverage. Multi-display, physical display scaling, Intel hardware and macOS 14 runtime remain unverified.

## Pull request and release handoff

The branch includes the frozen Studio and pointer changes, compatible feedback links, signing preflight, Release CI analysis and Debug-only acceptance profiles. The two updated issue forms retain `bug.yml`, `feature.yml` and every existing field ID, so existing links and field query parameters remain valid. The chooser’s private-security link and blank-issue setting are preserved. Both form labels exist. After merge, open the chooser and the two existing form URLs, confirm there is one entry of each kind, and load a synthetic `environment` prefill with punctuation and a line break. Close the drafts after checking the fields. [GitHub form schema](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-githubs-form-schema)

The [changelog](../CHANGELOG.md) records the approved release metadata. The release-note draft is in `build/beta2-release-prep/BETA2_RELEASE_NOTES.md`. The verified Beta 1 asset remains the public download during preparation.

### Approvals required

1. Review hosted checks and separately approve the merge.
2. Authorise Apple Developer ID issuance or import and Keychain profile setup if needed. Authorise Apple notarisation of the approved release SHA separately.
3. Approve the disposable macOS test environment and any permission, system accessibility or hardware changes used for acceptance. Agree any compatibility limits that will accompany the beta.
4. Approve tagging, publishing the verified stapled DMG and checksum, and switching public download links to the new release.
