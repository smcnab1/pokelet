# Draft privacy notice for optional usage reporting

Unpublished. Production reporting is unavailable. This text describes the verified implementation for a future analytics-enabled build.

## Optional app analytics

Open **Pokelet Studio → General → Privacy & Analytics**. **Share basic usage** starts off. You can leave it off, turn it off again in the same place, or use **Reset Settings…** to withdraw consent. Your choice does not affect the pointer or other features. Pokelet uses your consent as the lawful basis for usage reporting and its associated storage and access on your Mac.

With your permission, Pokelet creates a random installation code and keeps it and the consent record on your Mac. A report carries the code in hashed form, the Pokelet version and build, and whether this is the first report or a later day of use. TelemetryDeck assigns a timestamp and rounds it to the hour in analytics records. Reports help estimate how many installations use Pokelet and how quickly versions are adopted. Cursor activity, screen contents, other apps, chosen characters, device details and location are outside these reports. Pokelet attempts at most one report per UTC day. Failed or offline attempts are dropped.

Turning off reporting cancels pending transmission and clears the installation code and consent record. Pokelet keeps the date of its last attempt locally to prevent duplicate reporting if you opt in again. A later opt-in creates a new code. Withdrawal applies to future reporting. A request TelemetryDeck has already received cannot be recalled by the app.

### Service, retention and rights

Sam McNab is responsible for Pokelet’s usage analytics. TelemetryDeck GmbH provides the hosted analytics service. It says it hashes the installation code again and runs the service on Hetzner infrastructure in Germany and Finland. Network delivery exposes your IP address to receiving infrastructure. TelemetryDeck says it does not use it to locate app traffic or retain it in databases, logs or backups. UK adequacy regulations cover transfers to the EEA. [TelemetryDeck’s privacy FAQ](https://telemetrydeck.com/faq/privacy/) · [Service locations and agreement](https://telemetrydeck.com/faq/compliance/) · [ICO adequacy guidance](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/international-transfers/adequacy-regulations/is-the-restricted-transfer-covered-by-adequacy-regulations/)

**Awaiting TelemetryDeck’s written response**

| Outstanding detail | To complete before publication |
| --- | --- |
| Article 28 arrangements | [Confirm the parties’ roles and the terms covering this payload and ingestion route.] |
| Raw event retention | [Confirm how long raw events remain in active and cold storage and when deletion completes.] |
| Backup retention and expiry | [Confirm the backup lifetime and what happens to deleted data after restoration.] |
| Individual erasure | [Confirm how a request is identified, verified and fulfilled, including limits and the response to the requester.] |

Email [Sam McNab](mailto:sam@sammcnab.co.uk) to ask about your data or exercise applicable rights of access, correction, restriction, portability or erasure. You may complain to the [UK Information Commissioner’s Office](https://ico.org.uk/make-a-complaint/) or your local data protection authority.
