# Optional usage statistics

**26 November 2026 · Sam McNab · sam@sammcnab.co.uk.** Release packages have an empty analytics configuration. The [public privacy policy](site/privacy/index.html) covers the app and website.

## What we count

The Pokelet dashboard counts **events**. The app sends one event per participating installation per UTC day at most. The required `clientUser` is the literal `pokelet` in every request.

| Estimate | TelemetryDeck insight |
| --- | --- |
| First-time reporting installations | Count `Usage.firstLaunch`. |
| Daily activity | Count both `Usage.firstLaunch` and `Usage.active` in daily UTC buckets. |
| Version adoption | Group both events by `Pokelet.App.version` within a day. Longer periods count installation-days. |

The first attempt consumes the day even when offline. Clearing app preferences can make an installation appear new. Reports cannot measure unique weekly or monthly users. The Free plan includes 50,000 monthly events and drops excess events without upgrading. [Free plan](https://dashboard.telemetrydeck.com/plans) · [Subscription FAQ](https://telemetrydeck.com/faq/subscription/)

## Processing decision

- **Consent.** Prior opt-in covers analytics storage and access under PECR and any personal data processed for reporting under UK GDPR Article 6(1)(a). Consent time and notice revision stay on the Mac. Withdrawal cancels delivery and removes the grant. The last attempt day survives withdrawal to prevent duplicates. Debug, CI, automated tests, acceptance profiles and developer-excluded installations are ineligible. To exclude a local Release installation, quit and run `defaults write uk.co.sammcnab.Pokelet PokeletAnalyticsDeveloperExcluded -bool true`. [ICO guidance](https://ico.org.uk/for-organisations/direct-marketing-and-privacy-and-electronic-communications/guidance-on-the-use-of-storage-and-access-technologies/what-are-the-pecr-rules/)
- **Recipient and location.** TelemetryDeck GmbH applies its standard agreement to direct app ingestion. Hetzner hosts the standard service in Finland and Germany, covered by UK adequacy. The network handles the source IP for delivery. The provider says app ingestion neither retains it nor derives a location. Event time and a server-generated session value accompany the app ID, shared literal, event type and version/build. [Ingest FAQ](https://telemetrydeck.com/faq/ingest-api/) · [Hosting](https://telemetrydeck.com/faq/compliance/)
- **Roles and rights.** The provider's terms treat stored analytics as anonymous and disclaim an Article 28 processor relationship. With the shared literal, neither party has an installation key for lookup or deletion. Sam handles requests and considers any information that would enable identification. There is no reason to start collecting identifiers for that purpose. [Agreement](https://telemetrydeck.com/dpa/) · [Article 11](https://www.legislation.gov.uk/eur/2016/679/article/11)
- **Retention.** Free provides three months of queryable history. Older events can remain in cold storage. Organisation settings allow deletion by month or whole organisation. The provider quotes up to three months for low-level backups after deletion but also describes a separate raw-ingest backup without a fixed expiry. Avoid promising a final deletion date. [Provider deletion and backup FAQ](https://telemetrydeck.com/faq/analytics-data-privacy/)

**Before activation.** Make the policy available at the URL linked in Studio. On the documented app-ingest path, there is no evident need for a bespoke processor contract, individual erasure tool or backup deadline for anonymous counts. If identifiable request data is retained or processed on Sam’s behalf, resolve the role, retention and applicable Article 28 terms first. Sam should check any existing ICO fee registration or exemption against his activities as a whole. The free service adds no subscription fee. [ICO fee self-assessment](https://ico.org.uk/for-organisations/data-protection-fee/data-protection-fee-self-assessment/)
