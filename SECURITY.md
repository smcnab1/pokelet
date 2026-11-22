# Security policy

Please report vulnerabilities privately through [GitHub's private vulnerability reporting](https://github.com/smcnab1/pokelet/security/advisories/new), particularly concerns about cursor restoration, input interception, unsafe imported audio, permissions or release integrity. If this route is unavailable, contact the maintainer through the [GitHub profile](https://github.com/smcnab1) without publishing exploit details.

Include the affected Pokelet version, macOS version, impact and minimal reproduction steps. Use harmless test files and exclude personal data. Please keep details private while the issue is assessed. An acknowledgement or remediation deadline is not guaranteed.

## Distribution and trust

Pokelet's current public beta is **ad hoc signed and not notarised by Apple**. An ad hoc signature is a package-integrity mechanism, **not proof of the developer's identity**. Obtain downloads from the [official GitHub Releases page](https://github.com/smcnab1/pokelet/releases), compare the published SHA-256 checksum and use only Apple's [per-app Open Anyway procedure](https://support.apple.com/102445) if you trust the source. Do not disable Gatekeeper globally. Stop if macOS reports damage or malware.

The [release checklist](docs/RELEASE_CHECKLIST.md) describes the build and verification process. See the [privacy policy](PRIVACY.md) for data handling and permissions. Presentation Mode's click suppression is excluded from public Release builds.
