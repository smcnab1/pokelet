# Privacy

Pokelet runs locally. It has no account, telemetry, background updater or network service.

| Feature | Data and permission |
| --- | --- |
| Pointer and click effects | Passive mouse events update the character and track click cadence in memory. Pokelet does not collect screen contents. |
| Global shortcut | macOS delivers registered shortcut events. Pokelet keeps the shortcut setting locally. |
| Click sounds | Pokelet keeps a local copy of the audio file you select, plus its filename. Reset Settings removes the copy. |
| Launch at login | macOS manages the registration through Login Items. |
| Presentation Mode | Disabled on ordinary launches. In acceptance sessions, an active event tap observes mouse gestures and checks key-down events for Escape. Other keys pass through. Event contents are neither written to disk nor transmitted. Accessibility is required. The option to request Input Monitoring appears only if macOS withholds events needed to verify Escape. |
| GitHub links | Opening a link hands it to your default browser. GitHub’s privacy policy then applies. |

Preferences live in macOS’s local preferences store. You can reset them in **Settings → General → Reset Settings…** and remove any grants in **System Settings → Privacy & Security**. Screen recording permissions belong to the recorder you choose.
