# Studio acceptance and beta readiness

**21 November 2026. Public beta update on hold.** The local candidate built and passed automated checks. Run the controlled pointer and restoration checks before qualifying the update. The candidate still carries the public Beta 1 bundle version and build number. Choose a distinct release version and build before cutting the next artefact.

The starting checkout was clean at `93a7947` on `fix/native-studio`. Desktop checks ran on Apple M2, macOS 27.3 (`26C5047e`), Xcode 27.2 (`27B52`), and one built-in Retina display. They used a separate Debug bundle, preferences suite, window frame and audio directory. The Studio-only profile disables pointer activation, global shortcut registration, click suppression and Login Items changes. The Release bundle was built and inspected separately. During initial setup, the native tool relaunched the test bundle without its Studio-only flag, so default shortcut registration may have run briefly. The process was stopped and the dedicated bundle ID now enforces Studio-only mode even when started without arguments. Pointer activation and permission changes were outside the session.

**PASS** means verified at the evidence level shown. **FAIL** means a confirmed defect or failed release check. **BLOCKED** means the available desktop, tooling or credentials could not establish the result. **NOT RUN** means the check awaits approval.

## Phase 1 · Native Studio

| Feature | Status | Evidence |
| --- | --- | --- |
| Source, build and complete automated suite | PASS | Clean starting checkout. All 27 SwiftPM tests passed with warnings as errors. Xcode Debug build and analysis, universal Release build and extracted and mounted bundle smoke checks passed. |
| Studio and Quick start | PASS | First isolated launch displayed Studio with the pointer off. Opened Quick start and dismissed it with Return. The app showed no Pokelet permission prompt. |
| Character, colour and size previews | PASS | All four characters appeared in native preview state. Observed the Original selection, true Black on light and dark stages, Custom selection and its colour well, and the 44 and 132 point ends of the size slider. Outline and shadow switched off and persisted. Rendering tests cover all eight palettes on all four characters at 1× and 2×. |
| Custom tint editing and display-mode picker | BLOCKED | Custom exposed a native colour well, and the default custom swatch rendered. A newly chosen RGB value was not verified. Companion and the disabled picker in Click-only were observed. Switching into replacement and its desktop effect remain unverified here. |
| Animations pane and preview controls | PASS | Primary and secondary preview actions were exercised with the global pointer off, and the preview showed a character alongside the app cursor at the test point. Unhinged selection and the Animate on click, fast-click response, comic effects, Click-only and Reduced Motion control states were observed. The screen showed disabled intensity controls when animation was off, disabled sparkles when effects were off and disabled wobble when Reduced Motion was on. Automated tests cover all five intensities and response decisions. |
| Detailed preview motion | BLOCKED | The tool did not capture a continuous animation trace. The full set of intensity transitions, held input, rapid-click timing, wobble, sparkle output, Click-only reveal duration and macOS-level Reduce Motion were not visually established. |
| Sounds, import and volume | PASS | Selected Cartoon Pop, tested preview with live sounds off, verified Silent disabled preview and set volume to 42%. The native picker imported a valid WAV. The app rejected a malformed WAV and retained the first sound. The custom selection, name and volume survived relaunch. Bundle smoke opened all four built-in WAVs. |
| Audible sound and output recovery | BLOCKED | Built-in and custom preview calls returned without an in-app error. Audible output and device switching require a listening check. Live click sounds await Phase 2. |
| Presentation pane | PASS | Native view displayed **Unavailable in this build** and the recovery copy. The Release package check verified the absence of the Debug presentation launch flag on both architectures. Live controls are gated below. |
| General, shortcut capture and reset | PASS | Larger text and restore-state preferences changed and persisted. An unmodified key was rejected, and Control–Option–K was captured and persisted in the isolated profile. Reset reverted those settings and the shortcut to Control–Option–P. Global registration and actual startup restoration await Phase 2. |
| About | PASS | Native view displayed version 1.1.0 (2), compatibility text, privacy, credits and correctly named website, repository, releases, licence and upstream links. The GitHub prerelease was verified separately. |
| Settings persistence and relaunch | PASS | Relaunched the isolated bundle and observed Foam Finger, Custom, 44 points, outline and shadow off, click-only and reduced motion on, Unhinged, imported audio, volume, larger text, restore preference and the recorded shortcut. |
| Keyboard shortcuts and fullscreen | PASS | Command–1 to Command–6 selected their panes. Return dismissed Quick start. After the fix, Control–Command–F entered and exited native fullscreen. Captures measured 3420 × 2148 and 1872 × 1196 pixels. Command–W removed the Studio window from the tool while the candidate process stayed alive. |
| Keyboard focus, VoiceOver and accessibility | BLOCKED | AX inspection verified named navigation, selected and disabled states, labeled switches, spoken-value text for sliders, headings, recovery text and native window actions. Tab and Shift–Tab left the window focused with system Keyboard Navigation off. Full focus traversal, visible focus indication and VoiceOver speech remain unverified. |
| Window dragging, resizing and frame restoration | BLOCKED | Tool drags did not produce a verified frame change. The app relaunched at its observed 936 × 598 point window size. A physical move and resize are still needed to establish compact layout and persisted frame changes. |
| Status menu, Settings reopening and menu-bar-only usage | BLOCKED | Closing Studio left the process running. The app uses accessory activation and `LSUIElement`. The native tool lost its window target on close, so opening the macOS status item and reopening **Settings…** in that process remain unverified. |
| Updates and installation behaviour | PASS | Source and bundle review found no automatic updater or in-app install action. About exposes the GitHub Releases link. Installing an update from a downloaded DMG remains blocked below. |
| Crashes and console | PASS | Corrected isolated builds survived the exercised workflows and relaunches. The scoped unified-log query found no Pokelet error or fault in the final observation period. One earlier setup crash is recorded below. |
| Short process resource sample | PASS | Studio open and pointer off, seven one-second `top` readings showed 48 MiB displayed memory and CPU at 0.0% five times, 0.3% once and 3.5% once. Separate `ps` RSS was about 35 MiB. After closing Studio in a later candidate session, seven readings showed 0.0% CPU and 46 MiB displayed memory, with a separate RSS sample of about 101 MiB. The samples came from different processes and exclude WindowServer, active tracking and battery impact. |

## Defects and release findings

| Finding | Severity | Status | Reproduction and disposition |
| --- | --- | --- | --- |
| Larger text split intensity names mid-word | Medium | FAIL → PASS | At the default 936 × 598 point size, enable **General → Larger Studio text**, then open **Animations**. The five-column grid split “Dramatic” and “Unhinged”. Fixed by using three columns at the larger type size. A native screenshot verified both complete labels after the change. |
| Standard window shortcuts had no action | Medium | FAIL → PASS | With Studio focused before the fix, press Command–W or Control–Command–F. The window remained unchanged. Added AppKit Window menu commands. Retest removed the Studio window without terminating the process and toggled native fullscreen in both directions. |
| First isolated test build crashed before showing Studio | High for test setup | FAIL → PASS | Launch the first experimental Debug build with its app ID and `UserDefaults` suite both set to `uk.co.sammcnab.Pokelet.StudioAcceptance`. macOS returned no suite and `AppModel.init()` trapped. Assigned a distinct suite and repeated launch and relaunch successfully. This crash was introduced during acceptance setup. |
| Candidate repeats the existing beta’s bundle version | Medium, release blocker | FAIL | Compare About or the local Release `Info.plist` against Beta 1. Both are 1.1.0, build 2. The existing tag points to `8baf2c9` and the Studio candidate contains later changes. The release version and build were left for the next release decision. |

## Phase 2 · Controlled pointer plan

**Paused at check 2.** The owner approved checks 1–2. Checks 3–10 are **NOT RUN**. Use a separately staged candidate with presentation acceptance off, a disposable document and the [local input targets](../Tests/Interactive/InputTargets.html). Confirm the candidate path and PID, current permission state and initial native cursor. Keep a second terminal or owner-operated keyboard route available to quit that exact candidate. Run one numbered check at a time. After any enablement or failure, verify a visible macOS cursor and working clicks in the fixture with the overlay off. Stop if recovery is incomplete. Steps 2 and 5 establish restoration before the later tests.

### Observed results, 21 November 2026

| Check | Status | Evidence |
| --- | --- | --- |
| 1. Accessibility and Input Monitoring | PASS | The isolated Release candidate used bundle ID `uk.co.sammcnab.Pokelet.PointerAcceptance`. It started with Companion selected and the pointer off. The Privacy & Security panels showed zero Accessibility entries and two unrelated Input Monitoring entries. Counts remained the same after the cycle. No Pokelet permission prompt appeared and no grant changed. |
| 2. Companion activation, disable and click delivery | PASS | The native tool could not reach the macOS status item, so the Studio pointer switch provided the one enable–disable cycle. WindowServer reported zero candidate overlay windows before, one on, and zero after disable. One coordinate click reached the disposable WebKit fixture at each stage, taking its click count from 0 to 1, 2 and 3. Studio showed Pointer off after disable. No Pokelet error or fault appeared in the scoped log query. |
| 2. Native pointer visibility, character pixels and status menu | BLOCKED | The tool captured the fixture window and its own pointer indicator. That capture cannot establish the physical macOS pointer or the separate overlay pixels. A legacy Quartz visibility query had already returned false at baseline, and the AppKit cursor image resolved after the trial without establishing on-screen visibility. The shortcut repeat was held at the recovery gate. |

The exact candidate and fixture processes were stopped after the off state and post-disable click were observed. The dedicated acceptance preferences returned to their initial empty state. No application was replaced or installed, and no Presentation session was started.

| Test | Expected result | Recovery |
| --- | --- | --- |
| 1. Check Accessibility and Input Monitoring status with the pointer off. Begin with an isolated candidate without grants. | Passive pointer operation should not require the Debug Presentation key monitor or request those grants. Record any genuine OS prompt and stop at it. | Close the prompt, leave the pointer off and quit the candidate. Permission grants or revocations are separate owner actions. |
| 2. Enable Companion once using the status menu, disable it, then repeat using the configured shortcut. | The character appears and disappears while the native cursor and clicks remain usable. Confirm restoration before continuing. | Use **Disable Pointer**, the configured shortcut or **Quit Pokelet**. If necessary, terminate the recorded candidate PID from the backup terminal. |
| 3. Select The Finger, Cat Paw, Foam Finger and Comic Arrow one at a time. | The selected art replaces the previous character without duplicates. The native arrow stays visible in Companion. | Disable the pointer and confirm the fixture still receives clicks. Switch back to a known character with the overlay off. |
| 4. Test Original and Black for each character over light and dark fixture backgrounds. | Original colours and the visible black silhouette and details match the Studio previews. | Disable the pointer, then return to Original if needed. |
| 5. Select **Replace in Studio**. Move across exposed Studio, a covering window, menus, another app and back. Disable while the cursor is over Studio. | The overlay aligns at the click point. The native cursor is hidden only where Studio owns the hit. It returns immediately on leaving eligible content, menu tracking, disable or quit. | Disable by shortcut, or use the status menu or backup terminal. Confirm the native cursor and ordinary clicks before continuing. |
| 6. Compare Companion and Click-only over the fixture. | Companion displays an offset, persistent character. Click-only briefly reveals it after a click. The native cursor remains visible and fixture input still works. | Disable the overlay or quit. Confirm the native pointer and ordinary clicks. |
| 7. Exercise one mouse-down, hold, mouse-up, secondary click, then a short rapid-click burst. Include a sound-enabled run. | One animation per down event, no duplicate effect on release, and normal fixture counts. Rapid clicks respond to the configured intensity and click effects. Enabled sound plays once per applicable click. | Release every button, disable and verify plain clicks. If input is abnormal, quit the exact candidate. |
| 8. Switch between the disposable browser page and Finder. Test display boundaries only if a second display is available. | Focus, clicks and drags retain their normal behaviour. The overlay follows the pointer across screens without duplicates and stays within the applicable display. | Disable the overlay on the current display, or use the backup terminal. Record unavailable displays as blocked. |
| 9. Close Studio during a replacement check, reopen it from the status menu, then quit normally in a separate run. | Closing restores the native cursor over the former window area and leaves the status menu usable. Quitting removes the overlay and restores the native cursor and clicks. | Use the configured shortcut or **Quit Pokelet**. If Pokelet is unresponsive, terminate the recorded PID. |
| 10. Relaunch with restore-state off, then test opt-in restoration separately. Only after prior recovery passes, terminate the exact candidate unexpectedly while it owns the cursor. | Normal relaunch stays off by default and restores only opted-in pointer state. On unexpected termination, the native cursor and normal clicks return; relaunching creates one overlay if opted in. | Use the backup terminal for the exact process. Relaunch only after the desktop is usable, clear restore-state and disable the pointer before ending the trial. |

## Phase 3 · Presentation and emergency recovery

Every live item remains **NOT RUN** until Phase 2 passes and the owner approves Phase 3 separately.

| Feature | Status | Acceptance condition |
| --- | --- | --- |
| Activation and click interception | NOT RUN | Only the designated Debug candidate can arm the tap after permission and recovery checks. The disposable fixture receives no intercepted clicks, and keyboard slide navigation continues. |
| Escape and Control–Option–T | NOT RUN | Use one activation per exit method. Verify ordinary click delivery after each one. |
| Restore clicks action | NOT RUN | Test the menu bar indicator and the separate **End Presentation Mode** command in distinct activations. **Restore clicks** is the pane’s recovery heading. |
| App termination during presentation | NOT RUN | Terminate the exact candidate only after ordinary stop routes pass. Verify mouse and pointer recovery immediately. |
| Error or unexpected interruption | NOT RUN | Verify tap loss, permission loss, session inactivity, expiry and held-button exit individually. Confirm no stuck button or continued suppression. |

## Phase 4 · Release audit

| Check | Status | Evidence |
| --- | --- | --- |
| Apple silicon and newer macOS | PASS | Actual Studio runtime on M2 and macOS 27.3. The runtime evidence is from the isolated Debug bundle. |
| Universal binary and macOS 14 minimum | PASS | Release ZIP contains `arm64` and `x86_64`, both with `LC_BUILD_VERSION` minimum macOS 14.0. The navigation material uses an availability-guarded macOS 26 path with a fallback. |
| Intel and macOS 14 runtime | BLOCKED | No Intel or macOS 14 desktop was available. Target metadata and fallback source review establish build compatibility. |
| Permissions and entitlements | PASS | Both Release slices passed strict signature checks and the test excluding `get-task-allow` and Debug acceptance flags. Pointer monitoring handles mouse events. Debug Presentation is the path that requests Accessibility and conditionally Input Monitoring. Actual grant and recovery checks are gated. |
| Signing and notarisation | PASS | Ad hoc hardened-runtime signatures verified for both slices and inside the read-only test DMG. The repository has a local Developer ID signing and notarisation workflow. |
| Trusted distribution | BLOCKED | No valid Developer ID Application identity was available. Notary submission, stapling and Gatekeeper acceptance of a trusted download remain unverified. [Apple distribution guidance](https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution) |
| First-run onboarding and defaults | PASS | Fresh local Debug Studio started pointer off with Companion, Original, The Finger and muted sounds. Quick start was accessible. Automated coverage verifies preference migration, corrupt data recovery and defaults. |
| Quarantined install or upgrade | BLOCKED | Existing beta download matched the published checksum. The staged candidate DMG mounted read-only and verified its Applications shortcut, executable and resources. First launch through Gatekeeper and an in-place update require a separate clean desktop. [Apple Gatekeeper guidance](https://support.apple.com/102445) |
| Launch at login | NOT RUN | Static review found `SMAppService.mainApp` status, registration, removal and approval handling. Registration, OS approval, login relaunch and removal change account-level state and await separate authorisation. [Apple Service Management documentation](https://developer.apple.com/documentation/servicemanagement/smappservice) |
| Privacy and security | PASS | Source review matched the documented local data model. Preferences and imported audio stay on the Mac, and About links open in the browser. The release workflow uses no background updater or telemetry. See the [privacy statement](../PRIVACY.md). |
| Active CPU, memory and energy | NOT RUN | Pointer-enabled workload awaits Phase 2. The Phase 1 sample cannot measure WindowServer or battery effects. |
| GitHub packaging | PASS | Verified [the Beta 1 prerelease](https://github.com/smcnab1/pokelet/releases/tag/v1.1.0-beta.1), its tag commit, the downloaded DMG and SHA-256 file, and the mounted Beta 1 bundle. The local workflow verified ZIP integrity and resources, both architectures, and read-only DMG layout. |
| Next release version | FAIL | Bundle version and build still match Beta 1. |
| Exact-commit CI | BLOCKED | The local fixes and report have no remote CI run. |

## Reproduce the Studio-only session

```sh
xcodebuild -quiet -project Pokelet.xcodeproj -scheme Pokelet -configuration Debug \
  -destination "platform=macOS,arch=$(uname -m)" -derivedDataPath build/studio-acceptance \
  PRODUCT_BUNDLE_IDENTIFIER=uk.co.sammcnab.Pokelet.StudioAcceptance \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
open -n build/studio-acceptance/Build/Products/Debug/Pokelet.app --args --studio-acceptance
```

This profile accepts and persists a shortcut value for testing without registering it. The app and preferences suite identifiers are distinct. Release packaging rejects the Debug acceptance flags.
