# Pokelet verification

## Local 1.1 candidate

Built and checked on 20 November 2026 on Apple M2, macOS 27.3 (26C5035r), Xcode 27.2 (27B52). The bundle identifies itself as 1.1.0, build 2. The public release version will be decided after desktop acceptance.

| Check | Result |
| --- | --- |
| Xcode Debug | Build and static analysis completed with Swift warnings treated as errors. |
| `swift test -Xswiftc -warnings-as-errors` | 24 passed. Covers preference migration, geometry, cursor ownership and restoration decisions, four characters and eight palette options at 1× and 2×, true-black pixels, animation state, click cadence, presentation gesture pairing and fail-open logic, and isolated audio import. |
| `./script/package_release.sh` | Universal Release compiled. Both `arm64` and `x86_64` slices target macOS 14.0. Archive integrity, SHA-256 verification, extraction, resource decode and strict code-signature verification passed. |
| Extracted bundle | App icon present, four WAV files decoded, both MIT notices present and matching source. Ad hoc signature with hardened runtime. Developer ID signing and notarisation are pending. |
| Repository and documentation | `git diff --check`, ShellCheck, Actionlint and the local documentation link checker passed. Headless checks exercised the landing page at 1160 px in light appearance and 390 px in dark appearance. |
| Inherited source and assets | Quiet Pointer’s notice matches the upstream pinned commit. The baseline asset generators reproduced the four WAV files and the original 1024 px app icon. |
| Existing distribution | The 1.0.0 ZIP and app executable retained their original SHA-256 hashes. The new bundle, archive and checksum are in `dist/candidate/`. |

The packaging command stages the archive, validates an extracted copy and refuses to overwrite an existing output directory. Builds can be regenerated from source. ZIP bytes can vary with build metadata, so use the checksum that accompanies each archive.

## Desktop acceptance

20 November 2026. Source changes verified at `e84b28b`. Tests used an Apple M2 with one built-in Retina display, a separate Pokelet preferences profile and an isolated local browser window. Scoped native mouse and keyboard events went through the macOS event stream. The verification records the behaviour observed on that host.

| Check | Observed result |
| --- | --- |
| Settings | Opened all six panes with the pointer disabled and no permission prompt. Inspected accessibility labels and dark appearance at a compact window size and 770 × 660 points. Black showed legible body and detail on light and dark swatches for all four characters. White and Custom selection, all five intensity selections, preview controls and palette persistence were exercised. |
| Ordinary input | The browser received one left-click, one right-click, and a double-click. Dragging selected fixture text. A disposable Finder file could be selected while Companion mode was active. Control–Option–P toggled the pointer while the browser was foregrounded. Click-only mode revealed the character on a click and hid it again after the animation. |
| Cursor restoration | Captures showed the replacement’s contact point and the native arrow returning after disable. A floating click target initially exposed a bug where an occluded Settings region could still hide the cursor. The fix uses AppKit hit testing. The retest kept the arrow visible over the floating fixture and replaced it over exposed Settings. |
| Presentation denied | Without a valid Accessibility grant, the app reported Accessibility as required and withheld suppression. The existing grant referenced a different ad hoc build. After the owner authorised replacing it, macOS granted access to the staged binary. No separate Input Monitoring grant was added. |
| Presentation active | Browser click, context-click and double-click counters stayed unchanged and arrow-key slide navigation continued. Escape also reached the browser. Escape, Control–Option–T, a click on the pause symbol and terminating the exact candidate while suppression was active each restored clicks. A fixed-width status item corrected a menu bar overflow discovered during this check. The Accessibility grant was retained at the owner’s request. |
| Full-screen and capture | Companion mode followed the pointer in a full-screen Chrome window. A whole-display recording captured the native arrow, animated character and click effects. The [cropped GIF](docs/site/assets/pokelet-cursor-demo.gif) shows only the disposable test page. |
| Sounds | The Soft Tap preview command returned without an app error while click audio was muted. The app imported a valid WAV, then rejected a malformed WAV and retained the existing custom sound. Audible output and output-device changes remain unverified. |

Ordinary launches still disable Presentation Mode. The 15-minute limit, held-button drain and tap-loss recovery have headless coverage. Live expiry, revocation, and keyboard navigation to the separate **End Presentation Mode** menu action remain open. VoiceOver, native light appearance, Login Items, sleep and wake, multiple monitors, Intel and older macOS runtimes are also open. Hosted CI and Apple distribution trust have not been exercised. After testing, the original app was relaunched with Settings open and its pointer off.

## Runtime measurements

The following 1.0.0 measurements predate the candidate. They were taken on an Apple M2, macOS 27.3, at one-second intervals with `top`. They are Pokelet process metrics. WindowServer was outside the measurement.

| Historical 1.0.0 scenario | CPU | Memory |
| --- | --- | --- |
| Pointer disabled at fresh launch | 0.0% in six of seven samples, 0.3% once | 12–13 MiB in `top`. A later `ps` RSS snapshot was about 61 MiB. |
| Pointer enabled and stationary | 0.0% in six of seven samples, 0.1% once | 41 MiB in `top`, about 42 MiB `ps` RSS. |
| Mixed automated UI and drag stress | 0.0–12.1% | 38–45 MiB in `top`. |

### Controlled comparison

Measured on the same M2 at 60 Hz on 20 November 2026. Both builds used the Finger at 76 points in Original with Playful click intensity and sound muted. The isolated browser was foregrounded throughout. The baseline Settings window had been opened to enable the pointer and remained behind the browser during the enabled trials. The candidate ran without a Settings window during measurement, which limits the RSS comparison.

Each row uses 30 one-second `top` samples after discarding the first, with a separate `ps` RSS snapshot. Scripted movement targeted the browser’s harmless click target at up to 60 input events per second. Click bursts added up to five clicks per second. The figures cover the Pokelet process.

| Scenario | 1.0.0 CPU median / peak | Candidate CPU median / peak | 1.0.0 RSS | Candidate RSS |
| --- | --- | --- | --- | --- |
| Pointer disabled | 0.0% / 0.0% | 0.0% / 0.0% | 62.9 MiB | 61.2 MiB |
| Enabled, stationary | 0.0% / 0.0% | 0.0% / 0.0% | 89.4 MiB | 64.9 MiB |
| Pointer-only movement | 5.3% / 5.7% | 5.0% / 5.4% | 89.4 MiB | 62.7 MiB |
| Movement and click bursts | 5.5% / 6.1% | 5.2% / 5.6% | 70.2 MiB | 62.7 MiB |
| Sustained drag | 3.8% / 4.0% | 3.6% / 3.9% | 70.1 MiB | 60.3 MiB |

Continuous tracking accounted for most of the observed CPU in the scripted movement-and-click workload. The historical 12.1% peak came from a different, mixed UI and drag run, so that peak remains unattributed. WindowServer CPU and battery impact were outside this comparison. An earlier candidate session with Settings open recorded a separate RSS snapshot of approximately 102 MiB.
