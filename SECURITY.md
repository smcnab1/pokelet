# Security policy

Please report vulnerabilities privately through [GitHub's private vulnerability reporting](https://github.com/smcnab1/pokelet/security/advisories/new), particularly concerns about cursor restoration, input interception, unsafe imported audio, permissions or release integrity. [Sam McNab](https://github.com/smcnab1) is the security contact.

Include the affected Pokelet version, macOS version, impact and minimal reproduction steps. Use harmless test files and exclude personal data. Please keep details private while the issue is assessed.

## What happens after you report

- The maintainer aims to acknowledge reports within 14 days, then confirms the affected versions, impact and any workaround in the private report.
- Confirmed issues are prioritised by severity and exposure. Treat credible critical issues as urgent. Block a release with a confirmed exploitable medium-or-higher issue identified by analysis until it is fixed. Record false positives with the reason and scope of any suppression.
- Coordinate disclosure with the reporter. Publish confirmed vulnerabilities through [GitHub Security Advisories](https://github.com/smcnab1/pokelet/security/advisories) with affected and fixed versions, available mitigations and a CVE where appropriate. Credit the reporter unless they request anonymity.

Keep credentials outside Git and in their provider's credential store or the macOS Keychain. Limit access to the maintainer and the job that needs it. Revoke or rotate any exposed credential promptly, check its use and remove the exposed material from active configuration.

## Distribution and trust

Download Pokelet from [official GitHub Releases](https://github.com/smcnab1/pokelet/releases) and follow the [verification guide](docs/VERIFYING_RELEASES.md). Each release states its signing and notarisation status and provides its available verification files. A checksum alone does not authenticate the publisher. Verify detached signatures with Pokelet’s [Minisign public key](security/pokelet-minisign.pub), preferably a previously trusted copy. Minisign publisher verification and Apple Developer ID/notarisation are separate checks.

In update-enabled builds, Sparkle uses a channel-specific HTTPS feed and an embedded EdDSA public key to verify the appcast, release notes and archive before installation. The free update-enabled build keeps Hardened Runtime with library validation disabled for the Pokelet executable. This relaxes its checks on libraries loaded into the process so it can load Sparkle without an Apple Team ID. Apple publisher verification and notarisation are unavailable for ad hoc builds. The [update release procedure](docs/RELEASE_CHECKLIST.md#signed-sparkle-updates) covers verification and key custody.

## Supported versions

Use the newest published release, including a prerelease where applicable. Security fixes target the current source and a subsequent release; older versions have no separate backport or long-term support commitment. Report suspected vulnerabilities in any version and include its exact version and build. No fixed support duration is promised.

The [release checklist](docs/RELEASE_CHECKLIST.md) describes the maintainer’s verification process. See the [privacy policy](PRIVACY.md) for data handling and permissions.
