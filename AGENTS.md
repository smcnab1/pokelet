# Pokelet - repository instructions

These instructions apply to all future work in this repository, including Codex tasks. Keep the implementation and documentation concise; do not change the release mechanism casually.

## Normal development

- Start from current `main`. Make focused changes in a branch and PR; do not silently merge, tag, release or deploy. Respect explicit approval for publication.
- Add user-facing changes under `Unreleased` in `CHANGELOG.md`. It is the source for in-app What's New and GitHub release change notes. Keep README and Wiki evergreen; edit them only when behaviour or guidance changes.
- Run the relevant existing tests, SwiftLint and CI. Preserve the pointer recovery behaviour, macOS 14+ target, universal arm64/x86_64 support, signing and package checks.
- Avoid unrelated refactors, dependency updates or excessive manual acceptance checks.

## Every beta release or updater change

The **authoritative release procedure** is [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md), especially **Signed Sparkle updates**. Read it and the current scripts before preparing a release. Follow the *current* published releases and beta appcast, not the example versions in documentation.

- The verified public beta route uses **Sparkle 2**, **ad hoc-signed update-enabled Release builds**, and **EdDSA-signed archives, appcast and notes**. It does **not** require Apple Developer ID or notarisation. Retain Hardened Runtime and the existing, documented library-validation exception for this route. Never bypass Sparkle signature checks or change signing policy without explicit review.
- Beta channel: existing Keychain account `pokelet-beta`; `./script/package_release.sh --ad-hoc-updates --channel beta`; `script/prepare_sparkle_release.py --channel beta`; feed `https://smcnab1.github.io/pokelet/updates/beta/appcast.xml` from `docs/site/updates/beta/`. Keep the stable feed and separate `pokelet-stable` key untouched unless specifically authorised.
- For each release, use an **unused tag** and a **strictly higher build number** than all published builds. Move the relevant changelog entries into a dated release; reuse those change bullets for Studio, the signed feed and GitHub notes. Use existing packaging, Minisign and Sparkle tooling - no separate updater or duplicate changelog.
- Verify the exact source, universal app, nested signatures, DMG, checksum, detached Minisign signature, ZIP, Sparkle signatures and signed appcast. Never commit private keys, expose key material, overwrite released assets or move an existing tag.
- Publish the verified **GitHub update ZIP** and separately approved **GitHub Pages beta feed and notes** in the documented order. Check that the live HTTPS bytes and channel match the signed staging manifest before distributing the bootstrap DMG or claiming updates work. Keep historical release-note URLs valid.
- For material updater changes, prove installation from an older **published update-enabled beta** to a newer one, including relaunch, settings retention, What's New and an up-to-date check. For routine non-updater changes, do targeted regression tests rather than repeating the full historical acceptance matrix.
- Preserve the known-good Beta 4 -> Beta 5 live update precedent; always validate new release assets and feed independently. Disclose that the free route remains ad hoc-signed and unnotarised.

If a user asks for a code change only, prepare a PR; **do not automatically release**. If they explicitly authorise a release, follow the checklist and stop for real signature, CI or asset-integrity failures.
