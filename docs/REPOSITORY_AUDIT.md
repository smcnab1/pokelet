# Repository finalisation audit

**23 November 2026.** This record closes the post-release documentation and
repository clean-up reviewed in [draft PR #15](https://github.com/smcnab1/pokelet/pull/15).
The baseline was public `main` at [`6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae`][baseline].
The [complete audit at `e890da8`][full-audit] preserves the original inventory,
individual file decisions and audit evidence.

## Documentation and clean-up decisions

| Material | Home |
| --- | --- |
| Installation, Studio, pointer modes and troubleshooting | [User Wiki][wiki] |
| Release notes, assets and build-specific limitations | [GitHub Releases][releases], linked from the [changelog](../CHANGELOG.md) |
| Source, privacy, security, validation and packaging | [Version-controlled documentation](README.md) |
| Questions and ideas | [Discussions Q&A][qa] and [Ideas][ideas] |
| Actionable defects and scoped requests | [Issue forms](https://github.com/smcnab1/pokelet/issues/new/choose) |
| Conduct concerns and suspected vulnerabilities | [Code of conduct](../CODE_OF_CONDUCT.md) and [security policy](../SECURITY.md), respectively |

The README uses permanent download and documentation links, retains the
approved artwork and listing badges, and describes the universal build target.
The required CI job adds documentation regression tests and offline release
selection alongside the existing link, issue-form, Swift, build and packaging
checks. The existing website listing badges and contrast adjustment remain
part of the PR. Merging its `docs/site` changes would trigger GitHub Pages.

## Historical evidence and retained controls

- The 18 removed paths (16 screenshots and two superseded Markdown files)
  match byte-for-byte in the [baseline tree][baseline] and the published
  [Beta 2 source tree][beta2-tree]. The archive keeps reports and screenshots
  together, with their original relative paths.
- [Acceptance](BETA2_ACCEPTANCE.md), [release readiness](BETA2_RELEASE_READINESS.md),
  [draft release notes](BETA2_RELEASE_NOTES_DRAFT.md) and [Studio](STUDIO.md)
  keep their cited paths and link to immutable originals. The
  [OpenSSF assessment](OPENSSF_ASSESSMENT.md#repository-controls) retains its
  historical claims and anchors. The full audit holds the per-file inventory.
- Both Studio source captures, their website copies, the application artwork
  and audio, and the [installer template and sources](../packaging/dmg/README.md)
  were retained along with the app source, tests, licences and verification key.
- The [Protect main ruleset](https://github.com/smcnab1/pokelet/rules/27837727)
  requires a PR and an up-to-date passing `build` check, blocks deletion and
  force-push, and has no bypass actors. It requires zero independent approvals.
  SwiftLint, CodeQL, Scorecard, Dependabot, secret scanning, push protection and
  private vulnerability reporting were retained.

## OpenSSF evidence review

The [public questionnaire][questionnaire] still recorded **Passing** on the
audit date. This table proposes evidence and wording corrections for owner
review. The public questionnaire and its answers were left as recorded.

| Criterion | Recorded answer | Proposed correction | Evidence | External update |
| --- | --- | --- | --- | --- |
| `version_unique`, `version_tags` | Met. Beta 1 published, Beta 2 planned. | Verified. Both betas are published with distinct versions and Git tags. Use the release history and tags as evidence. | [Releases][releases] · [Tags](https://github.com/smcnab1/pokelet/tags) | Yes, wording |
| `release_notes`, `maintained` | Met. Separate changelog and a draft for Beta 2. | Verified. Point to published notes for both releases. The changelog is an index to Releases after this PR. | [Beta 2][beta2] · [Changelog](../CHANGELOG.md) | Yes, changelog wording after merge |
| `release_notes_vulns` | N/A. Beta 1 had no qualifying publicly known fixes. | N/A for both published betas on the evidence reviewed. Neither release identifies a qualifying public vulnerability fix and the public advisory list is empty. | [Releases][releases] · [Advisories](https://github.com/smcnab1/pokelet/security/advisories) | Yes, extend evidence to Beta 2 |
| `documentation_basics`, `documentation_interface`, `interact` | Met. Relies on README and the in-tree Studio guide. | Verified. Cite the Wiki for install, first launch, removal and Studio controls, Releases for build limits, and Issues and Contributing for feedback and development. | [Installation][install] · [Studio][studio] · [Wiki][wiki] · [Contributing](../CONTRIBUTING.md) | Yes, evidence links |
| `discussion`, `contribution` | Met. Issues and PRs, with guidance to wait for review. | Verified. Document the live Q&A and Ideas categories and the required build check. Describe the maintainer's merge decision and the availability of independent review. | [Q&A][qa] · [Ideas][ideas] · [Workflow](../.github/workflows/macos.yml) · [Contributing](../CONTRIBUTING.md) | Yes, workflow wording after merge |
| `build_floss_tools`, `build_common_tools` | Unmet and Met, respectively. Build evidence points to README. | Keep the answers. Cite the Xcode requirements and build commands directly. Apple’s build tools and SDK are still required. | [Build from source](../CONTRIBUTING.md#build-from-source) | Yes, evidence link |
| `test`, `tests_are_added`, `dynamic_analysis` | Met. Includes historical Beta 2 test counts and “planned” release wording. | Verified publication. Keep test counts tied to the dated qualification. Describe Rosetta and offscreen testing accurately. Distinguish the required CI checks from the separate full browser suite. | [Verification](../VERIFICATION.md) · [Readiness][readiness] · [Acceptance][acceptance] | Yes, clarify scope and release status |
| `delivery_mitm`, `delivery_unsigned` | Met. Explains HTTPS and SHA-256 for the unnotarised beta. | Retain the HTTPS and checksum evidence. Beta 1 is checksum-only. Beta 2’s detached Minisign signature verified against the published key. Apple Developer ID and notarisation are separate. | [Beta 1](https://github.com/smcnab1/pokelet/releases/tag/v1.1.0-beta.1) · [Beta 2][beta2] · [Verification guide](VERIFYING_RELEASES.md) | Yes, clarify both release routes |
| `test_most` | Unmet. The reported coverage is for the SwiftPM subset. | Full-app coverage is unsupported. Keep the dated subset result. | [Verification](../VERIFICATION.md) | No |
| `vulnerability_report_response` | N/A, conditional on no reports during the assessment window. | Unverified. The owner must confirm the private reporting window before renewing N/A. | [Security](../SECURITY.md) | Only if confirmed evidence changes the answer |
| `signed_releases`, `OSPS-BR-06.01`, `OSPS-DO-03.01` | Unanswered. Historical review records a gap or partial evidence. | Partial across releases. Beta 2’s DMG and instructions support integrity and signature verification. Beta 1 lacks a publisher signature and Beta 2 has no signed manifest covering every asset. Review the requirements before claiming broader compliance. | [Beta 2][beta2] · [Verification guide](VERIFYING_RELEASES.md) · [Baseline](https://baseline.openssf.org/versions/2026-08-28#osps-br-0601) | No upgrade proposed |
| `version_tags_signed`, `two_person_review`, `access_continuity` | Unanswered. | Tags are unsigned. Independent review and continuity evidence remain unverified. Leave higher-tier claims pending. | [Tags](https://github.com/smcnab1/pokelet/tags) · [Historical assessment](OPENSSF_ASSESSMENT.md#best-practices-silver-and-gold) | No upgrade proposed |

## Remaining actions and limits

- A separate Wiki patch for Home, Help and Feedback, FAQ and the footer
  awaits approval. It links the live categories and updates stale availability
  wording. The sidebar, installation and troubleshooting guides were reviewed.
- A dedicated project-controlled private conduct channel remains a future
  improvement. The code of conduct documents GitHub's available reporting routes.
- Native Intel, macOS 14 runtime and broader hands-on accessibility coverage
  remain open. Published beta builds are ad hoc signed and unnotarised.
- External questionnaire edits, Wiki publication, PR merge and Pages deployment
  each require owner approval. Final validation results belong in [PR #15](https://github.com/smcnab1/pokelet/pull/15).

[baseline]: https://github.com/smcnab1/pokelet/tree/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae
[full-audit]: https://github.com/smcnab1/pokelet/blob/e890da87dc0a85ab90000e9cb08e1098db2c8dcd/docs/REPOSITORY_AUDIT.md
[beta2-tree]: https://github.com/smcnab1/pokelet/tree/47c28d2a02e6f5d52209a4a5527f455a349cd9e6
[beta2]: https://github.com/smcnab1/pokelet/releases/tag/v1.2.0-beta.1
[releases]: https://github.com/smcnab1/pokelet/releases
[wiki]: https://github.com/smcnab1/pokelet/wiki
[install]: https://github.com/smcnab1/pokelet/wiki/Installation
[studio]: https://github.com/smcnab1/pokelet/wiki/Pokelet-Studio
[qa]: https://github.com/smcnab1/pokelet/discussions/categories/q-a
[ideas]: https://github.com/smcnab1/pokelet/discussions/categories/ideas
[questionnaire]: https://www.bestpractices.dev/projects/16999.json
[readiness]: https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/BETA2_RELEASE_READINESS.md
[acceptance]: https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/BETA2_ACCEPTANCE.md
