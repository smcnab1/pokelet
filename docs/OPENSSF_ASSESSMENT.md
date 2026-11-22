# OpenSSF assessment and registration evidence

**22 November 2026 · Evidence draft · No certification claimed**

This document records verifiable repository evidence and unanswered questions before registering Pokelet with [OpenSSF Best Practices](https://www.bestpractices.dev/) or displaying an [OpenSSF Scorecard](https://scorecard.dev/) badge. These are separate programmes. A Scorecard result does not imply Best Practices Passing, and Best Practices Passing does not imply compliance with the Open Source Project Security Baseline.

## 1. OpenSSF Scorecard

The proposed workflow is [`scorecard.yml`](../.github/workflows/scorecard.yml). It uses the official Scorecard Action pinned to a full commit SHA and runs on main pushes and a weekly schedule. The workflow limits write permissions to Code Scanning SARIF upload and OIDC issuance, publishes authenticated results, and uses no personal access token.

**Status:** Proposed on a PR only. No successful Scorecard publication, numerical score, badge response or GitHub code scanning findings have yet been independently verified.

After approval and merge, review [Actions](https://github.com/smcnab1/pokelet/actions/workflows/scorecard.yml), [Code scanning](https://github.com/smcnab1/pokelet/security/code-scanning), the [Scorecard viewer](https://scorecard.dev/viewer/?uri=github.com/smcnab1/pokelet), and [badge response](https://api.scorecard.dev/projects/github.com/smcnab1/pokelet/badge). Add the official badge to the README **only after** the results and the badge resolve to this repository. Record actual findings and decide mitigations based on risk, not solely the numerical score.

## 2. OpenSSF Best Practices registration

[Register a project](https://www.bestpractices.dev/en/projects/new) by signing in with GitHub. Registration and self-assessment are free. Only the repository owner can authorise GitHub authentication and submit the initial application.

Suggested registration fields, subject to owner confirmation:

| Field | Proposed value |
| --- | --- |
| Project name | Pokelet |
| Description | Free, open-source animated cursor companion for macOS |
| Project website | https://smcnab1.github.io/pokelet/ |
| Source repository | https://github.com/smcnab1/pokelet |
| Licence | MIT |
| Current distribution | GitHub Releases, currently `v1.1.0-beta.1` |
| Project-specific badge or ID | **Not registered or verified** |

Do not reuse project 13303 (Thaw) or any other project's badge. After registration, link to Pokelet's own assessment, and display a badge only with its actual recorded state and project ID.

## 3. Best Practices Passing: evidence to enter

The [official Passing criteria](https://www.bestpractices.dev/en/criteria/0) are broader than simply having tests and CI. Each answer below is a **draft for review**, not a submitted claim.

| Area / criteria examples | Existing evidence | Cautious answer |
| --- | --- | --- |
| Project description, obtaining software, feedback | [Website](https://smcnab1.github.io/pokelet/), [README](../README.md), [issue forms](../.github/ISSUE_TEMPLATE) | Supported; public download remains Beta 1 |
| Contribution instructions, acceptable changes | [CONTRIBUTING.md](../CONTRIBUTING.md), [PR template](../.github/PULL_REQUEST_TEMPLATE.md) | Supported after this PR merges |
| FLOSS licence and licence location | [MIT licence](../LICENSE), [third-party notices](../THIRD_PARTY_NOTICES.md) | Supported for source; independently verify asset distribution |
| Documentation of features and interface | [README](../README.md), [Studio guide](STUDIO.md), [privacy](../PRIVACY.md) | Broadly documented; cross-check after Beta 2 publication |
| Public version history, unique releases, tags, notes | [Changelog](../CHANGELOG.md), [releases](https://github.com/smcnab1/pokelet/releases), [commits](https://github.com/smcnab1/pokelet/commits/main) | Supported for the existing release |
| Discussion, issue reporting and public archive | [GitHub issues](https://github.com/smcnab1/pokelet/issues) and PRs | Mechanisms supported; response-rate criteria require checking actual history |
| Private vulnerability reports and contact | [SECURITY.md](../SECURITY.md) | Published policy; confirm private reporting is enabled and assess actual responses |
| Repeatable build and automated tests | [macOS CI](../.github/workflows/macos.yml), [Package.swift](../Package.swift), [tests](../Tests), [release checklist](RELEASE_CHECKLIST.md) | Evidence supports build/test criteria; some live behaviour remains manual |
| Adding tests for changes | [Contributing test policy](../CONTRIBUTING.md), [Beta 2 acceptance](BETA2_ACCEPTANCE.md) | Policy documented in this PR; confirm concrete tests for significant changes |
| Warnings and static analysis | [macOS CI](../.github/workflows/macos.yml) uses Swift warnings as errors and Xcode analysis | Warnings supported; evaluate independent FLOSS static-analysis criterion separately |
| Secure development knowledge | No independently verified personal training or competence evidence in this repository | **Owner self-assessment required**; do not assume |
| Private credentials and vulnerability backlog | No complete secret scan or verified vulnerability inventory was available for this assessment | **Unverified**; inspect security settings and triage open findings |
| Basic cryptography criteria | Pokelet uses HTTPS for hosted distribution and SHA-256 for checksums; no custom crypto implementation established by this review | Assess applicability criterion by criterion; do not blanket-mark N/A |
| FLOSS-only build tools (SHOULD) | Xcode and Apple frameworks required for native macOS builds | Does not meet a FLOSS-only toolchain objective; explain platform constraint where permitted |

Other Passing requirements include vulnerability acknowledgement times, timely fixes, secure delivery, warning remediation and static-analysis findings. The maintainer must inspect those answers rather than infer compliance from the presence of policies.

**Passing is not achieved until the programme records it.** Silver adds governance, contribution provenance and further controls; it is a long-term target, not a release blocker.

## 4. OSPS Baseline Level 1 (v2026.08.28)

[Current official criteria](https://baseline.openssf.org/versions/2026-08-28.html). A baseline self-assessment is distinct from the Best Practices Passing badge.

| Level 1 control(s) | Current evidence / gap | Next action |
| --- | --- | --- |
| OSPS-AC-01.01, multi-factor access | Authentication settings are not readable from the repo | Owner confirms GitHub MFA |
| OSPS-AC-02.01, least-privilege collaborator assignment | GitHub repository permissions exist; onboarding defaults not verified | Owner confirms access policy |
| OSPS-AC-03.01 and 03.02, prevent direct main commits and confirm deletion | As at 22 November, `main` was unprotected and no ruleset appeared in the repository API | Create a suitable main ruleset requiring PR and passing checks, after owner approval |
| OSPS-BR-01.01 and 01.03, untrusted CI inputs and credentials | [CI workflow](../.github/workflows/macos.yml) uses read-only PR token and SHA-pinned actions | Review any future user-controlled steps before granting write |
| OSPS-BR-03.01 and 03.02, secure official links and delivery | Website and GitHub downloads use HTTPS; DMG is ad hoc signed | Do not imply publisher authentication; continue checksum and Gatekeeper disclosures |
| OSPS-BR-07.01, prevent secret storage | No complete secret scanning or push-protection setting established | Owner checks GitHub settings and alerts |
| OSPS-DO-01.01, DO-02.01, GV-02.01, GV-03.01 | [README](../README.md), [issues](https://github.com/smcnab1/pokelet/issues), [contributing](../CONTRIBUTING.md) | Cross-check coverage for Beta 2 |
| OSPS-LE-02 and LE-03, source and asset licensing | [MIT](../LICENSE), [third-party notices](../THIRD_PARTY_NOTICES.md), packaged licence checks described in [release readiness](BETA2_RELEASE_READINESS.md) | Verify final DMG contains matching notices |
| OSPS-QA-01, QA-02, QA-04, public change history and dependencies | Public Git repository and [Swift package manifest](../Package.swift); one source repository known | Confirm dependency inventory stays current |
| OSPS-QA-05, no generated executables or unreviewable binaries in version control | [`.gitignore`](../.gitignore) excludes generated outputs; source includes artwork and screenshots | Inspect committed files for unreviewable executable payloads |
| OSPS-VM-02.01, security contact | [Security policy](../SECURITY.md) | Confirm private reporting mechanism works |

This is a prioritised mapping, **not** evidence of full Level 1 compliance. Most actionable gap: enforce PR-based changes to `main`, with a carefully scoped ruleset which retains a maintainer emergency recovery path.

## 5. Repository security work to assess

1. **After owner approval:** protect `main` with required pull requests, a stable macOS CI status check and protection against accidental deletion; verify the actual ruleset enforcement. Do not make a ruleset that locks the sole maintainer out.
2. **After owner approval:** check private vulnerability reporting, secret scanning/push protection, dependency graph and Dependabot alerts. Existing CI has previously shown GitGuardian but this does not prove secret scanning or push protection is enabled.
3. **After checking settings:** consider GitHub CodeQL **Swift** scanning using macOS. CodeQL is available for public repositories; Swift analysis requires a macOS runner and a build. Avoid duplicate workflows and assess runtime cost.
4. The repository currently has no external Swift package dependencies in [`Package.swift`](../Package.swift). The proposed [Dependabot settings](../.github/dependabot.yml) track updates to SHA-pinned GitHub Actions instead.
5. Consider a provenance attestation only when the **actual downloadable DMG** can be built and attested from the recorded release source. An attestation for a different CI ZIP must not be presented as verification of a locally built DMG. An SBOM is low-priority without external third-party package dependencies.

## 6. Evidence to complete before awarding status

- Record the actual Scorecard run, API status, numerical findings and remedial decisions.
- Confirm the owner-controlled account and repository security settings, and verify the main ruleset.
- Register Pokelet as its **own** Best Practices project following owner approval, then save its project ID and each justified questionnaire answer.
- Resolve or explicitly justify all outstanding MUST, SHOULD and SUGGESTED criteria under the programme's actual rules.
- Review reports and response history, static analysis, packaging attribution and distribution controls.
- Verify final Beta 2 source SHA, DMG hash, public release links and published documentation after owner-approved release.

No security certification is claimed by this document.
