# Security policy

Please report vulnerabilities privately through [GitHub's private vulnerability reporting](https://github.com/smcnab1/pokelet/security/advisories/new), particularly concerns about cursor restoration, input interception, unsafe imported audio, permissions or release integrity. [Sam McNab](https://github.com/smcnab1) is the security contact.

Include the affected Pokelet version, macOS version, impact and minimal reproduction steps. Use harmless test files and exclude personal data. Please keep details private while the issue is assessed.

## What happens after you report

- The maintainer aims to acknowledge reports within 14 days, then confirms the affected versions, impact and any workaround in the private report.
- Confirmed issues are prioritised by severity and exposure. Treat credible critical issues as urgent. Block a release with a confirmed exploitable medium-or-higher issue identified by analysis until it is fixed. Record false positives with the reason and scope of any suppression.
- Coordinate disclosure with the reporter. Publish confirmed vulnerabilities through [GitHub Security Advisories](https://github.com/smcnab1/pokelet/security/advisories) with affected and fixed versions, available mitigations and a CVE where appropriate. Credit the reporter unless they request anonymity.

Keep credentials outside Git and in their provider's credential store or the macOS Keychain. Limit access to the maintainer and the job that needs it. Revoke or rotate any exposed credential promptly, check its use and remove the exposed material from active configuration.

## Distribution and trust

The current public beta is **ad hoc signed and unnotarised**. Download Pokelet from [official GitHub Releases](https://github.com/smcnab1/pokelet/releases) and follow the [verification and first-launch guide](docs/VERIFYING_RELEASES.md). Beta 2 provides a SHA-256 checksum and detached signature. Verify the signature with Pokelet’s [Minisign public key](security/pokelet-minisign.pub). Beta 1 provides a checksum.

The [release checklist](docs/RELEASE_CHECKLIST.md) describes the maintainer’s verification process. See the [privacy policy](PRIVACY.md) for data handling and permissions.
