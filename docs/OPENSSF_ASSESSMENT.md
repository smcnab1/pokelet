# OpenSSF assessment and registration evidence

**22 November 2026 · Evidence update · Certification level not independently verified**

This document records repository evidence and unanswered questions after the maintainer supplied [OpenSSF Best Practices project 16999](https://www.bestpractices.dev/projects/16999) and the [OpenSSF Scorecard workflow](https://github.com/smcnab1/pokelet/actions/workflows/scorecard.yml) first passed. These are separate programmes. A Scorecard result does not imply Best Practices Passing, and Best Practices Passing does not imply compliance with the Open Source Project Security Baseline.

## 1. OpenSSF Scorecard

The merged workflow is [`scorecard.yml`](../.github/workflows/scorecard.yml). It uses the official Scorecard Action pinned to a full commit SHA and runs on main pushes and a weekly schedule. The workflow limits write permissions to Code Scanning SARIF upload and OIDC issuance, publishes authenticated results, and uses no personal access token.

**Status:** The first [Scorecard run](https://github.com/smcnab1/pokelet/actions/runs/45014059679) passed on 22 November 2026, with a reported score of **5.6/10**. SARIF upload to GitHub code scanning completed successfully. Direct HTTP validation of the public Scorecard API badge remains outstanding. This first result predates the branch-protection ruleset and the maintainer's new Best Practices registration, so scores may change on the next run.

Review [Actions](https://github.com/smcnab1/pokelet/actions/workflows/scorecard.yml), [Code scanning](https://github.com/smcnab1/pokelet/security/code-scanning), the [Scorecard viewer](https://scorecard.dev/viewer/?uri=github.com/smcnab1/pokelet), and [badge response](https://api.scorecard.dev/projects/github.com/smcnab1/pokelet/badge). Verify both public badge endpoints render for Pokelet before merging the badge PR. Treat scores as diagnostics rather than a security guarantee.

## 2. OpenSSF Best Practices registration

**Maintainer-supplied project ID: [16999](https://www.bestpractices.dev/projects/16999)**. The maintainer reports completing the project questionnaire. This review could not directly retrieve the live Best Practices status or verify all submitted answers. The `/passing` path names the questionnaire; it does not independently prove that a Passing badge has been awarded.

Project record supplied by maintainer, subject to checking against the live page:

| Field | Proposed value |
| --- | --- |
| Project name | Pokelet |
| Description | Free, open-source animated cursor companion for macOS |
| Project website | https://smcnab1.github.io/pokelet/ |
| Source repository | https://github.com/smcnab1/pokelet |
| Licence | MIT |
| Current distribution | GitHub Releases, currently `v1.1.0-beta.1` |
| Project-specific badge or ID | [16999](https://www.bestpractices.dev/projects/16999) (owner supplied; live status not independently verified) |

Do not reuse project 13303 (Thaw) or another project's badge. The proposed [dynamic badge](https://www.bestpractices.dev/projects/16999/badge) will display the programme's actual status rather than a hardcoded Passing claim. Confirm it resolves to Pokelet before merging the badge PR.

## 3. Best Practices Passing: evidence to enter

The [official Passing criteria](https://www.bestpractices.dev/en/criteria/0) are broader than simply having tests and CI. Each answer below is a **draft for review**, not a submitted claim.

| Area / criteria examples | Existing evidence | Cautious answer |
| --- | --- | --- |
| Project description, obtaining software, feedback | [Website](https://smcnab1.github.io/pokelet/), [README](../README.md), [issue forms](../.github/ISSUE_TEMPLATE) | Supported; public download remains Beta 1 |
| Contribution instructions, acceptable changes | [CONTRIBUTING.md](../CONTRIBUTING.md), [PR template](../.github/PULL_REQUEST_TEMPLATE.md) | Published on main |
| FLOSS licence and licence location | [MIT licence](../LICENSE), [third-party notices](../THIRD_PARTY_NOTICES.md) | Supported for source; independently verify asset distribution |
| Documentation of features and interface | [README](../README.md), [Studio guide](STUDIO.md), [privacy](../PRIVACY.md) | Broadly documented; cross-check after Beta 2 publication |
| Public version history, unique releases, tags, notes | [Changelog](../CHANGELOG.md), [releases](https://github.com/smcnab1/pokelet/releases), [commits](https://github.com/smcnab1/pokelet/commits/main) | Supported for the existing release |
| Discussion, issue reporting and public archive | [GitHub issues](https://github.com/smcnab1/pokelet/issues) and PRs | Mechanisms supported; response-rate criteria require checking actual history |
| Private vulnerability reports and contact | [SECURITY.md](../SECURITY.md) | Published policy; confirm private reporting is enabled and assess actual responses |
| Repeatable build and automated tests | [macOS CI](../.github/workflows/macos.yml), [Package.swift](../Package.swift), [tests](../Tests), [release checklist](RELEASE_CHECKLIST.md) | Evidence supports build/test criteria; some live behaviour remains manual |
| Adding tests for changes | [Contributing test policy](../CONTRIBUTING.md), [Beta 2 acceptance](BETA2_ACCEPTANCE.md) | Policy now published; confirm concrete tests for significant changes |
| Warnings and static analysis | [macOS CI](../.github/workflows/macos.yml) uses Swift warnings as errors and Xcode analysis | Warnings supported; evaluate independent FLOSS static-analysis criterion separately |
| Secure development knowledge | No independently verified personal training or competence evidence in this repository | **Owner self-assessment required**; do not assume |
| Private credentials and vulnerability backlog | No complete secret scan or verified vulnerability inventory was available for this assessment | **Unverified**; inspect security settings and triage open findings |
| Basic cryptography criteria | Pokelet uses HTTPS for hosted distribution and SHA-256 for checksums; no custom crypto implementation established by this review | Assess applicability criterion by criterion; do not blanket-mark N/A |
| FLOSS-only build tools (SHOULD) | Xcode and Apple frameworks required for native macOS builds | Does not meet a FLOSS-only toolchain objective; explain platform constraint where permitted |

Other Passing requirements include vulnerability acknowledgement times, timely fixes, secure delivery, warning remediation and static-analysis findings. The maintainer must inspect those answers rather than infer compliance from the presence of policies.

**Do not claim Passing unless the programme records it for project 16999.** Silver adds governance, contribution provenance and further controls; it is a long-term target, not a release blocker.

## 4. OSPS Baseline Level 1 (v2026.08.28)

[Current official criteria](https://baseline.openssf.org/versions/2026-08-28.html). A baseline self-assessment is distinct from the Best Practices Passing badge.

| Level 1 control(s) | Current evidence / gap | Next action |
| --- | --- | --- |
| OSPS-AC-01.01, multi-factor access | Authentication settings are not readable from the repo | Owner confirms GitHub MFA |
| OSPS-AC-02.01, least-privilege collaborator assignment | GitHub repository permissions exist; onboarding defaults not verified | Owner confirms access policy |
| OSPS-AC-03.01 and 03.02, prevent direct main commits and confirm deletion | [Ruleset Protect main](https://github.com/smcnab1/pokelet/rules/27837727) is active and requires PRs, the `build` check, and blocks deletion and non-fast-forward pushes | Verify effective enforcement in future PRs; controls now configured |
| OSPS-BR-01.01 and 01.03, untrusted CI inputs and credentials | [CI workflow](../.github/workflows/macos.yml) uses read-only PR token and SHA-pinned actions | Review any future user-controlled steps before granting write |
| OSPS-BR-03.01 and 03.02, secure official links and delivery | Website and GitHub downloads use HTTPS; DMG is ad hoc signed | Do not imply publisher authentication; continue checksum and Gatekeeper disclosures |
| OSPS-BR-07.01, prevent secret storage | No complete secret scanning or push-protection setting established | Owner checks GitHub settings and alerts |
| OSPS-DO-01.01, DO-02.01, GV-02.01, GV-03.01 | [README](../README.md), [issues](https://github.com/smcnab1/pokelet/issues), [contributing](../CONTRIBUTING.md) | Cross-check coverage for Beta 2 |
| OSPS-LE-02 and LE-03, source and asset licensing | [MIT](../LICENSE), [third-party notices](../THIRD_PARTY_NOTICES.md), packaged licence checks described in [release readiness](BETA2_RELEASE_READINESS.md) | Verify final DMG contains matching notices |
| OSPS-QA-01, QA-02, QA-04, public change history and dependencies | Public Git repository and [Swift package manifest](../Package.swift); one source repository known | Confirm dependency inventory stays current |
| OSPS-QA-05, no generated executables or unreviewable binaries in version control | [`.gitignore`](../.gitignore) excludes generated outputs; source includes artwork and screenshots | Inspect committed files for unreviewable executable payloads |
| OSPS-VM-02.01, security contact | [Security policy](../SECURITY.md) | Confirm private reporting mechanism works |

This is a prioritised mapping, **not** evidence of full Level 1 compliance. Main branch protection is now configured, but MFA, account permissions, private reporting and release provenance still need evaluation.

## 5. Repository security work to assess

1. **Configured:** [Protect main](https://github.com/smcnab1/pokelet/rules/27837727) requires pull requests, passing `build` checks, and disallows deletion and force-pushes. Continue monitoring rule enforcement.
2. **After owner approval:** check private vulnerability reporting, secret scanning/push protection, dependency graph and Dependabot alerts. Existing CI has previously shown GitGuardian but this does not prove secret scanning or push protection is enabled.
3. **After checking settings:** consider GitHub CodeQL **Swift** scanning using macOS. CodeQL is available for public repositories; Swift analysis requires a macOS runner and a build. Avoid duplicate workflows and assess runtime cost.
4. The repository currently has no external Swift package dependencies in [`Package.swift`](../Package.swift). Merged [Dependabot settings](../.github/dependabot.yml) track updates to SHA-pinned GitHub Actions instead.
5. Consider a provenance attestation only when the **actual downloadable DMG** can be built and attested from the recorded release source. An attestation for a different CI ZIP must not be presented as verification of a locally built DMG. An SBOM is low-priority without external third-party package dependencies.

## 6. Evidence to complete before awarding status

- Record the latest Scorecard API response, verify both badge images resolve, and triage findings after the first successful 5.6/10 run.
- Verify owner-controlled account and repository security settings; main branch ruleset is active.
- Independently verify project 16999's repository link, recorded badge status and each questionnaire answer; the owner has supplied the project ID.
- Resolve or explicitly justify all outstanding MUST, SHOULD and SUGGESTED criteria under the programme's actual rules.
- Review reports and response history, static analysis, packaging attribution and distribution controls.
- Verify final Beta 2 source SHA, DMG hash, public release links and published documentation after owner-approved release.

No security certification is claimed by this document.
