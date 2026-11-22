# Contributing to Pokelet

Pokelet is a small, native macOS project. Focused fixes, clear bug reports and practical improvements are welcome.

Before starting a substantial feature, open a [feature request](https://github.com/smcnab1/pokelet/issues/new?template=feature.yml) to agree its scope. Use the [bug report](https://github.com/smcnab1/pokelet/issues/new?template=bug.yml) form for defects. Include the app and macOS versions, Mac architecture, display setup and pointer mode where relevant. Report vulnerabilities [privately](SECURITY.md), not through a public issue.

## Propose a change

1. Create a branch from `main` and keep the pull request focused.
2. Use Xcode 16 or later to build the `Pokelet` scheme.
3. Run the relevant checks before requesting review:

   ```sh
   swift test -Xswiftc -warnings-as-errors
   ./script/test_native.sh
   python3 script/check_docs.py
   ruby script/check_issue_forms.rb
   ```

4. Describe the behaviour, risk and actual checks performed in your pull request. If a check was not run, say so. For visible changes, add representative light and dark screenshots where possible.
5. Wait for review and passing CI before merging. Maintainers determine whether and when to release.

**Testing policy:** Changes adding major functionality or fixing regressions should add or update automated tests where feasible. When automated testing cannot safely cover live cursor, input or Accessibility behaviour, document a focused manual test and recovery route instead of claiming equivalent automated coverage. Recent test and acceptance evidence is linked from [verification](VERIFICATION.md).

The automated suite uses mock cursor and input state, offscreen drawing and temporary audio fixtures. Do not exercise live click suppression outside an approved controlled Debug test. The [interactive acceptance guide](docs/INTERACTIVE_ACCEPTANCE.md) records recovery steps; public Release builds do not enable Presentation Mode.

Pokelet relies on Apple system frameworks and builds with Xcode. For artwork or audio, include the origin, licence and permission to redistribute it. By contributing original code or assets, you agree to make them available under the project's [MIT licence](LICENSE). See the [third-party notices](THIRD_PARTY_NOTICES.md).
