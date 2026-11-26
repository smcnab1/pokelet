# Privacy

Pokelet’s pointer features run locally and require no account. Builds configured for software updates can contact GitHub for releases.

| Feature | Data and permission |
| --- | --- |
| Pointer, Presenter Arm and click effects | Passive mouse events update the character and track click cadence in memory. Pokelet does not collect screen contents. |
| Global shortcut | macOS delivers registered shortcut events. Pokelet keeps the shortcut setting locally. |
| Click sounds | Pokelet keeps a local copy of any audio file you select, plus its filename. Reset Settings removes the copy. If you select **Interactive clicks only** and Accessibility access is already available, Pokelet checks the clicked element’s role, enabled state and available actions. These checks do not read control text or contents, and results are discarded after the click. |
| Launch at login | macOS manages the registration through Login Items. |
| Presentation Mode | Disabled in public Release builds. In local Debug acceptance sessions, an active event tap observes mouse gestures and checks key-down events for Escape. Other keys pass through. Event contents are neither written to disk nor transmitted. Accessibility is required. The option to request Input Monitoring appears only if macOS withholds events needed to verify Escape. |
| Software updates | In builds configured for signed updates, a manual check or an automatic check you opt into requests the stable or beta appcast configured for that build from GitHub Pages. Sparkle can also fetch release notes and download an update when you choose to install it. GitHub receives standard web request data such as your IP address and Sparkle’s user agent, which includes the Pokelet and Sparkle versions. Sparkle’s optional system profile is disabled. Update preferences and the last check time are stored on this Mac. |
| Usage analytics | An analytics-enabled build can send one basic usage report per UTC day if you turn on **Share basic usage**. **Share additional diagnostics** is off and unavailable. |
| GitHub feedback | **Report a problem** hands your browser a GitHub form link with the app version and build, macOS version, Mac architecture and pointer mode. The information is editable before you submit the issue yourself. **Copy system information** writes the same summary to the clipboard on request. The feature request link carries no diagnostics. |

Preferences live in macOS’s local preferences store. You can reset them in **Settings → General → Reset Settings…**. Automatic update checks are managed separately under **Studio → Updates**. Remove any grants in **System Settings → Privacy & Security**. Screen recording permissions belong to the recorder you choose.

## Optional app analytics

Open **Pokelet Studio → General → Privacy & Analytics**. **Share basic usage** starts off. You can leave it off, turn it off again in the same place, or use **Reset Settings…** to withdraw consent. Your choice does not affect the pointer or other features. Pokelet uses your consent as the lawful basis for usage reporting and its associated storage and access on your Mac.

With your permission, Pokelet creates a random installation code and keeps it and the consent record on your Mac. A report carries the code in hashed form, the Pokelet version and build, and whether this is the first report or a later day of use. TelemetryDeck assigns a timestamp and rounds it to the hour in analytics records. Reports help estimate how many installations use Pokelet and how quickly versions are adopted. Cursor activity, screen contents, other apps, chosen characters, device details and location are outside these reports. Pokelet attempts at most one report per UTC day. Failed or offline attempts are dropped.

Turning off reporting cancels pending transmission and clears the installation code and consent record. Pokelet keeps the date of its last attempt locally to prevent duplicate reporting if you opt in again. A later opt-in creates a new code. Withdrawal applies to future reporting. A request TelemetryDeck has already received cannot be recalled by the app.

### Service, retention and rights

Sam McNab is responsible for Pokelet’s usage analytics. TelemetryDeck GmbH provides the hosted analytics service. It says it hashes the installation code again and runs the service on Hetzner infrastructure in Germany and Finland. Network delivery exposes your IP address to receiving infrastructure. TelemetryDeck says it does not use it to locate app traffic or retain it in databases, logs or backups. UK adequacy regulations cover transfers to the EEA. [TelemetryDeck’s privacy FAQ](https://telemetrydeck.com/faq/privacy/) · [Service locations and agreement](https://telemetrydeck.com/faq/compliance/) · [ICO adequacy guidance](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/international-transfers/adequacy-regulations/is-the-restricted-transfer-covered-by-adequacy-regulations/)

The free plan keeps three months available in the dashboard. Older records can remain in cold storage. TelemetryDeck provides deletion by month and describes a separate backup policy for raw events. Its data agreement forms part of its terms and states that it acts outside GDPR Article 28 for data it considers anonymous. [Retention and deletion](https://telemetrydeck.com/faq/subscription/) · [Data agreement](https://telemetrydeck.com/dpa/)

Email [Sam McNab](mailto:sam@sammcnab.co.uk) about your data or to exercise applicable rights, including access, correction, erasure, restriction and portability. TelemetryDeck provides no lookup for an individual installation or single-installation deletion. If you provide information that could help identify records, Pokelet will assess the request. You can complain to the [UK Information Commissioner’s Office](https://ico.org.uk/make-a-complaint/) or your applicable data protection authority.

## Permissions

Ordinary pointer use requires neither Accessibility nor Input Monitoring. Interactive-only sounds use Accessibility only when access is already available; the experimental Debug acceptance path has separate permission controls.

## Website

The [website](https://smcnab1.github.io/pokelet/) remembers cursor preferences in local storage when available. It asks GitHub’s public API for release metadata to resolve the download link and caches the answer briefly in your browser tab. Click sounds start muted each time you load the page.

GitHub hosts releases, the Wiki, Discussions and issue forms. Opening those pages or submitting feedback is subject to [GitHub’s privacy statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement). The website also loads MacNative, Product Hunt and AlternativeTo listing badges from those providers; your browser makes requests to them. Pokelet does not send native app usage data to these services.
