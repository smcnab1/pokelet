# Draft privacy notice for optional usage reporting

**Unpublished.** Production reporting is disabled. This notice describes a future enabled build and needs the provider details below before use.

## Your choice

Sam McNab is the controller for Pokelet usage reporting. The purpose is to estimate how many participating installations use Pokelet and which versions they run. Pokelet works fully with reporting off.

In **Studio → General → Privacy & Analytics**, **Share basic usage** starts off. Turning it on gives consent to storing and using an installation code on your Mac and sending reports to TelemetryDeck GmbH. Consent is the legal basis for this reporting.

## What leaves your Mac

Pokelet stores a random installation code, the time you agreed and the notice revision locally. The code is independent of your name, Apple ID and hardware. Pokelet hashes it with the app identifier before sending it. The result is pseudonymous: reports can be linked to one installation across updates.

At most once per UTC day, Pokelet attempts to send that digest, the public app identifier, the version and build, and an event indicating first participation or later activity. Failed attempts are dropped. Reports exclude screen contents, pointer activity and other apps. The receiving infrastructure processes your IP address transiently to deliver the request. TelemetryDeck says its app analytics do not retain the IP or derive location from it. The service assigns a receipt time and says it hashes the digest again. [Provider privacy FAQ](https://telemetrydeck.com/faq/privacy/)

## Stop sharing

Turn off **Share basic usage** or use **Reset Settings…**. Pokelet cancels pending delivery and clears the local code and consent record. It keeps the last attempt day to prevent a duplicate report. A material notice revision also clears obsolete consent and its code. Reporting then requires a fresh opt-in with a new code. Withdrawal applies going forward. It cannot recall reports already received or change the lawfulness of earlier processing.

## Rights and complaints

Email [Sam McNab](mailto:sam@sammcnab.co.uk) to request access, correction, erasure, restriction or portability where applicable. Describe what you want to do. Please keep private identifiers out of public GitHub issues.

There is no account directory connecting an email address to an installation. Article 11 allows Sam to avoid collecting extra identity data solely to identify you. If Sam can demonstrate that he cannot identify your records, he will explain this where possible. In those circumstances the rights in Articles 15–20 may be limited. If you provide information that enables identification, Sam will assess the request and the rights that apply. You can still withdraw consent and complain. [UK GDPR Article 11](https://www.legislation.gov.uk/eur/2016/679/article/11)

To complain, email the same address with what happened and how you would like Sam to respond. Sam will acknowledge receipt within 30 days, investigate without undue delay, keep you informed and explain the outcome. If you remain dissatisfied you can complain to the [UK Information Commissioner’s Office](https://ico.org.uk/make-a-complaint/) or your applicable supervisory authority.

## Details pending TelemetryDeck’s response

| Topic | To confirm before publication |
| --- | --- |
| Processor arrangements | [Confirm each party’s role for the Ingest API, applicable Article 28 terms and subprocessors.] |
| Hosting and transfers | [Confirm ingestion, storage, support and onward access locations, including any transfer safeguards.] |
| Raw events | [Confirm retention and deletion in active and cold storage. Dashboard visibility alone does not establish expiry.] |
| Backups | [Confirm expiry, restore handling and how deletions are reapplied.] |
| Individual rights | [Confirm what information can establish a match, secure verification, supported actions, erasure and response procedure.] |
