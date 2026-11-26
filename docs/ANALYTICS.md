# Pokelet usage analytics

Hosted Test Mode ingestion and the dashboard configuration passed verification. Production reporting is disabled in release packaging pending the provider response and approval of the [draft privacy notice](ANALYTICS_PRIVACY_DRAFT.md). Proposed next beta: `v1.4.0-beta.1`, build 8, after stable build 7.

## Payload and counting

Reporting requires both a configured Release build and opt-in in **Studio → General → Privacy & Analytics**. Debug, CI, acceptance profiles and developer-excluded installations are ineligible. Additional diagnostics are unavailable. The feature adds no collection or calls to the cursor path.

| Sent over HTTPS to TelemetryDeck | Purpose |
| --- | --- |
| `appID` | Public TelemetryDeck app identifier. The organisation namespace, when assigned, routes the request in the URL. |
| `clientUser` | SHA-256 of an installation-specific random UUID and the public app ID. The UUID stays on the Mac. TelemetryDeck salts and hashes the digest again. |
| `type` | `Usage.firstLaunch` for the first reporting attempt after opt-in, or `Usage.active` for a later day. Both count towards activity. |
| `payload.Pokelet.App.version` | Pokelet marketing version and build in one value. The build distinguishes releases that share a marketing version. |

There are no automatic SDK properties, analytics cookie, session identifier or client timestamp. The request uses a fixed user agent and language wildcard. TelemetryDeck assigns receipt time, rounds the timestamp to the hour and can derive a daily session ID on its side. The receiving infrastructure necessarily handles the network source IP. TelemetryDeck says app ingestion performs no location lookup and does not retain the IP. [Ingest API](https://telemetrydeck.com/docs/ingest/v2/) · [Provider privacy FAQ](https://telemetrydeck.com/faq/privacy/)

[Swift SDK 2.14.2](https://github.com/TelemetryDeck/SwiftSDK/releases/tag/2.14.2) was the latest stable release reviewed on 26 November 2026. Its [signal manager](https://github.com/TelemetryDeck/SwiftSDK/blob/2.14.2/Sources/TelemetryDeck/Signals/SignalManager.swift) unconditionally constructs the [default payload](https://github.com/TelemetryDeck/SwiftSDK/blob/2.14.2/Sources/TelemetryDeck/Signals/Signal.swift), including hardware model, architecture, display, OS, locale, time zone, accessibility preferences and usage counters. It also restores queued events from disk on initialisation. Pokelet uses the official app Ingest API through Foundation so only the fields above are constructed or sent. Revisit the SDK when a stable version can disable unwanted collection and cancel delivery on withdrawal.

Pokelet records the attempt before sending. It makes one attempt per UTC day, including when it stays open overnight or resumes from sleep. Failed attempts are dropped. There is no retry queue or connectivity wait. A first attempt lost offline undercounts new reporting installations, though the installation can appear in future activity counts. Updates keep the same local state. Withdrawal clears the code and consent record while leaving the last attempt day to prevent same-day duplication and a second first-launch event after re-enrolment. A new opt-in creates a different code, so a period spanning both opt-ins can count the installation twice in activity. Reinstalls with cleared preferences and different macOS profiles can also change counts. These are estimates of participating installations. GitHub download counts measure separate distribution activity.

## Ingest routing

Use the organisation namespace exactly as shown in [TelemetryDeck’s Namespace settings](https://dashboard.telemetrydeck.com/namespace). Namespaces can use reverse DNS, such as `com.example.pokelet`. The v2 API documents an app-ID-only endpoint for organisations without a namespace. TelemetryDeck migrated existing organisations to namespaces, so check the assigned value before qualifying a release. A successful HTTP response confirms receipt by the ingest endpoint. Read back a clearly marked Test Mode event in the app’s dashboard to confirm routing and indexing. The Free plan can take up to a day to show a new event. [Namespaces](https://telemetrydeck.com/docs/articles/namespaces/) · [Namespace migration](https://telemetrydeck.com/blog/namespace-conversion-finished/) · [Ingest API v2](https://telemetrydeck.com/docs/ingest/v2/) · [Test Mode](https://telemetrydeck.com/docs/articles/test-mode/)

## Dashboard configuration

In the [TelemetryDeck dashboard](https://dashboard.telemetrydeck.com/), select the Pokelet app in its own Free organisation. Turn off Test Mode in the production dashboard. Create a dashboard called **Pokelet usage** and add the following insights. Where TelemetryDeck says **Users** or **Unique by user**, the unit in this app is an installation code. Use UTC and end recurring summaries at the last complete bucket.

| Insight | Filter | Measure and display |
| --- | --- | --- |
| New reporting installations | `Usage.firstLaunch` | Unique installations, daily or weekly time series. Title reflects first reporting rather than original installation. |
| Daily active installations | `Usage.firstLaunch` OR `Usage.active` | Unique installations, day buckets. |
| Weekly active installations | Same two event types | Unique installations, week buckets. |
| Monthly active installations | Same two event types | Unique installations, calendar month buckets. Set a date range that includes at least one full month within available history. |
| Installations by reported version | Same two event types | Breakdown on `Pokelet.App.version`, unique installations per version, last 30 days. The synthetic upgrade counted one installation under both reported builds. Version rows can overlap across an update and do not measure each installation’s latest build. |

Use **Any event** for the activity and version queries if the Pokelet app is dedicated to these two types. If more event types are introduced, use an OR filter for the two usage types. Never sum daily unique counts to get weekly or monthly counts. The free dashboard updates in batches. See the provider guides for [custom dashboards](https://telemetrydeck.com/docs/articles/create-custom-dashboards/), [unique counting and breakdowns](https://telemetrydeck.com/docs/api/insights-reference/) and [monthly active insight intervals](https://telemetrydeck.com/docs/articles/insights-about-monthly-users/).

## Free-tier capacity

For a new organisation, the free plan provides 50,000 events per month across up to three apps and three months of queryable history. Free accounts have no automatic paid upgrade or payment-card requirement. Once the monthly allowance is reached, excess events are discarded. Keep Pokelet on Free and monitor the 80% usage alert. [Pricing](https://dashboard.telemetrydeck.com/plans) · [Subscription FAQ](https://telemetrydeck.com/faq/subscription/)

| Scenario | Attempts per 31-day month |
| --- | ---: |
| 100 opted-in installations active daily | 3,100 |
| 500 opted-in installations active 12 days each | 6,000 |
| 1,500 opted-in installations active daily | 46,500 |

At 31 days the cap fits 1,612 installations active every day, assuming no other apps share the allowance. First reports are already included. As context, GitHub showed 54 DMG downloads across five published prereleases on 26 November 2026. It is too early to estimate active installations from that number.

## Before enabling reporting

1. Owner signs in or creates a Free TelemetryDeck organisation, reviews the binding terms and creates dedicated Pokelet and test app entries. Record the public production app UUID and organisation namespace, if assigned. Keep dashboard access restricted. The app never needs a dashboard token or administrative key.
2. Confirm the legal roles and permitted processing with TelemetryDeck for this exact payload and infrastructure path. The provider's [data agreement](https://telemetrydeck.com/dpa/) is incorporated into its terms and expressly disclaims Article 28 processor status for data it considers anonymous. Pokelet treats the stable digest as potentially pseudonymous. If TelemetryDeck processes personal data on Pokelet's behalf, obtain appropriate Article 28 terms before enabling reporting. Confirm standard processing stays in Germany/Finland, including support or onward access. UK-to-EEA transfers are covered by [UK adequacy regulations](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/international-transfers/adequacy-regulations/is-the-restricted-transfer-covered-by-adequacy-regulations/).
3. Set and record a justified retention limit and rights-handling process. Three months of queryable history is not deletion. The provider currently offers whole-month deletion, no single-installation lookup or deletion, and describes long-lived raw backups. Confirm cold storage and backup expiry and the practical withdrawal, erasure and recipient-notification procedure. Keep reporting disabled if the agreed treatment cannot meet those requirements. [Provider retention FAQ](https://telemetrydeck.com/faq/subscription/) · [ICO withdrawal guidance](https://ico.org.uk/for-organisations/direct-marketing-and-privacy-and-electronic-communications/guidance-on-the-use-of-storage-and-access-technologies/how-do-we-manage-consent-in-practice/)
4. Record the processing and consent notice in the owner's privacy records, confirm the rights contact and whether EU GDPR territorial scope, EU representative requirements, UK registration or a DPIA apply. The app keeps the local affirmative choice, timestamp and notice revision. Material changes to use or disclosure require renewed consent. The legal design uses consent under UK/EU GDPR Article 6(1)(a) and Article 7, and prior consent for analytics storage/access under PECR and the applicable national rules implementing ePrivacy Article 5(3). It does not rely on the UK statistical-purpose exception. [ICO PECR rules](https://ico.org.uk/for-organisations/direct-marketing-and-privacy-and-electronic-communications/guidance-on-the-use-of-storage-and-access-technologies/what-are-the-pecr-rules/) · [EU GDPR](https://eur-lex.europa.eu/eli/reg/2016/679/oj/eng) · [EDPB consent guidance](https://www.edpb.europa.eu/documents/guideline/guidelines-052020-on-consent-under-regulation-2016679_en) · [EDPB ePrivacy guidance](https://www.edpb.europa.eu/documents/guideline/guidelines-22023-on-technical-scope-of-art-53-of-eprivacy-directive_en)
5. Configure the dashboard above and qualify the wire request and chart using a disposable installation and the separate test app. Confirm the official privacy page is live before enabling reporting. Enabling release packaging requires a separately reviewed change.

### Exclude a developer installation

Quit Pokelet, run the following command, then relaunch. The setting applies to the production bundle ID on that macOS account and survives updates and Reset Settings.

```sh
defaults write uk.co.sammcnab.Pokelet PokeletAnalyticsDeveloperExcluded -bool true
```

To remove the exclusion, quit Pokelet, delete that key and relaunch. Leave **Share basic usage** off on real developer profiles if you no longer intend to report from them.
