# Contributing to Pokelet

Pokelet is a small, native macOS project. Focused fixes, clear bug reports and practical improvements are welcome.

Use [Discussions Q&A](https://github.com/smcnab1/pokelet/discussions/categories/q-a) for support and questions, and [Ideas](https://github.com/smcnab1/pokelet/discussions/categories/ideas) to explore proposals. Before implementing a substantial feature, open a [feature request](https://github.com/smcnab1/pokelet/issues/new?template=feature.yml) to agree its scope. Use the [bug report](https://github.com/smcnab1/pokelet/issues/new?template=bug.yml) form for defects. Include the app and macOS versions, Mac architecture, display setup and pointer mode where relevant. Report vulnerabilities [privately](SECURITY.md), not through a public issue.

## Build from source

Install Xcode 16 or later with the macOS SDK and select its command-line tools. Open `Pokelet.xcodeproj` and use **Product → Run** with the **Pokelet** scheme. To build without launching the app:

```sh
./script/build_and_run.sh --build
```

Run `./script/package_release.sh` to produce an ad hoc-signed universal app, ZIP and checksum in `dist/candidate/`. See the [release checklist](docs/RELEASE_CHECKLIST.md) for distribution checks.

## Propose a change

1. Create a branch from `main` and keep the pull request focused.
2. Build the `Pokelet` scheme when changing or testing application code.
3. Run the relevant checks before requesting review:

   ```sh
   ./script/lint_swift.sh
   swift test -Xswiftc -warnings-as-errors
   ./script/test_native.sh
   python3 script/check_docs.py
   python3 -m unittest discover -s Tests/Documentation -v
   ruby script/check_issue_forms.rb
   node --test Tests/Browser/releases.test.mjs
   ```

4. Describe the behaviour, risk and actual checks performed in your pull request. If a check was not run, say so. For visible changes, add representative light and dark screenshots where possible.
5. Wait for review and passing CI before merging. Maintainers determine whether and when to release.

**Testing policy:** Add or update automated tests for major new functionality and for regression fixes where feasible. Document a focused manual check and recovery route for live cursor, input or Accessibility behaviour that cannot be safely automated. See [verification coverage and limitations](VERIFICATION.md).

The automated suite uses mock cursor and input state, offscreen drawing and temporary audio fixtures. Do not exercise live click suppression outside an approved controlled Debug test. The [interactive acceptance guide](docs/INTERACTIVE_ACCEPTANCE.md) records recovery steps; public Release builds do not enable Presentation Mode.

Pokelet relies on Apple system frameworks and builds with Xcode. For artwork or audio, include the origin, licence and permission to redistribute it. By contributing original code or assets, you agree to make them available under the project's [MIT licence](LICENSE). See the [third-party notices](THIRD_PARTY_NOTICES.md).

## Review and maintenance

[Sam McNab](https://github.com/smcnab1) maintains Pokelet and is responsible for triage, merge and release decisions, and [private security reports](SECURITY.md). Contributors submit changes through pull requests. Use Discussions for help and open-ended conversation, Issues for actionable bugs and scoped feature requests, and pull requests to review implementation. Follow the [code of conduct](CODE_OF_CONDUCT.md).

- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) and match the surrounding code. Review failure paths, permissions and user-visible changes. The required macOS CI check runs on pull requests and main updates. Its [SwiftLint rules](.swiftlint.yml) cover selected failure patterns and security-sensitive APIs. Review the rule set and pinned tool version when updating the tool.
- Prefer Apple system frameworks for the app. If a new dependency is needed, document why, its licence, version and update path. SwiftPM lists the app's package dependencies, GitHub Actions use commit pins tracked by Dependabot, and vendored material is listed in the [third-party notices](THIRD_PARTY_NOTICES.md). The [assessment](docs/OPENSSF_ASSESSMENT.md#architecture-and-security-boundaries) identifies the app and website interfaces.

## Documentation

Keep installation and usage guidance in the [Wiki](https://github.com/smcnab1/pokelet/wiki). Keep source, security, privacy, test, packaging, release-verification and website-maintenance instructions in this repository. Update documentation when behaviour changes, rather than copying release notes into several files. [GitHub Releases](https://github.com/smcnab1/pokelet/releases) is the release history.

`python3 script/check_docs.py` checks tracked Markdown and local links, including heading anchors and embedded HTML. Website changes also need the [browser suite](docs/WEBSITE.md#run-the-browser-checks). Keep external evidence URLs working; use an immutable commit reference before retiring an old report or screenshot.
