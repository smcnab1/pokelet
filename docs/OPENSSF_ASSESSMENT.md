# OpenSSF assessment

**Evidence reviewed on 22 November 2026.** The [public record for Pokelet 16999](https://www.bestpractices.dev/projects/16999.json) records **Passing**. [Scorecard reported 5.8/10](https://scorecard.dev/viewer/?uri=github.com/smcnab1/pokelet) from its [22 November scan](https://github.com/smcnab1/pokelet/actions/runs/45024169644), which preceded the Passing award and successful Swift CodeQL scan. Scorecard measures repository signals separately from the badge and Baseline assessments.

The [public release](https://github.com/smcnab1/pokelet/releases/tag/v1.1.0-beta.1) is Beta 1. Beta 2 is **1.2.0 (3)**, planned as `v1.2.0-beta.1`, and remains unpublished.

## Historical Passing questionnaire review

This records the nine criteria reviewed before the maintainer completed the [Passing form](https://www.bestpractices.dev/en/projects/16999/passing), using the [official Passing criteria](https://www.bestpractices.dev/en/criteria/0). Use the live record for current answers.

| Criterion | Recorded → recommended | Justification and evidence URL |
| --- | --- | --- |
| `report_responses` · MUST | ? → Met if the maintainer confirms no eligible reports on any channel | Pokelet opened to the public in November 2026. No bug reports were submitted in the required 2–12 month window, so there were no reports to acknowledge. Bug reports are handled in GitHub Issues. [Public issue history](https://github.com/smcnab1/pokelet/issues?q=is%3Aissue) |
| `enhancement_responses` · SHOULD | ? → Met if the maintainer confirms no eligible requests on any channel | No enhancement requests were submitted in the required 2–12 month window. The only public issue at review was opened by the maintainer this month. Enhancement requests are discussed in GitHub Issues. [Issue history](https://github.com/smcnab1/pokelet/issues?q=is%3Aissue) · [Issue 9](https://github.com/smcnab1/pokelet/issues/9) |
| `build_floss_tools` · SHOULD | Unmet → Unmet with justification | The native app build uses Apple's Xcode build system, macOS SDK and system frameworks. The FLOSS Swift compiler and SwiftPM test runner do not constitute a FLOSS-only release toolchain. [Build instructions](https://github.com/smcnab1/pokelet/blob/main/CONTRIBUTING.md#build-from-source) |
| `test_most` · SUGGESTED | ? → Unmet | The SwiftPM suite and native smoke tests cover core, rendering, input recovery and packaging paths. Instrumented SwiftPM tests covered 1,031 of 1,257 source lines (82.0%) in the subset compiled by that test target, with no branch counters. This leaves the full app's branch, field and feature coverage unestablished. [Test targets](https://github.com/smcnab1/pokelet/blob/main/Package.swift) · [Test evidence](https://github.com/smcnab1/pokelet/blob/main/VERIFICATION.md) |
| `vulnerabilities_critical_fixed` · SHOULD | ? → ? pending maintainer confirmation | The public advisory list and project records reviewed show no critical vulnerabilities. Check the private intake and any other channels. **If none were reported**, record Met with “No critical vulnerabilities have been reported through Pokelet's reporting channels as of the review date.” Otherwise use the actual handling dates. [Advisories](https://github.com/smcnab1/pokelet/security/advisories) · [Reporting policy](https://github.com/smcnab1/pokelet/security/policy) |
| `no_leaked_credentials` · MUST | ? → Met based on reviewed evidence | GitHub secret scanning and push protection are enabled, with zero alerts returned. A redacted Gitleaks scan of 78 commits reachable from fetched public branches and tags flagged the same public browser preference key in `cursor.js` twice. Both hits were false positives. No valid private credential was identified in the reviewed public history. [Flagged source](https://github.com/smcnab1/pokelet/blob/10ce7dc488f0493248f14b8487ee2f9d8d00d2bc/docs/site/cursor.js#L2) · [Assessment record](https://github.com/smcnab1/pokelet/blob/main/docs/OPENSSF_ASSESSMENT.md#repository-controls) |
| `static_analysis` · MUST | Unmet → Met once merged and run on the proposed release source | Pokelet runs MIT-licensed SwiftLint over all native app Swift source in its macOS CI, in addition to strict compiler warnings and Xcode analysis. The release checklist requires the same scan for any proposed major production release. [CI](https://github.com/smcnab1/pokelet/blob/main/.github/workflows/macos.yml) · [Release checklist](https://github.com/smcnab1/pokelet/blob/main/docs/RELEASE_CHECKLIST.md) |
| `static_analysis_common_vulnerabilities` · SUGGESTED at Passing, MUST at Silver | Unmet → Met once merged and running | SwiftLint flags use of legacy cryptographic hashes and manual server-trust credential construction for review. Both rules were verified with failing fixtures. These are targeted source checks for weak cryptography and TLS verification risks. [Rules](https://github.com/smcnab1/pokelet/blob/main/.swiftlint.yml) · [Check](https://github.com/smcnab1/pokelet/blob/main/script/lint_swift.sh) |
| `static_analysis_often` · SUGGESTED | Unmet → Unmet | SwiftLint runs on PR updates and pushes to main, covering each tested integration snapshot. Topic commits can be batched in one push and CI has no daily analysis schedule. [CI triggers](https://github.com/smcnab1/pokelet/blob/main/.github/workflows/macos.yml) |

At the time of the review, `vulnerabilities_critical_fixed` and `no_leaked_credentials` had blank justifications and `static_analysis` needed an updated justification. The form permits a reasoned SHOULD exception and a considered Unmet SUGGESTED answer. It provides no N/A option for `report_responses`, `enhancement_responses`, `test_most`, `no_leaked_credentials` or `vulnerabilities_critical_fixed`. The official criteria give no explicit rule for an empty reporting window. [Passing project 16649](https://www.bestpractices.dev/en/projects/16649/passing#report_responses) provides a self-assessed precedent for Met when the window contains no reports. The proposed answers disclose the empty window and depend on checking all channels. With eligible reports or requests, use the actual counts.

The coverage sample used `swift test --enable-code-coverage -Xswiftc -warnings-as-errors` (46 tests). The line totals sum only `Pokelet/` entries in the exported coverage report, excluding tests and the generated runner. [Package.swift](../Package.swift) excludes the app entry points, views and several native services.

**Check existing answers.** Keep `vulnerability_report_response` at N/A only after confirming zero reports across all channels in the previous six months. With reports, compare each first acknowledgement to the actual 14-day requirement. Keep `static_analysis_fixed` and `dynamic_analysis_fixed` at N/A only if there are no confirmed qualifying findings. The maintainer's `know_secure_design` and `know_common_errors` answers are personal attestations. [Security policy](../SECURITY.md) · [Verification](../VERIFICATION.md)

**Cryptography.** Official project and download endpoints use HTTPS. The SHA-256 checksum is delivered over HTTPS and checks bytes. The DMG's ad hoc signature carries no publisher identity. The app manages no passwords, cryptographic keys or nonces and implements no key agreement, supporting N/A for `crypto_password_storage`, `crypto_keylength`, `crypto_random` and `crypto_pfs`. The remaining crypto answers should describe standard platform/browser TLS and SHA-256, with the browser separately handling GitHub feedback and the website's metadata requests. [Privacy](../PRIVACY.md) · [Release notes and checksum](https://github.com/smcnab1/pokelet/releases/tag/v1.1.0-beta.1)

## Architecture and security boundaries

| Actor or boundary | Behaviour and control |
| --- | --- |
| User, AppKit and SwiftUI | The menu bar and Studio drive the app model and local preferences. The cursor controller observes macOS pointer events, renders an overlay and restores native cursor state when tracking stops. Release builds disable experimental click suppression. [App](../Pokelet/App) · [Cursor and input services](../Pokelet/Services) |
| Other apps and macOS permissions | Ordinary pointer operation uses passive observation. In the Beta 2 source, opt-in interactive-only audio queries limited Accessibility state when access is available. The app fails silent when it cannot classify a click. Local Debug presentation acceptance has a separate event tap and exit controls. [Privacy](../PRIVACY.md) · [Interactive acceptance](INTERACTIVE_ACCEPTANCE.md) |
| Local files and settings | Preferences stay in macOS preferences. The user selects audio; the importer bounds bytes and duration, checks decodability and writes a local copy atomically. Tests cover corrupt and oversized input. [SoundPlayer](../Pokelet/Services/SoundPlayer.swift) · [Audio tests](../Tests/PokeletCoreTests/AudioTests.swift) |
| Feedback and site | The native app launches the browser with editable feedback and sends no background requests. The static Pages site requests public release metadata over HTTPS. It validates expected GitHub API and download destinations and falls back to the releases page. [Feedback](../Pokelet/Models/GitHubFeedback.swift) · [Release selection](site/releases.js) · [Website](WEBSITE.md) |
| Source, CI and distribution | GitHub hosts source, PRs, reports and releases. Untrusted PR builds use read-only credentials; the separately scoped publishing jobs run from trusted main. A tampered artifact is a distribution risk; GitHub HTTPS protects transport and the checksum checks integrity. Publisher verification remains open. [Workflows](../.github/workflows) · [Release checklist](RELEASE_CHECKLIST.md) |

The main risks are losing access to ordinary input, over-reading across the Accessibility boundary, malformed imported files, and accepting a substituted release. This repository review mapped those risks to the code and existing checks. Separate evidence is still needed for runtime combinations called out in [verification](../VERIFICATION.md), broader application security analysis and artifact provenance.

## Repository controls

- GitHub's [active Protect main ruleset](https://github.com/smcnab1/pokelet/rules/27837727) applies to `main`. Its effective rules require a PR and the GitHub Actions `build` check. Deletion and force-push are blocked and the bypass list is empty. The review requirement is **zero**. No destructive push was needed to inspect the effective configuration.
- The repository is public and its access list contains only `smcnab1` as admin. The authenticated profile response did not establish MFA. GitHub reports read-only default workflow permissions and disallows Actions approving PRs. No repository or Pages environment Actions secrets were listed. The Pages deployment policy allows `main`.
- GitHub reports private vulnerability reporting, secret scanning and push protection enabled. Its secret scanning and Dependabot alert lists were empty. The [weekly Dependabot configuration](../.github/dependabot.yml) groups SHA-pinned Actions updates. [PR #10](https://github.com/smcnab1/pokelet/pull/10) tracks the separate Scorecard Action and SARIF uploader updates. The first Scorecard's six open results are configuration/process diagnostics, including branch protection from before the ruleset, rather than confirmed app vulnerabilities.
- GitHub’s default CodeQL setup completed the [Swift scan on main](https://github.com/smcnab1/pokelet/actions/runs/45025756118). At review, the open code-scanning entries were the six Scorecard diagnostics. GitHub listed zero open CodeQL alerts.
- Downloaded the public Beta 1 DMG via GitHub and verified its accompanying SHA-256 file. The read-only mount contained both bundled MIT notices, matching the repository copies. The app signature reported ad hoc with no Team ID. The source tag is lightweight and unsigned. No signed release manifest or attestation for those downloadable bytes was found.
- Inspected the tracked installer template on a read-only mount, including hidden files. It contains art, the volume icon, Finder layout metadata, an Applications symlink and an empty app placeholder. The [generator and layout sources](../packaging/dmg) describe how to review and regenerate it. The actual application executable is built outside version control.

## OSPS Baseline v2026.08.28

[Versioned controls](https://baseline.openssf.org/versions/2026-08-28). Levels are cumulative. **PR** means the evidence depends on this change being adopted. **Verify** means a person or additional evidence is needed. **Partial** means implementation covers part of the requirement. The matrices list new controls at each level.

### Level 1

| Control | Status | Evidence or remaining work |
| --- | --- | --- |
| OSPS-AC-01.01 | Verify | Confirm MFA for the owner and any account with sensitive repository access. The public project and API inspected do not prove enforcement. |
| OSPS-AC-02.01 | Met | Only the owner has privileged access. GitHub personal repositories have owner and collaborator roles; public accounts receive no write access by default and the owner must explicitly invite the only available collaborator role. [GitHub roles](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/repository-access-and-collaboration/permission-levels-for-a-personal-account-repository) |
| OSPS-AC-03.01 | Met | The effective [ruleset](https://github.com/smcnab1/pokelet/rules/27837727) requires PRs with no bypass actors. |
| OSPS-AC-03.02 | Met | The same ruleset blocks deletion. Deleting main requires deliberately changing the protection first. |
| OSPS-BR-01.01 | Met | No issue, PR, or collaborator text is interpolated into shell commands. The macOS checkout uses GitHub's selected commit, with context values scoped to Actions metadata and key fields. [Workflows](../.github/workflows) |
| OSPS-BR-01.03 | Met | Ordinary PRs run with `contents: read` and no persisted checkout credentials. No privileged job consumes their artifacts. Pages publishing is main-only and Scorecard publishes on main and schedules. [Workflows](../.github/workflows) |
| OSPS-BR-03.01 | Met | Official channels use HTTPS, with HTTPS enforcement enabled on Pages. [Site](https://smcnab1.github.io/pokelet/) · [Repository](https://github.com/smcnab1/pokelet) |
| OSPS-BR-03.02 | Met | GitHub serves release assets over authenticated HTTPS. This is the channel control; artifact signing is BR-06.01. [Releases](https://github.com/smcnab1/pokelet/releases) |
| OSPS-BR-07.01 | Met | Secret scanning and push protection enabled, read-only PR workflow and secret scan reviewed. [Repository controls](#repository-controls) |
| OSPS-DO-01.01 | Met | Install, basic settings, pointer modes, sounds and removal are covered. The Studio guide is labelled for the upcoming release. [User guide](README.md) |
| OSPS-DO-02.01 | Met | [Contributing](../CONTRIBUTING.md) links the [bug form](../.github/ISSUE_TEMPLATE/bug.yml) and requests diagnostic context. |
| OSPS-GV-02.01 | Met | Public [Issues](https://github.com/smcnab1/pokelet/issues) and PRs support discussion. |
| OSPS-GV-03.01 | Met | [Contributing](../CONTRIBUTING.md) describes proposing, testing and submitting changes. |
| OSPS-LE-02.01 | Met | [MIT](../LICENSE) is an [OSI-approved licence](https://opensource.org/license/mit). |
| OSPS-LE-02.02 | Met | The shipped Beta 1 app and adapted Quiet Pointer code are MIT; the site's separate font is documented. [Notices](../THIRD_PARTY_NOTICES.md) |
| OSPS-LE-03.01 | Met | [LICENSE](../LICENSE) is at the repository root. |
| OSPS-LE-03.02 | Met | The release source tag contains LICENSE and the downloaded app contained both MIT notices. [Beta 1 source](https://github.com/smcnab1/pokelet/tree/v1.1.0-beta.1) |
| OSPS-QA-01.01 | Met | [Source on GitHub](https://github.com/smcnab1/pokelet) is public. |
| OSPS-QA-01.02 | Met | Public [Git history](https://github.com/smcnab1/pokelet/commits/main) records authors, dates and changes. |
| OSPS-QA-02.01 | Met | [SwiftPM manifest](../Package.swift) declares the core targets and has zero external Swift package dependencies. The app uses Apple system frameworks. |
| OSPS-QA-04.01 | N/A | App, site and tooling occupy one repository. Quiet Pointer is attributed vendored source. |
| OSPS-QA-05.01 | Met | No generated executables found in tracked files; the installer image contains an empty placeholder. [Template](../packaging/dmg/README.md) |
| OSPS-QA-05.02 | Met | Tracked template contents were inspected. Remaining binary files are assets such as audio, font and images. [Template](../packaging/dmg/README.md) · [Notices](../THIRD_PARTY_NOTICES.md) |
| OSPS-VM-02.01 | Met | [Security policy](../SECURITY.md) directs reports to the enabled private intake. This PR also names the security contact. |

### Level 2 additions

| Control | Status | Evidence or remaining work |
| --- | --- | --- |
| OSPS-AC-04.01 | Met | GitHub defaults to read access. Workflow permissions are explicit, with write scopes limited to the required publishing jobs. [Workflows](../.github/workflows) |
| OSPS-BR-02.01 | Met | Beta 1 has a unique release version and [tag](https://github.com/smcnab1/pokelet/releases/tag/v1.1.0-beta.1). |
| OSPS-BR-04.01 | Met | Beta 1 has descriptive [release notes](https://github.com/smcnab1/pokelet/releases/tag/v1.1.0-beta.1) and [changelog](../CHANGELOG.md); no public security fixes were identified. |
| OSPS-BR-05.01 | Met | Xcode/SwiftPM consume platform SDKs and GitHub Actions resolves Actions pinned to commit hashes. [CI](../.github/workflows/macos.yml) · [Dependabot](../.github/dependabot.yml) |
| OSPS-BR-06.01 | Gap | Public Beta 1 assets lack a publisher signature. The [release checklist](RELEASE_CHECKLIST.md) prepares detached Minisign for the upcoming beta. Coverage remains open until signed assets are published. |
| OSPS-DO-06.01 | PR | [Contribution guide](../CONTRIBUTING.md) describes Apple frameworks, SwiftPM, Action pins and tracking vendored components. |
| OSPS-DO-07.01 | Met | [Build guide](../CONTRIBUTING.md#build-from-source) specifies Xcode, macOS SDK, scheme and commands. [Architecture](#architecture-and-security-boundaries) identifies major platform interfaces. |
| OSPS-GV-01.01 | PR | [Contributing](../CONTRIBUTING.md#review-and-maintenance) names the sole maintainer; the repository access list agrees. |
| OSPS-GV-01.02 | PR | [Contributing](../CONTRIBUTING.md#review-and-maintenance) defines maintainer and contributor responsibilities. |
| OSPS-GV-03.02 | Met | [Contributing](../CONTRIBUTING.md) describes acceptable contributions, testing and provenance of assets. |
| OSPS-LE-01.01 | Gap | MIT contribution terms exist. There is no per-commit authorship-rights attestation requirement enforced by GitHub. |
| OSPS-QA-03.01 | Met | The [ruleset](https://github.com/smcnab1/pokelet/rules/27837727) enforces the `build` check for changes to main. |
| OSPS-QA-06.01 | Met | The required [build job](../.github/workflows/macos.yml) runs automated tests on PRs. |
| OSPS-SA-01.01 | PR | [Architecture](#architecture-and-security-boundaries) maps actors, features and boundaries. |
| OSPS-SA-02.01 | PR | [Architecture](#architecture-and-security-boundaries) describes macOS and browser interfaces and points to implementation. |
| OSPS-SA-03.01 | PR | This [source-based risk review](#architecture-and-security-boundaries) identifies the main software risks and controls, alongside the existing qualified test scope. |
| OSPS-VM-01.01 | PR | [Security policy](../SECURITY.md) adds coordinated disclosure and a 14-day acknowledgement target. |
| OSPS-VM-03.01 | Met | [Private GitHub intake](https://github.com/smcnab1/pokelet/security/advisories/new) is enabled. |
| OSPS-VM-04.01 | PR / verify as triggered | Confirmed findings will be disclosed via [Advisories](https://github.com/smcnab1/pokelet/security/advisories). There were no listed advisories; verify disclosure when there is a finding. |

### Level 3 additions

| Control | Status | Evidence or remaining work |
| --- | --- | --- |
| OSPS-AC-04.02 | Met | App CI is read-only. Specific page deployment, SARIF and OIDC rights are job-scoped. [Workflows](../.github/workflows) |
| OSPS-BR-01.04 | N/A | Manual workflows expose no custom input parameters. Changes to code go through the normal PR path. [Workflows](../.github/workflows) |
| OSPS-BR-02.02 | Met | The DMG and checksum use the same versioned base name on the versioned [release](https://github.com/smcnab1/pokelet/releases/tag/v1.1.0-beta.1). |
| OSPS-BR-07.02 | PR | [Security policy](../SECURITY.md) covers storage, access and rotation. |
| OSPS-DO-03.01 | Partial | [Release verification](VERIFYING_RELEASES.md) covers Beta 1’s checksum and explains signature checks for future signed releases. Beta 1 provides a checksum only. |
| OSPS-DO-03.02 | Gap | The official GitHub account is identified. The ad hoc app contains no independently verifiable publisher identity. |
| OSPS-DO-04.01 | Gap | The beta and supported OS are described. No duration or per-release support scope is committed. |
| OSPS-DO-05.01 | Gap | No published security support lifecycle or end-of-support schedule. |
| OSPS-GV-04.01 | Gap | Only the owner has access. No policy governs vetting before privilege escalation. |
| OSPS-QA-02.02 | Gap | Notices and manifests identify reused work. No SBOM is delivered with the compiled DMG. |
| OSPS-QA-04.02 | N/A | Releases come from one source repository. |
| OSPS-QA-06.02 | Met | [Contributing](../CONTRIBUTING.md) and [CI](../.github/workflows/macos.yml) explain commands and triggers. |
| OSPS-QA-06.03 | Met | [Contributing](../CONTRIBUTING.md) requires test changes for major functionality and explains manual coverage of live paths. |
| OSPS-QA-07.01 | Gap | [Protect main](https://github.com/smcnab1/pokelet/rules/27837727) requires zero author-independent approvals. Requires another reviewer and an authorised rule change. |
| OSPS-SA-03.02 | Partial | [Risk and boundary review](#architecture-and-security-boundaries) identifies principal paths. A fuller threat model and attack-surface analysis for the release was not established. |
| OSPS-VM-04.02 | Verify if triggered | No known dependency vulnerability requiring a non-exploitability determination was identified. There is no VEX process or feed. |
| OSPS-VM-05.01 | Gap | [Dependabot](../.github/dependabot.yml) covers Action updates. No documented SCA thresholds for vulnerability and licence findings. |
| OSPS-VM-05.02 | Gap | No release policy for SCA findings. The app's lack of external Swift packages does not cover Action and vendored dependencies. |
| OSPS-VM-05.03 | Gap | Dependabot monitoring is present; no required pre-merge malicious-dependency and known-vulnerability gate. |
| OSPS-VM-06.01 | PR | [Security policy](../SECURITY.md) sets a release-blocking threshold for confirmed exploitable medium-or-higher analysis findings. |
| OSPS-VM-06.02 | Partial | [SwiftLint](../.swiftlint.yml) blocks selected Swift findings in required CI once merged. Security weakness coverage for the rest of the codebase and a complete gating process remain open. |

Level 1 has one manual verification item. Level 2's reusable changes improve release and response evidence. Full Level 2 still requires authenticated release artifacts and contribution attestation. Level 3 adds release support and evidence obligations that warrant a larger project or a clear user need. Apple Developer ID and notarisation address macOS installation trust; a free signed manifest addresses a distinct artifact authenticity requirement.

## Best Practices Silver and Gold

[Silver](https://www.bestpractices.dev/en/criteria/1) and [Gold](https://www.bestpractices.dev/en/criteria/2) list requirements added or strengthened at each tier. Passing criteria still apply. **PR** means addressed here or through the new assessment evidence, **Verify** means additional real-world evidence or maintainer confirmation, and **Gap** means unmet or deferred.

### Silver

| Criteria | Assessment and evidence |
| --- | --- |
| `achieve_passing` | **Met.** The [public badge record](https://www.bestpractices.dev/projects/16999.json) confirms Passing. |
| `contribution_requirements`, `report_tracker`, `tests_documented_added`, `warnings_strict` | **Met.** [Contributing](../CONTRIBUTING.md), [Issues](https://github.com/smcnab1/pokelet/issues), [PR template](../.github/PULL_REQUEST_TEMPLATE.md) and [CI](../.github/workflows/macos.yml). |
| `dco` | **Gap.** Licence terms for original contributions are documented. No DCO or equivalent authorisation assertion is collected. |
| `governance`, `roles_responsibilities` | **PR.** [Contributing](../CONTRIBUTING.md#review-and-maintenance) records how the single maintainer accepts changes and who is responsible. |
| `code_of_conduct` | **Met.** A [code of conduct](../CODE_OF_CONDUCT.md) is published at the root. |
| `access_continuity`, `bus_factor` | **Gap / verify.** A second maintainer is absent from public records. Only the owner can confirm arrangements to restore issue, merge and release authority within a week. |
| `documentation_roadmap` | **Gap.** [Release plan](RELEASE_CHECKLIST.md) covers the current beta. No maintained one-year roadmap defines scope and exclusions. |
| `documentation_architecture`, `documentation_security` | **PR.** [Architecture and security boundaries](#architecture-and-security-boundaries), [privacy](../PRIVACY.md) and [security policy](../SECURITY.md). |
| `documentation_quick_start`, `documentation_current`, `maintenance_or_update` | **Met.** The [user documentation](README.md) covers installation, launch, pointer modes and removal, and separates the current beta from upcoming features. [Release checklist](RELEASE_CHECKLIST.md) includes documentation updates when published. |
| `documentation_achievements` | **PR / verify.** README badges resolve dynamically. Confirm the 48-hour requirement against any actual future achievement and the front-page publication time. |
| `accessibility_best_practices` | **Partial.** Reduced motion, keyboard and site checks exist, with incomplete native VoiceOver and keyboard traversal. [Verification](../VERIFICATION.md) · [Website](WEBSITE.md) |
| `internationalization` | **Gap.** App and site have user-facing English copy; no localisation workflow was found. Applicable. |
| `sites_password_security` | **N/A.** The static site stores no passwords. GitHub administers its own login credentials. [Privacy](../PRIVACY.md) |
| `vulnerability_report_credit` | **Verify.** [Security policy](../SECURITY.md) provides attribution. N/A only if the maintainer confirms zero resolved reports in the last 12 months. |
| `vulnerability_response_process` | **PR.** [Policy](../SECURITY.md#what-happens-after-you-report) explains acknowledgement, triage and disclosure. |
| `coding_standards` | **PR.** [Contribution guide](../CONTRIBUTING.md#review-and-maintenance) references the Swift API Design Guidelines. |
| `coding_standards_enforced` | **Partial.** [SwiftLint](../.swiftlint.yml) enforces selected correctness and security rules. API naming and overall style still rely on review. |
| `build_standard_variables`, `build_preserve_debug` | **Verify.** The [Xcode project](../Pokelet.xcodeproj/project.pbxproj) selects DWARF and dSYM generation. Propagation of supplied compiler/linker build settings and retained symbol output have not been tested for this assessment. |
| `build_non_recursive` | **Met.** One app target and a single SwiftPM graph; no recursive subdirectory build. [Project](../Pokelet.xcodeproj/project.pbxproj) · [Manifest](../Package.swift) |
| `build_repeatable` | **Gap.** Universal rebuild and layout checks pass, but DMG metadata can change bytes. [Packaging](../packaging/dmg/README.md) |
| `installation_common`, `installation_development_quick` | **Met.** Standard macOS drag-install/removal and a documented Xcode/SwiftPM developer setup. [User guide](README.md) · [Build guide](../CONTRIBUTING.md#build-from-source) |
| `installation_standard_variables` | **N/A.** Drag-copy installs directly at a user-selected destination. There is no scripted end-user installer accepting environment variables. |
| `external_dependencies` | **Partial.** SwiftPM and Actions dependencies are machine-readable. The adapted Quiet Pointer code and Geist font are tracked in prose. [Manifest](../Package.swift) · [Notices](../THIRD_PARTY_NOTICES.md) |
| `dependency_monitoring` | **Partial.** GitHub tracks Actions and returns no Dependabot alerts. Periodic review of the vendored snapshot and tool pins lacks historical evidence. |
| `updateable_reused_components` | **Partial.** Quiet Pointer has a source commit reference and Geist is attributed. A font version and complete update path were not established. [Notices](../THIRD_PARTY_NOTICES.md) |
| `interfaces_current` | **Verify.** Strict warnings help. The project uses Carbon global shortcut APIs and needs an applicability check against the criterion's available FLOSS alternatives. [HotKeys](../Pokelet/Services/HotKeys.swift) |
| `automated_integration_testing` | **Met.** Main pushes run automated tests and publish a success/failure result. [CI](../.github/workflows/macos.yml) |
| `regression_tests_added50` | **Verify.** [PR #5](https://github.com/smcnab1/pokelet/pull/5) and [PR #8](https://github.com/smcnab1/pokelet/pull/8) contain regression evidence. A project-wide inventory linking at least half of bugs fixed during the preceding six-month window to automated tests was not established. |
| `test_statement_coverage80` | **Gap.** The 82.0% line figure covers only the SwiftPM subset; the full app's statement coverage is unmeasured. |
| `test_policy_mandated` | **PR / verify.** The updated [test policy](../CONTRIBUTING.md) requires automated tests for major additions. Live checks that cannot safely be automated need separate manual evidence. |
| `implement_secure_design` | **PR.** Existing local-only operation, least-privilege input handling and recovery paths are mapped to implementation and tests in [Architecture](#architecture-and-security-boundaries). |
| `crypto_weaknesses` | **Met.** The release check uses SHA-256 and the reviewed app/browser paths introduce no weak default crypto algorithm. |
| `crypto_algorithm_agility`, `crypto_credential_agility` | **N/A.** The product has no configurable crypto protocol or credential/key storage. The distribution checksum uses a standard hashing utility. |
| `crypto_used_network`, `crypto_tls12`, `crypto_certificate_verification`, `crypto_verification_private` | **Met / N/A by criterion.** The app has no network client; the site uses HTTPS and platform-browser certificate verification, and the origin/API accepted TLS 1.2. Metadata fetches omit credentials, so there are no project-supplied private headers or authentication cookies to protect on that fetch. [Metadata fetch](site/releases.js) |
| `signed_releases`, `version_tags_signed` | **Gap.** The public beta is widely downloadable. The DMG is ad hoc signed and its checksum and Git tag have no publisher signature. [Release](https://github.com/smcnab1/pokelet/releases/tag/v1.1.0-beta.1) |
| `input_validation` | **Partial.** File size, audio duration and release URLs are validated. Full verification across all untrusted inputs is outstanding. [Architecture](#architecture-and-security-boundaries) |
| `hardening` | **Met.** Hardened Runtime is enabled and the [package check](../script/package_release.sh) rejects the debugger entitlement and Debug acceptance options for both slices. |
| `assurance_case` | **Partial.** The [risk review](#architecture-and-security-boundaries) maps main boundaries and control evidence. A complete assurance case and broader weakness review remain open. |
| `static_analysis_common_vulnerabilities` | **PR.** SwiftLint scans for specified weak hash APIs and manual TLS trust construction. See the Passing justification and limits. |
| `dynamic_analysis_unsafe` | **N/A.** Pokelet ships Swift and browser JavaScript, with no project C/C++ code. Swift's explicit unsafe interfaces and interactions with Apple frameworks still warrant targeted testing. |

### Gold

| Criteria | Assessment and evidence |
| --- | --- |
| `achieve_silver` | **Gap.** Silver is incomplete. |
| `bus_factor`, `contributors_unassociated`, `two_person_review` | **Gap.** Git and GitHub records show one significant human contributor. No evidence establishes a second maintainer or 50% non-author review. |
| `copyright_per_file`, `license_per_file` | **Gap.** Root and third-party notices are present. Per-source notices are not complete. |
| `repo_distributed` | **Met.** Source uses public Git. |
| `small_tasks` | **Gap.** A good-first-issue label exists; no task was verified with that label at review. |
| `require_2FA`, `secure_2FA` | **Verify.** Check required authentication and method for access to code and private reports. The public record provides neither. |
| `code_review_standards` | **PR.** [Contribution guide](../CONTRIBUTING.md#review-and-maintenance) records what to check. This policy supplies no evidence of independent review. |
| `build_reproducible` | **Gap.** No independent bit-for-bit verification of the native release. [DMG packaging](../packaging/dmg/README.md) |
| `test_invocation`, `test_continuous_integration` | **Met.** Standard SwiftPM command and [macOS CI](../.github/workflows/macos.yml). |
| `test_statement_coverage90`, `test_branch_coverage80` | **Gap.** No full-app measurement establishes either threshold. |
| `crypto_used_network`, `crypto_tls12` | **Met for the website.** Browser release lookup uses HTTPS; site and API accepted TLS 1.2. Native app has no network client. [Metadata fetch](site/releases.js) |
| `hardened_site` | **Gap.** Pages returned HSTS but lacked CSP, X-Content-Type-Options and X-Frame-Options during the header check. [Public site](https://smcnab1.github.io/pokelet/) |
| `security_review` | **Verify.** This focused assessment considers key security boundaries. Completion of a dedicated review of security requirements and the entire boundary is unverified. |
| `hardening` | **Met.** Hardened Runtime and universal Release entitlement/acceptance-flag checks. [Project](../Pokelet.xcodeproj/project.pbxproj) · [Packaging checks](../script/package_release.sh) |
| `dynamic_analysis`, `dynamic_analysis_enable_assertions` | **Verify.** Debug XCTest assertions and native smoke tests are documented. Confirm qualifying analysis on each proposed major production release. [Verification](../VERIFICATION.md) |

Silver is currently held up by project continuity, authenticated releases, repeatable output and stronger evidence for test coverage and regression handling. Gold also needs a genuine second contributor and independent reviews. Pursue either tier when those practices serve the project.
