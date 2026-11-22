# Privacy

Pokelet runs locally. It has no account, telemetry, background updater or network service.

| Feature | Data and permission |
| --- | --- |
| Pointer, Presenter Arm and click effects | Passive mouse events update the character and track click cadence in memory. Pokelet does not collect screen contents. |
| Global shortcut | macOS delivers registered shortcut events. Pokelet keeps the shortcut setting locally. |
| Click sounds | Pokelet keeps a local copy of any audio file you select, plus its filename. Reset Settings removes the copy. If you select **Interactive clicks only** and Accessibility access is already available, Pokelet checks the clicked element’s role, enabled state and available actions. These checks do not read control text or contents, and results are discarded after the click. |
| Launch at login | macOS manages the registration through Login Items. |
| Presentation Mode | Disabled in the public beta. In local Debug acceptance sessions, an active event tap observes mouse gestures and checks key-down events for Escape. Other keys pass through. Event contents are neither written to disk nor transmitted. Accessibility is required. The option to request Input Monitoring appears only if macOS withholds events needed to verify Escape. |
| GitHub feedback | **Report a problem** hands your browser a GitHub form link with the app version and build, macOS version, Mac architecture and pointer mode. The information is editable before you submit the issue yourself. **Copy system information** writes the same summary to the clipboard on request. The feature request link carries no diagnostics. |

Preferences live in macOS’s local preferences store. You can reset them in **Settings → General → Reset Settings…** and remove any grants in **System Settings → Privacy & Security**. Screen recording permissions belong to the recorder you choose.

## Release availability

Presenter Arm, **Interactive clicks only** and the in-app feedback tools described above are in the unpublished Beta 2. Ordinary pointer use in Beta 1 and Beta 2 requires neither Accessibility nor Input Monitoring.

## Website

The landing page remembers cursor preferences in your browser. It asks GitHub’s public API for release metadata to resolve the download link and caches the answer briefly in your browser tab. Click sounds start muted each time you load the page.
