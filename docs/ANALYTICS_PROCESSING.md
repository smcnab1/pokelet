# Optional usage reporting — processing record and risk assessment

Reviewed 26 November 2026. Owner and controller: Sam McNab, [sam@sammcnab.co.uk](mailto:sam@sammcnab.co.uk). Production reporting is disabled. Hosted verification used synthetic events in Test Mode.

## Processing record

| Activity | Scope and safeguards |
| --- | --- |
| Purpose and participants | Estimate first participation, active installations and version adoption for users who opt in. No accounts, advertising, cross-app matching or individual decisions. |
| Basis and local storage | Prior consent for analytics and its associated storage/access. The Mac holds the random identifier, grant time, notice revision and last attempt day. Withdrawal or an obsolete revision clears the grant and identifier. The last day limits duplicates. |
| Data and recipients | Pokelet sends TelemetryDeck a pseudonymous installation digest, event type, app ID and version/build over HTTPS. Receipt adds timing and service metadata. The network handles the IP during receipt. No diagnostic or cursor stream. |
| Retention and transfers | [Confirm raw event and cold storage retention, backup expiry and deletion after restore.] [Confirm hosting, subprocessors, international support access, transfers and any safeguards.] |
| Processor and rights | [Confirm legal roles and Article 28 arrangements where applicable.] [Confirm secure matching, erasure feasibility and response steps.] Sam handles email requests and complaints and seeks provider assistance where appropriate. |
| Security | Separate production/test reporting, developer exclusion, minimal payload, ephemeral transport, no redirects or retries, at most one attempt per UTC day. Restrict dashboard access to the owner. |

Regular daily reporting is recurring processing. The under-250-employee exception does not remove the Article 30 record requirement for that activity. Maintaining this short record while disabled prepares for activation. [ICO documentation guidance](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/accountability-and-governance/guide-to-accountability-and-governance/documentation/)

## Risks and decision

| Risk to participants | Control and remaining decision |
| --- | --- |
| Reports reveal a pattern of use across days | A random pseudonym and coarse payload limit exposure. Reports remain linkable. Confirm who can access raw records, where and for how long. |
| Reporting continues after a change of mind or notice | Opt-in defaults off. Withdrawal cancels delivery. A material revision discards the old code and requires fresh consent. Received reports need a separate rights process. |
| A request cannot be matched, or data is disclosed to the wrong person | Assess each request privately, use only proportionate evidence, explain any demonstrated inability to identify and reconsider if further information enables a match. Confirm provider procedures before launch. |
| Provider copies outlive the stated purpose | Require an agreed raw and backup expiry before enabling. Dashboard visibility alone cannot establish deletion. |

**DPIA screening.** On the current small-scale design, limited voluntary events support aggregate counts. There is no sensitive payload, location tracking, cross-service profiling or consequential decision about a user. Likely high risk has not been identified on these facts. Reassess once the provider answers, or if scale, data or purpose changes. A formal DPIA is mandatory before processing likely to pose high risk. This short screening is the proportionate record for now. [ICO DPIA criteria](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/accountability-and-governance/data-protection-impact-assessments-dpias/when-do-we-need-to-do-a-dpia/)

**ICO fee.** A UK controller using personal information must pay unless exempt. A free, open-source licence alone establishes no exemption. The installation digest is treated as personal data, and recurring product analytics may fall outside the exempt purposes. Sam should complete the ICO assessment for the controller’s activities as a whole and check any existing registration. Register and pay if liable, or record the applicable exemption. The current tier 1 fee is £52 if that tier applies. Turnover, staffing and any other processing are owner facts. [ICO assessment](https://ico.org.uk/for-organisations/data-protection-fee/data-protection-fee-self-assessment/) · [Fee guidance](https://ico.org.uk/for-organisations/data-protection-fee/data-protection-fee)

**Complaints.** UK law requires an accessible route, acknowledgement within 30 days, appropriate enquiries, progress updates and an outcome without undue delay. The email route in the notice is the implementation choice. A separate ticket system is unnecessary. [Data Protection Act 2018, section 164A](https://www.legislation.gov.uk/ukpga/2018/12/section/164A)

**Website badges.** In a fresh Chromium session the published landing page requested images from all three listing services. Product Hunt returned one Set-Cookie header and the browser stored one listing cookie. The other two responses had no Set-Cookie header in this observation. The staged site uses ordinary links with no campaign parameters or referrer. This avoids contacting those providers during page load.
