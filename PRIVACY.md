# Privacy

Pokelet runs locally. The stable app requires no account, creates no analytics installation identifier and sends no usage reports. Builds configured for software updates can contact GitHub for releases.

| Feature | Data and permission |
| --- | --- |
| Pointer, Presenter Arm and click effects | Passive mouse events update the character and track click cadence in memory. Pokelet does not collect screen contents. |
| Global shortcut | macOS delivers registered shortcut events. Pokelet keeps the shortcut setting locally. |
| Click sounds | Pokelet keeps a local copy of any audio file you select, plus its filename. Reset Settings removes the copy. If you select **Interactive clicks only** and Accessibility access is already available, Pokelet checks the clicked element’s role, enabled state and available actions. These checks do not read control text or contents, and results are discarded after the click. |
| Launch at login | macOS manages the registration through Login Items. |
| Presentation Mode | Disabled in public Release builds. In local Debug acceptance sessions, an active event tap observes mouse gestures and checks key-down events for Escape. Other keys pass through. Event contents are neither written to disk nor transmitted. Accessibility is required. The option to request Input Monitoring appears only if macOS withholds events needed to verify Escape. |
| Software updates | In builds configured for signed updates, a manual check or an automatic check you opt into requests the stable or beta appcast configured for that build from GitHub Pages. Sparkle can also fetch release notes and download an update when you choose to install it. GitHub receives standard web request data such as your IP address and Sparkle’s user agent, which includes the Pokelet and Sparkle versions. Sparkle’s optional system profile is disabled. Update preferences and the last check time are stored on this Mac. |
| GitHub feedback | **Report a problem** hands your browser a GitHub form link with the app version and build, macOS version, Mac architecture and pointer mode. The information is editable before you submit the issue yourself. **Copy system information** writes the same summary to the clipboard on request. The feature request link carries no diagnostics. |

Preferences live in macOS’s local preferences store. You can reset them in **Settings → General → Reset Settings…**. Automatic update checks are managed separately under **Studio → Updates**. Remove any grants in **System Settings → Privacy & Security**. Screen recording permissions belong to the recorder you choose.

## Permissions

Ordinary pointer use requires neither Accessibility nor Input Monitoring. Interactive-only sounds use Accessibility only when access is already available; the experimental Debug acceptance path has separate permission controls.

## Website

The [website](https://smcnab1.github.io/pokelet/) remembers cursor preferences in local storage when available. It asks GitHub’s public API for release metadata to resolve the download link and caches the answer briefly in your browser tab. Click sounds start muted each time you load the page.

GitHub hosts releases, the Wiki, Discussions and issue forms. Opening those pages or submitting feedback is subject to [GitHub’s privacy statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement). The website also loads MacNative, Product Hunt and AlternativeTo listing badges from those providers; your browser makes requests to them. Pokelet does not send native app usage data to these services.
