# Security policy

Please report vulnerabilities privately through [GitHub's private vulnerability reporting](https://github.com/smcnab1/pokelet/security/advisories/new), particularly concerns about cursor restoration, input interception, unsafe imported audio, permissions or release integrity. [Sam McNab](https://github.com/smcnab1) is the security contact.

Include the affected Pokelet version, macOS version, impact and minimal reproduction steps. Use harmless test files and exclude personal data. Please keep details private while the issue is assessed.

## What happens after you report

- The maintainer aims to acknowledge reports within 14 days, then confirms the affected versions, impact and any workaround in the private report.
- Confirmed issues are prioritised by severity and exposure. Treat credible critical issues as urgent. Block a release with a confirmed exploitable medium-or-higher issue identified by analysis until it is fixed. Record false positives with the reason and scope of any suppression.
- Coordinate disclosure with the reporter. Publish confirmed vulnerabilities through [GitHub Security Advisories](https://github.com/smcnab1/pokelet/security/advisories) with affected and fixed versions, available mitigations and a CVE where appropriate. Credit the reporter unless they request anonymity.

Keep credentials outside Git and in their provider's credential store or the macOS Keychain. Limit access to the maintainer and the job that needs it. Revoke or rotate any exposed credential promptly, check its use and remove the exposed material from active configuration.

## Distribution and trust

Pokelet's current public beta is **ad hoc signed and not notarised by Apple**. An ad hoc signature is a package-integrity mechanism, **not proof of the developer's identity**. Obtain downloads from the [official GitHub Releases page](https://github.com/smcnab1/pokelet/releases), compare the published SHA-256 checksum and use only Apple's [per-app Open Anyway procedure](https://support.apple.com/102445) if you trust the source. Do not disable Gatekeeper globally. Stop if macOS reports damage or malware.

The [release checklist](docs/RELEASE_CHECKLIST.md) describes the build and verification process. See the [privacy policy](PRIVACY.md) for data handling and permissions. Presentation Mode's click suppression is excluded from public Release builds.
