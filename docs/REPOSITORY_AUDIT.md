# Repository finalisation audit

Snapshot: **23 November 2026**. This is an audit record, not a release-status page or a checklist to update every release.

| Baseline | Identity |
| --- | --- |
| Public main and immutable archive | [`6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae`](https://github.com/smcnab1/pokelet/commit/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae) |
| Starting work branch | `chore/cleanup-docs` at `0ee729060b0c522b8615dc7b2939b67bc4fe2019`; initially clean |
| Scope | 178 tracked files; 22 Markdown files; 18 documentation screenshots; three workflows |
| Wiki inspected | `b1272567e52c2a7f1c28889248f9c4e64223dda5`; 15 content pages, sidebar and footer |

The request names both “only work on chore/cleanup-docs” and a new finalisation branch. Work follows the explicit existing-branch restriction. The starting commit already changes README badges and the website’s listing badges/CSS compared with main. Preserve those changes; they are not app or packaging changes introduced by this audit. Any merge affecting `docs/site` triggers Pages and needs approval.

## Findings and decisions

| Finding | Resolution |
| --- | --- |
| README, docs index and verification instructions name one beta and installer. Privacy calls published features unpublished. | Use permanent Wiki/Releases links and a version badge that includes prereleases sorted by date. State build-independent behaviour. |
| User guides and release notes are duplicated. | Wiki is primary user documentation. Releases is the release history. Retain technical procedures in Git. |
| Public OpenSSF questionnaire cites historical paths on main. | Preserve those paths as evidence pointers and retain the full assessment, including its anchors. No external assessment is silently rewritten. |
| Historical diaries and captures clutter current documentation. | Remove only after comparing each file’s Git blob and current bytes with the public immutable archive above. The original relative links still resolve within that commit. |
| Link checker omits nested Markdown, Markdown anchors and `srcset`. | Check all tracked Markdown/HTML, fences, whitespace, local targets, heading anchors, HTML IDs and image source sets; add regression fixtures. External availability remains a separate live audit. |
| Existing website listing label fails light-mode contrast (2.35:1). | Reuse the existing adaptive muted-text colour; keep layout, artwork and interaction unchanged. Remove trailing whitespace in the inherited badge markup. |
| Existing release-selection tests are offline Node tests. | Add their existing command to the required macOS job, with no npm install, browser download or credentials. Keep all prior CI gates. |

## Markdown inventory and disposition

Every Markdown file tracked at the baseline is listed below. Original links use the full commit SHA, including for files retained or rewritten. Newly added documentation is this audit; the new checker regression suite is `Tests/Documentation/test_check_docs.py`.

| Original file | Disposition and rationale |
| --- | --- |
| [.github/PULL_REQUEST_TEMPLATE.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/.github/PULL_REQUEST_TEMPLATE.md) | Retain: concise outcome, tests, screenshots and compatibility prompts. |
| [CHANGELOG.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/CHANGELOG.md) | Replace with one-line Releases pointer; preserve URL cited by OpenSSF. |
| [CODE_OF_CONDUCT.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/CODE_OF_CONDUCT.md) | Retain: community conduct and reporting expectations. |
| [CONTRIBUTING.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/CONTRIBUTING.md) | Edit: Discussions/Issues/private-report routing; build and validation commands; documentation ownership. |
| [PRIVACY.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/PRIVACY.md) | Edit: remove unpublished-release statements; describe actual permissions and external website badges. |
| [README.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/README.md) | Edit: evergreen landing page, Wiki, Releases, community, security and contribution links; automatic stable/prerelease badge. |
| [SECURITY.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/SECURITY.md) | Edit: per-release trust instructions and current-source security-fix scope, without a fixed-version support table. |
| [THIRD_PARTY_NOTICES.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/THIRD_PARTY_NOTICES.md) | Retain: licence, provenance and redistribution evidence. |
| [VERIFICATION.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/VERIFICATION.md) | Condense: current check coverage and limits; immutable historical outcomes and measurement method. |
| [docs/BETA2_ACCEPTANCE.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/BETA2_ACCEPTANCE.md) | Keep evidence pointer: OpenSSF cites this path. Original report and all captures preserved. |
| [docs/BETA2_RELEASE_NOTES_DRAFT.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/BETA2_RELEASE_NOTES_DRAFT.md) | Keep evidence pointer: OpenSSF cites this path. Published release notes supersede the draft. |
| [docs/BETA2_RELEASE_READINESS.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/BETA2_RELEASE_READINESS.md) | Keep evidence pointer: OpenSSF cites this path. Historical pre-publication gates are not current blockers. |
| [docs/COMPETITOR_COMPARISON.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/COMPETITOR_COMPARISON.md) | Remove from branch: dated external pricing/product claims are unnecessary maintenance. Preserve original. |
| [docs/INTERACTIVE_ACCEPTANCE.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/INTERACTIVE_ACCEPTANCE.md) | Retain procedure; replace beta-specific wording with public Release behaviour. |
| [docs/LIVE_ACCEPTANCE.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/LIVE_ACCEPTANCE.md) | Remove from branch: detailed historical trial diary. Link the immutable original from verification. |
| [docs/OPENSSF_ASSESSMENT.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/OPENSSF_ASSESSMENT.md) | Retain all evidence, matrices and anchors; add an explicit historical-snapshot notice. |
| [docs/README.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/README.md) | Replace duplicate user guide with Wiki navigation and version-controlled technical references. |
| [docs/RELEASE_CHECKLIST.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/RELEASE_CHECKLIST.md) | Rewrite as reusable candidate, qualification, trust, approval and publication process. |
| [docs/STUDIO.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/STUDIO.md) | Keep Wiki/evidence pointer: OpenSSF cites the original interface documentation. |
| [docs/VERIFYING_RELEASES.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/VERIFYING_RELEASES.md) | Edit: exact-filename variable, checksum/signature trust distinction, per-release disclosures and Wiki installation link. |
| [docs/WEBSITE.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/WEBSITE.md) | Retain artwork, browser and maintenance instructions; explain offline unit tests in CI. |
| [packaging/dmg/README.md](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/packaging/dmg/README.md) | Retain: installer-template provenance and regeneration/build inputs. |

## Tracked directory inventory

All directories containing tracked files at the baseline, including asset-catalog subdirectories:

```text
.codex
.codex/environments
.github
.github/ISSUE_TEMPLATE
.github/workflows
Pokelet
Pokelet.xcodeproj
Pokelet.xcodeproj/xcshareddata
Pokelet.xcodeproj/xcshareddata/xcschemes
Pokelet/App
Pokelet/Assets.xcassets
Pokelet/Assets.xcassets/AccentColor.colorset
Pokelet/Assets.xcassets/AppIcon.appiconset
Pokelet/Cursor
Pokelet/Models
Pokelet/Resources
Pokelet/Services
Pokelet/Views
Tests
Tests/Browser
Tests/Interactive
Tests/Native
Tests/PokeletCoreTests
docs
docs/screenshots
docs/screenshots/beta2
docs/site
docs/site/assets
docs/site/assets/characters
packaging
packaging/dmg
script
security
```

App source, resource and Xcode directories, `Package.swift`, `security`, `packaging` and the complete `docs/site` tree are required inputs and are retained. `.codex/environments/environment.toml` is existing local development setup, not release output. Generated `.build`, `build`, `dist`, derived data and credentials remain ignored. Add only Python bytecode cache ignores for the new checker tests.

## Screenshots and website assets

All 18 original documentation captures are listed individually. Two are the documented source captures for website WebP derivatives and remain in the branch. The other 16 have identical blobs and bytes in the public archive and leave the current tree. No website or application artwork is removed.

| Original capture | Disposition |
| --- | --- |
| [beta2/companion-after.png](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/screenshots/beta2/companion-after.png) | Archive only: historical evidence or unused capture. |
| [beta2/companion-before.png](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/screenshots/beta2/companion-before.png) | Archive only: historical evidence or unused capture. |
| [beta2/presenter-arm-edge.png](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/screenshots/beta2/presenter-arm-edge.png) | Archive only: historical evidence or unused capture. |
| [beta2/presenter-arm-live.png](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/screenshots/beta2/presenter-arm-live.png) | Archive only: historical evidence or unused capture. |
| [beta2/presenter-primary-live.png](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/screenshots/beta2/presenter-primary-live.png) | Archive only: historical evidence or unused capture. |
| [beta2/presenter-secondary-live.png](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/screenshots/beta2/presenter-secondary-live.png) | Archive only: historical evidence or unused capture. |
| [beta2/replace-after.png](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/screenshots/beta2/replace-after.png) | Archive only: historical evidence or unused capture. |
| [beta2/replace-before.png](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/screenshots/beta2/replace-before.png) | Archive only: historical evidence or unused capture. |
| [pokelet-presenter-arm-live-centre.png](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/screenshots/pokelet-presenter-arm-live-centre.png) | Archive only: historical evidence or unused capture. |
| [pokelet-presenter-arm-live-lower-right.png](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/screenshots/pokelet-presenter-arm-live-lower-right.png) | Archive only: historical evidence or unused capture. |
| [pokelet-settings-animations-dark.png](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/screenshots/pokelet-settings-animations-dark.png) | Archive only: historical evidence or unused capture. |
| [pokelet-settings-pointer-dark.png](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/screenshots/pokelet-settings-pointer-dark.png) | Archive only: historical evidence or unused capture. |
| [pokelet-studio-about-compact-dark.png](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/screenshots/pokelet-studio-about-compact-dark.png) | Archive only: historical evidence or unused capture. |
| [pokelet-studio-about-dark.png](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/screenshots/pokelet-studio-about-dark.png) | Archive only: historical evidence or unused capture. |
| [pokelet-studio-feedback-compact-light.png](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/screenshots/pokelet-studio-feedback-compact-light.png) | Archive only: historical evidence or unused capture. |
| [pokelet-studio-presenter-compact-light.png](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/screenshots/pokelet-studio-presenter-compact-light.png) | Retain: website image source. |
| [pokelet-studio-presenter-preview-dark.png](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/screenshots/pokelet-studio-presenter-preview-dark.png) | Retain: website image source. |
| [pokelet-studio-quiet-pointer-compact-light.png](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/screenshots/pokelet-studio-quiet-pointer-compact-light.png) | Archive only: historical evidence or unused capture. |

The entire website asset inventory is retained: the 24 character WebP/cursor PNG files, Geist font and OFL, demonstration GIF, icon, colour-gallery artwork, social image, two Studio WebPs and Soft Tap WAV. App icon sizes and four bundled WAVs remain unchanged. The tracked `packaging/dmg/InstallerTemplate.dmg` is a required packaging input, not a disposable released binary.

## Community and automation inventory

| File/control | Review and action |
| --- | --- |
| `.github/ISSUE_TEMPLATE/bug.yml` | Retain filename and all IDs: `behaviour`, `steps`, `expected`, `environment`, `setup`. Required fields and private-security warning unchanged. |
| `.github/ISSUE_TEMPLATE/feature.yml` | Retain filename and all IDs: `proposal`, `use-case`, `examples`. Existing in-app prefill URLs unchanged. |
| `.github/ISSUE_TEMPLATE/config.yml` | Keep blank issues disabled and security link; add Discussions contact link. |
| `.github/PULL_REQUEST_TEMPLATE.md` | Retain existing focused review prompts. |
| `.github/workflows/macos.yml` | Read-only PR permissions, no persisted checkout credentials, timeout, concurrency, strict Swift checks, analysis and package checks retained. Add checker regression tests and offline release-selection tests to `build`. |
| `.github/workflows/pages.yml` | Retain main-only deployment and job-scoped Pages/OIDC rights. No deployment initiated. |
| `.github/workflows/scorecard.yml` | Retain default-branch/scheduled publishing, required publisher-compatible permissions, job-scoped SARIF/OIDC rights and short artifact retention. |
| `.github/dependabot.yml` | Retain grouped weekly SHA-pinned Actions updates. App has no external Swift package dependencies. |
| `.swiftlint.yml` / `script/lint_swift.sh` | Retain targeted correctness/security rules and SHA-256-verified tool download. No claim of comprehensive vulnerability coverage. |
| `.gitignore` | Preserve packaging-template exception and existing credential/build ignores. Add Python bytecode-cache ignore. |
| Main ruleset 27837727 | Active: PR required, strict GitHub Actions `build` required, deletion and force-push blocked, no bypass actors. Classic protection endpoint returns 404 because protection is via a ruleset. Zero independent approvals is a remaining solo-maintainer limit; no configuration change made. |
| Repository metadata | Description, website URL and ten search topics already set. Wiki and Discussions enabled; secret scanning, push protection and Dependabot security updates enabled. Retain. |

All existing `uses:` references are full commit pins. Dependabot already maintains them; no speculative Action or tool upgrades are needed. The macOS runner provides Node; the CI command records its version and uses no third-party JavaScript dependencies. Full Playwright testing is kept local to avoid a browser/tooling installation in the release build job.

## Build, packaging and test script inventory

| Script | Purpose and disposition |
| --- | --- |
| [packaging/dmg/make-template.sh](../packaging/dmg/make-template.sh) | Finder/template generation; retain alongside Background.swift and FinderLayout.applescript. |
| [script/build_and_run.sh](../script/build_and_run.sh) | Build/local-run helper; retain. |
| [script/check_docs.py](../script/check_docs.py) | Expand Markdown and local-link validation. |
| [script/check_issue_forms.rb](../script/check_issue_forms.rb) | Retain published feedback mappings; validate Discussions contact. |
| [script/lint_swift.sh](../script/lint_swift.sh) | Pinned, digest-verified SwiftLint; retain. |
| [script/make_audio.py](../script/make_audio.py) | Original bundled audio generation; retain. |
| [script/make_gallery.swift](../script/make_gallery.swift) | Character gallery generation; retain. |
| [script/make_icon.swift](../script/make_icon.swift) | App icon generation; retain. |
| [script/make_site_art.swift](../script/make_site_art.swift) | Website character/cursor generation; retain. |
| [script/package_dmg.sh](../script/package_dmg.sh) | Installer creation, signing preflight and layout checks; retain unchanged. |
| [script/package_release.sh](../script/package_release.sh) | Universal app/ZIP, resource, metadata and Release safety checks; retain unchanged. |
| [script/sign_release.sh](../script/sign_release.sh) | Detached Minisign signing, digest checks and tamper rejection; retain unchanged. |
| [script/test_native.sh](../script/test_native.sh) | Bundle, signature, notice, icon and audio checks; retain. |
| [script/test_pointer_visual.sh](../script/test_pointer_visual.sh) | Offscreen pointer renderer checks; retain. |
| [script/test_studio_layout.sh](../script/test_studio_layout.sh) | Offscreen Studio layout checks; retain. |

## Live documentation and evidence links

- [Wiki](https://github.com/smcnab1/pokelet/wiki): cloned the live Wiki, checked all sidebar destinations against its 15 content pages and checked all unique Markdown link destinations over HTTPS. HTTP success is distinguished from expected sign-in redirects for issue submission/private reports. No Wiki edits were made.
- [Discussions](https://github.com/smcnab1/pokelet/discussions): GraphQL confirms Announcements, General, Ideas, Polls, Q&A (answerable), and Show and tell. Q&A covers support, Ideas covers proposals; no missing category needs creating.
- [Website](https://smcnab1.github.io/pokelet/), [Releases](https://github.com/smcnab1/pokelet/releases), [issue chooser](https://github.com/smcnab1/pokelet/issues/new/choose), [private security policy](https://github.com/smcnab1/pokelet/security/policy), [Minisign](https://jedisct1.github.io/minisign/) and [Apple first-launch guidance](https://support.apple.com/102445) resolved during the audit.
- [OpenSSF public JSON](https://www.bestpractices.dev/projects/16999.json) explicitly cites `CHANGELOG.md`, `docs/STUDIO.md`, `docs/BETA2_ACCEPTANCE.md`, `docs/BETA2_RELEASE_READINESS.md`, `docs/BETA2_RELEASE_NOTES_DRAFT.md`, `docs/INTERACTIVE_ACCEPTANCE.md` and `docs/OPENSSF_ASSESSMENT.md#repository-controls`, among other retained source/policy links. Historical questionnaire claims still refer to Beta 1 and preparation of Beta 2. The pointers preserve evidence access; maintainer review of those external answers is still needed.
- [OpenSSF badge](https://www.bestpractices.dev/projects/16999), [Scorecard](https://scorecard.dev/viewer/?uri=github.com/smcnab1/pokelet) and [CI](https://github.com/smcnab1/pokelet/actions/workflows/macos.yml) remain linked. Scores and versions come from live badges, not copied numbers. The broader Markdown/website link audit checked 122 unique HTTPS destinations: 121 resolved and the Product Hunt listing page returned HTTP 403 to the automated client. Its badge rendered in browser checks; automated access denial is not treated as a confirmed broken link.

## Remaining manual work and limits

- Review the external OpenSSF questionnaire’s historical release/documentation/discussion justifications against the now-live Wiki and Releases. This PR preserves the cited paths; it does not change the external certification record.
- The live Wiki Home still says Discussions “once enabled”; Discussions is already enabled. This is a small Wiki follow-up, not a blocker for navigation. No additional categories are required.
- Independent review, account MFA confirmation, full-app coverage, native Intel/minimum-OS acceptance, broader accessibility and Apple distribution trust remain separate evidence/configuration matters. No repository setting is weakened to obtain a badge.
- Issue-form schema and in-app URL mappings are checked locally. A signed-in GitHub preview after merge remains a manual check; no public test issue or security report should be submitted for validation.
- Do not merge, deploy, change a published tag/asset, re-sign a released binary or publish another release as part of this finalisation. Check results for this change belong in the PR.
