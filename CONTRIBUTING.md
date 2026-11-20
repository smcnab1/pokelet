# Contributing to Pokelet

Use GitHub Issues for feature requests or reproducible bugs. Include the Pokelet version, macOS version, Mac architecture, display setup and the relevant pointer mode. Follow the [security policy](SECURITY.md) for private reports.

1. Build the Pokelet scheme using Xcode 16 or later.
2. Run `swift test`, `./script/test_native.sh` and `python3 script/check_docs.py`.
3. Open a focused pull request. Describe the behaviour and list the checks you ran. For visual changes, attach safe screenshots that show light and dark appearance.

The automated tests use mock cursor and input state, offscreen drawing and temporary audio fixtures. Exercise live cursor changes and click suppression only in a controlled test session. The [acceptance plan](docs/INTERACTIVE_ACCEPTANCE.md) includes recovery steps.

Pokelet uses Apple frameworks. If you contribute artwork or audio, include its origin and licence. By contributing original code or assets, you agree to license your contributions under the [MIT licence](LICENSE).
