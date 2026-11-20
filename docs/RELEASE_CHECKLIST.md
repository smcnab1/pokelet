# First public release checklist

## Local candidate

- Build Debug and the universal Release archive. Run the headless tests, bundle smoke check, documentation links and workflow lint.
- Confirm both architecture slices target macOS 14 or later. Verify the extracted bundle signature and the SHA-256 checksum.
- Review original artwork, sound provenance and both MIT notices. Scan tracked changes for sensitive data and generated binaries.
- Record all results in [VERIFICATION.md](../VERIFICATION.md).

## Desktop approval and acceptance

- Obtain separate approval to run the [interactive acceptance sequence](INTERACTIVE_ACCEPTANCE.md).
- Confirm restore and fail-open cases with real input. Keep Presentation Mode disabled on ordinary launches until the evidence supports enabling it.
- Review light and dark Settings, VoiceOver, input, capture and performance. Add representative screenshots and a short demo using safe data.
- Choose the public version after acceptance. Confirm the signing and Apple notarisation plan. This candidate uses ad hoc signing.

## Publication approval

- Obtain explicit permission to create or update `smcnab1/pokelet`, push the branch, make the repository public, enable Pages or publish binaries.
- Once authorised, enable private security reports, verify CI on the submitted commit, review and assign the PR, and associate any related issue.
- Verify the final distribution from a clean download. Attach the universal ZIP and its SHA-256 checksum and update download links.
- Preview the static site before enabling Pages. Add canonical and Open Graph image URLs after the final host is confirmed.

Proposed GitHub description: **Free animated cursor companion for macOS with cartoon pointers and click effects.**

Proposed topics: `macos`, `swift`, `swiftui`, `appkit`, `menu-bar`, `cursor`, `cursor-highlighter`, `screen-recording`, `presentations`.

Proposed title after acceptance: **Pokelet 1.1 — Custom colours and cursor companion**. Use [the changelog](../CHANGELOG.md) for the release description. Mention macOS support, cursor replacement limits, signature status, download checksums and the status of Presentation Mode.
