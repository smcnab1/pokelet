# Verification coverage and limitations

This page describes the available checks. A command listed here is not evidence that a particular release passed: record the exact source commit, package digest, host and observed result when qualifying a candidate.

| Check | Coverage | Limit |
| --- | --- | --- |
| `./script/lint_swift.sh` | Hash-verified SwiftLint over app Swift source; selected failure and security rules. | Targeted rules are not a complete security review. |
| `swift test -Xswiftc -warnings-as-errors` | Preferences and migration, geometry, rendering, cursor recovery decisions, click cadence, gesture pairing, audio import, feedback URLs, bundled release notes and upgrade history. | SwiftPM excludes app entry points, views and several native services. |
| `./script/test_native.sh` | Build or inspect a supplied app; metadata, signatures, Sparkle helper architectures, licences, icon and audio decoding. | Does not establish live pointer behaviour or Apple distribution trust. |
| `./script/test_studio_layout.sh` | Offscreen native layouts across window sizes, appearances and text sizes, plus Sparkle build ordering. | Does not establish VoiceOver or complete keyboard usability. |
| `./script/test_pointer_visual.sh /tmp/pokelet-visual-results` | Offscreen pointer contact-point and effect alignment. | Does not prove physical mouse or multi-display behaviour. |
| `./script/package_release.sh /path/to/new-output` | Universal Release, both macOS 14 targets, ZIP/checksum, extracted resources, signatures and exclusion of Debug acceptance flags. | Build compatibility does not establish Intel or macOS 14 runtime coverage. |
| `node --test Tests/Browser/releases.test.mjs` | Stable/prerelease ordering, DMG selection and invalid-asset fallback; no browser or network needed. | Full fetch/cache/download behaviour needs the browser suite. |
| [Website browser suite](docs/WEBSITE.md#run-the-browser-checks) | Chromium, Firefox and WebKit interactions, responsive navigation, accessibility, release API fixtures and failure recovery. | Automated accessibility checks do not replace user testing. |

The [macOS CI workflow](.github/workflows/macos.yml) runs the Swift, documentation, issue-form, release-selection, layout, build, analysis and packaging checks. Full browser and controlled desktop checks are separate.

## Runtime acceptance

Use the [interactive acceptance guide](docs/INTERACTIVE_ACCEPTANCE.md) for owner-approved live checks with a disposable profile and an agreed recovery route. Record passed, failed, skipped and owner-reported checks separately. Public Release builds disable experimental Presentation Mode click suppression.

Do not infer complete coverage for native Intel, macOS 14, multiple displays, VoiceOver, full keyboard traversal, Login Items, sleep/wake, audible output-device changes or quarantined first launch. Each requires explicit evidence for the tested package and environment. Follow each [release’s notes](https://github.com/smcnab1/pokelet/releases) for its actual limitations and signing status.

## Historical evidence

- [Beta 2 acceptance](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/BETA2_ACCEPTANCE.md) and [readiness](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/BETA2_RELEASE_READINESS.md) retain automated, local, physical and owner-reported outcomes without upgrading their status.
- [Earlier Studio and desktop trials](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/docs/LIVE_ACCEPTANCE.md) and [previous verification record](https://github.com/smcnab1/pokelet/blob/6bb59a7c2b6c61a390e0079ed5fdd2d58ca521ae/VERIFICATION.md) preserve the original screenshots, performance measurements and methods.
- The [OpenSSF assessment](docs/OPENSSF_ASSESSMENT.md) records 82.0% line coverage of a SwiftPM subset at its review date. Full-app statement and branch coverage remain unestablished.

For a new performance comparison, use the same hardware, build settings, display refresh rate, pointer configuration and window state. Sample matched stationary, movement, click and drag workloads; report sample duration, CPU and RSS separately, and state whether WindowServer and battery use were measured.
