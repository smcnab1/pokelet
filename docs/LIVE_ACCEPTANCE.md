# Studio acceptance and beta readiness

**21 November 2026. Public beta update on hold.** Companion, Click-only and Replace in Studio passed controlled input and recovery checks on one Apple silicon Mac. Cross-display verification remains open. The current candidate still has Beta 1's bundle version and build number.

The starting checkout was clean at `93a7947` on `fix/native-studio`. Desktop checks ran on Apple M2, macOS 27.3 (`26C5047e`), Xcode 27.2 (`27B52`), and one built-in Retina display. They used a separate Debug bundle, preferences suite, window frame and audio directory. The Studio-only profile disables pointer activation, global shortcut registration, click suppression and Login Items changes. The Release bundle was built and inspected separately. During initial setup, the native tool relaunched the test bundle without its Studio-only flag, so default shortcut registration may have run briefly. The process was stopped and the dedicated bundle ID now enforces Studio-only mode even when started without arguments. Pointer activation and permission changes were outside the session.

**PASS** means verified at the evidence level shown. **FAIL** means a confirmed defect or failed release check. **BLOCKED** means the available desktop, tooling or credentials could not establish the result. **NOT RUN** means the check was deferred, including checks that still need approval.

## Menu bar and Dock follow-up · 21 November 2026

The baseline was `4162781`. It created and retained one native status item. On this Mac, it had `isVisible == true` while its AppKit host frame was 38 × 0 points and there was no accessible Pokelet item to click. A fresh bundle ID, an explicit visibility request, a stable name, different widths, a system-symbol image and regular activation each failed to reveal it. After Thaw quit, the instrumented baseline had a 38 × 38 point host frame. The remaining Vorssaint notch overlay occupied that position on this display. With both tools briefly paused, the candidate displayed its template hand and its native menu. Both tools were relaunched after testing. Thaw documents that new items can start in a hidden section. [Thaw’s placement guidance](https://www.getthaw.app/docs/thaw/frequent-issues)

Pokelet retains a named `NSStatusItem` independently of Studio. If AppKit reports that it is hidden or has no usable frame, Pokelet keeps a Dock route. The app also handles Finder and Dock reopen events. The previous bundle launched as an `LSUIElement` agent. In the first candidate, Finder remained active even after Studio opened. The final bundle launches as a regular app so Finder can give it focus. AppKit switches it to accessory activation once Studio is closed and the menu bar is available, according to the saved preferences. The status item stays registered during ordinary Studio transitions. macOS can hide an item for space even when `isVisible` is true, and another app can cover a frame that AppKit reports as onscreen. [Apple’s status-item visibility documentation](https://developer.apple.com/documentation/appkit/nsstatusitem/isvisible)

| Check | Result | Evidence |
| --- | --- | --- |
| Defaults, migration and policy | PASS · automated | 32 SwiftPM tests passed with warnings as errors. New cases cover default visibility, repeated policy decisions, the Dock fallback, persistence and reset, and decoding old preferences without losing existing values. A native smoke test also opened and closed Studio three times using Launch Services and the close button, checked the original PID and single window, then verified termination. |
| Native status menu and Dock lifecycle | PASS · observed | The native menu displayed **Open Pokelet Studio**, **Enable Pointer**, **Pointer Style**, **Animation Intensity**, **Click Sounds**, **Presentation Settings…** and **Quit Pokelet**. Across three Command–W and status-menu reopen cycles, the same process ran with one status item. The Dock item disappeared on close and returned with one focused Studio window. |
| Finder launch, appearance and Dock Quit | PASS · observed | Finder launched and focused the final Release bundle. Finder also reopened Studio in the same process after its Dock icon disappeared. General and the native status menu rendered in Light and Dark. The Dock context menu’s **Quit** command terminated Pokelet. The previous system appearance was restored. |
| Menu bar unavailable | PASS · observed | With Thaw and Vorssaint running, the Release candidate started in the background without a visible status item. It kept its Dock icon, and clicking it opened and focused one Studio window. |
| Visibility preferences, minimise and relaunch | PASS · observed | Disabling automatic Dock hiding kept both access routes available after close. Disabling the status item left the Dock usable and disabled the dependent setting. Dock clicks reopened closed Studio and restored minimised Studio. Command–Q terminated the process. A `--background` relaunch preserved the Dock-only configuration and left Studio closed. Switching the menu bar back on restored the prior Dock hiding preference. The status menu quit also terminated the process. |
| Companion with Studio closed | PASS · observed after owner approval | Enabled Companion in the status menu. The overlay had the same WindowServer ID before and after Command–W, with Studio closed and the Dock icon absent. The cursor capture showed the native arrow alongside the character. The status menu removed the overlay, reopened Studio and restored the Dock icon. A second enable followed by **Quit Pokelet** removed the process and overlay. The native arrow was visible after disable and after quit. The disposable input fixture counted all four test clicks. |
| Global shortcut with Studio closed | PASS · observed after owner approval | Two desktop-generated Option–Command–P keypresses enabled and disabled the overlay while the Release candidate was running as an accessory with Studio closed. |
| Build and bundle | PASS · automated | Debug build and universal Release build and analysis passed with warnings as errors. Strict signature verification and bundle smoke passed. Both slices declare macOS 14.0. Bundle version stayed at 1.1.0 (2). |
| Installed application | BLOCKED | `/Users/sammcnab/Applications/Pokelet.app` was absent. A separate bundle in the Trash was inspected read-only. The runnable candidate had its own bundle ID and settings domain. |
| Actual login and minimum-OS runtime | NOT RUN | The background command-line path was exercised. The login Apple Event path was implemented using Apple’s launch marker. No login item registration or actual login was exercised. This desktop ran macOS 27.3 on Apple silicon. [Apple’s login launch event marker](https://developer.apple.com/documentation/coreservices/1556410-launch_apple_event_constants/keyaelaunchedasloginitem) |

The Companion result above was observed on the isolated candidate using desktop automation. The owner authorised that test. The prior owner-operated shortcut results below apply to the earlier builds. Presentation Mode was never started in this follow-up.

To confirm the ordinary desktop setup after installation, show Pokelet in your menu bar manager if one is in use. Open its status menu, choose **Open Pokelet Studio**, close with Command–W and reopen from the status menu. If the item is covered or hidden by a desktop utility, reopen Pokelet in Finder and use **General → Application behaviour** to keep the Dock icon visible while testing.

## Phase 1 · Native Studio

The table below preserves the original Studio evidence. The [additional Studio checks](#additional-studio-checks--21-november-2026) record the latest results for previously blocked items.

| Feature | Status | Evidence |
| --- | --- | --- |
| Source, build and complete automated suite | PASS | Clean starting checkout. All 27 initial SwiftPM tests and all 28 after the default shortcut change passed with warnings as errors. Xcode Debug build and analysis, universal Release build and extracted and mounted bundle smoke checks passed. |
| Studio and Quick start | PASS | First isolated launch displayed Studio with the pointer off. Opened Quick start and dismissed it with Return. The app showed no Pokelet permission prompt. |
| Character, colour and size previews | PASS | All four characters appeared in native preview state. Observed the Original selection, true Black on light and dark stages, Custom selection and its colour well, and the 44 and 132 point ends of the size slider. Outline and shadow switched off and persisted. Rendering tests cover all eight palettes on all four characters at 1× and 2×. |
| Custom tint editing and display-mode picker | BLOCKED | Custom exposed a native colour well, and the default custom swatch rendered. A newly chosen RGB value was not verified. Companion and the disabled picker in Click-only were observed. Switching into replacement and its desktop effect remain unverified here. |
| Animations pane and preview controls | PASS | Primary and secondary preview actions were exercised with the global pointer off, and the preview showed a character alongside the app cursor at the test point. Unhinged selection and the Animate on click, fast-click response, comic effects, Click-only and Reduced Motion control states were observed. The screen showed disabled intensity controls when animation was off, disabled sparkles when effects were off and disabled wobble when Reduced Motion was on. Automated tests cover all five intensities and response decisions. |
| Detailed preview motion | BLOCKED | The tool did not capture a continuous animation trace. The full set of intensity transitions, held input, rapid-click timing, wobble, sparkle output, Click-only reveal duration and macOS-level Reduce Motion were not visually established. |
| Sounds, import and volume | PASS | Selected Cartoon Pop, tested preview with live sounds off, verified Silent disabled preview and set volume to 42%. The native picker imported a valid WAV. The app rejected a malformed WAV and retained the first sound. The custom selection, name and volume survived relaunch. Bundle smoke opened all four built-in WAVs. |
| Audible sound and output recovery | BLOCKED | Built-in and custom preview calls returned without an in-app error. Audible output and device switching require a listening check. Live click sounds await Phase 2. |
| Presentation pane | PASS | Native view displayed **Unavailable in this build** and the recovery copy. The Release package check verified the absence of the Debug presentation launch flag on both architectures. Live controls are gated below. |
| General, shortcut capture and reset | PASS | Larger text and restore-state preferences changed and persisted. An unmodified key was rejected, and Control–Option–K was captured and persisted in the isolated profile. Reset restored the build’s default shortcut. Control–Option–P was the default in that build. The new Option–Command–P default and saved-shortcut preservation have automated coverage. |
| About | PASS | Native view displayed version 1.1.0 (2), compatibility text, privacy, credits and correctly named website, repository, releases, licence and upstream links. The GitHub prerelease was verified separately. |
| Settings persistence and relaunch | PASS | Relaunched the isolated bundle and observed Foam Finger, Custom, 44 points, outline and shadow off, click-only and reduced motion on, Unhinged, imported audio, volume, larger text, restore preference and the recorded shortcut. |
| Keyboard shortcuts and fullscreen | PASS | Command–1 to Command–6 selected their panes. Return dismissed Quick start. After the fix, Control–Command–F entered and exited native fullscreen. Captures measured 3420 × 2148 and 1872 × 1196 pixels. Command–W removed the Studio window from the tool while the candidate process stayed alive. |
| Keyboard focus, VoiceOver and accessibility | BLOCKED | AX inspection verified named navigation, selected and disabled states, labeled switches, spoken-value text for sliders, headings, recovery text and native window actions. Tab and Shift–Tab left the window focused with system Keyboard Navigation off. Full focus traversal, visible focus indication and VoiceOver speech remain unverified. |
| Window dragging, resizing and frame restoration | BLOCKED | Tool drags did not produce a verified frame change. The app relaunched at its observed 936 × 598 point window size. A physical move and resize are still needed to establish compact layout and persisted frame changes. |
| Status menu, Settings reopening and menu-bar-only usage | BLOCKED · earlier build | Closing Studio left the process running. The earlier native tool lost its window target on close. The follow-up above verified the native menu and Studio reopening in the new candidate. |
| Updates and installation behaviour | PASS | Source and bundle review found no automatic updater or in-app install action. About exposes the GitHub Releases link. Installing an update from a downloaded DMG remains blocked below. |
| Crashes and console | PASS | Corrected isolated builds survived the exercised workflows and relaunches. The scoped unified-log query found no Pokelet error or fault in the final observation period. One earlier setup crash is recorded below. |
| Short process resource sample | PASS | Studio open and pointer off, seven one-second `top` readings showed 48 MiB displayed memory and CPU at 0.0% five times, 0.3% once and 3.5% once. Separate `ps` RSS was about 35 MiB. After closing Studio in a later candidate session, seven readings showed 0.0% CPU and 46 MiB displayed memory, with a separate RSS sample of about 101 MiB. The samples came from different processes and exclude WindowServer, active tracking and battery impact. |

### Additional Studio checks · 21 November 2026

The RGB and audio checks used the isolated Release candidate. Window, focus and preview checks used a fresh Debug build of `3269ef0` with the Studio-only profile. Its pointer switch remained disabled and off.

| Check | Status | Evidence |
| --- | --- | --- |
| Custom RGB persistence | PASS | Entered `#298AD1` in the native RGB colour panel. The colour well reported the matching sRGB values before and after relaunch, and the stored custom value was `0x298AD1`. |
| Detailed preview behaviour | PASS · sampled | Native preview captures showed the initial held-click effect, settling before release, and a secondary-click ring. Bursts exercised all five intensities and produced celebration sparkles. Click-only revealed the artwork then returned to its hidden tracking state. A quick reversal produced a wobble. Studio’s Reduced Motion setting produced a brief ring and disabled wobble. The macOS Reduce Motion setting and full animation timing remain BLOCKED. |
| Dragging and frame restoration | PASS · desktop automation | A title-area drag moved Studio 38 points horizontally. After resizing and positioning, quit and relaunch restored the exact 742 × 520 point window frame at (309, 230). |
| Keyboard focus and VoiceOver | BLOCKED | With macOS Keyboard Navigation off, Tab and Shift–Tab left focus on the Studio window. The earlier accessibility inspection verified control labels and states. Full traversal, visible focus and spoken output still need a desktop session with Keyboard Navigation and VoiceOver enabled. |
| Reduced Transparency | BLOCKED · live setting | Source review confirmed the macOS accessibility value selects a solid sidebar surface with a border. Earlier forced-branch captures show that material. The host reported Reduced Transparency off, and the system preference stayed in that state. |
| Preview audio and volume | PASS · digital output | The process-scoped sample in Phase 2 captured sound preview while live click sounds were off and measured the expected volume change. Listening and switching output devices remain BLOCKED. |
| Preview CPU and memory | PASS · sampled | Same Studio-only Debug PID, eight one-second `top` samples per workload after discarding the first. Idle CPU median/peak was 0.0%/4.7%. Under repeated six-click preview bursts it was 4.1%/4.7%. Displayed memory stayed about 43 MiB and separate RSS snapshots were about 103 MiB. The sample measures the Pokelet process. |

## Defects and release findings

| Finding | Severity | Status | Reproduction and disposition |
| --- | --- | --- | --- |
| Larger text split intensity names mid-word | Medium | FAIL → PASS | At the default 936 × 598 point size, enable **General → Larger Studio text**, then open **Animations**. The five-column grid split “Dramatic” and “Unhinged”. Fixed by using three columns at the larger type size. A native screenshot verified both complete labels after the change. |
| Standard window shortcuts had no action | Medium | FAIL → PASS | With Studio focused before the fix, press Command–W or Control–Command–F. The window remained unchanged. Added AppKit Window menu commands. Retest removed the Studio window without terminating the process and toggled native fullscreen in both directions. |
| First isolated test build crashed before showing Studio | High for test setup | FAIL → PASS | Launch the first experimental Debug build with its app ID and `UserDefaults` suite both set to `uk.co.sammcnab.Pokelet.StudioAcceptance`. macOS returned no suite and `AppModel.init()` trapped. Assigned a distinct suite and repeated launch and relaunch successfully. This crash was introduced during acceptance setup. |
| Candidate repeats the existing beta’s bundle version | Medium, release blocker | FAIL | Compare About or the local Release `Info.plist` against Beta 1. Both are 1.1.0, build 2. The existing tag points to `8baf2c9` and the Studio candidate contains later changes. The release version and build were left for the next release decision. |

## Phase 2 · Controlled pointer acceptance

Checks 1–2 and the menu-bar and Dock follow-up are prior accepted evidence. This session resumed at check 3 on source commit `3269ef0` on `fix/native-studio`, which differs from `064de79` only in this record. The owner approved Companion and Click-only first, then separately approved Replace in Studio. Presentation remains a separate phase.

### Companion and Click-only follow-up · 21 November 2026

The isolated Release candidate used bundle ID `uk.co.sammcnab.Pokelet.LifecycleAcceptance` and executable SHA-256 `3c251e97e88e12a8a6d5bd334281ea1eb068ea153fdd584981315e07414b6816`. It ran on the M2 Mac with one built-in Retina display. The disposable WebKit fixture loaded the existing [local input targets](../Tests/Interactive/InputTargets.html). A local copy of its wrapper provided per-window light and dark backgrounds and recorded events on the target. Desktop automation sent input to the verified fixture or Studio windows. Cursor captures, the fixture counters and WindowServer overlay counts established recovery. Local logs and captures are in `build/pointer-phase2/`.

| Check | Status | Evidence |
| --- | --- | --- |
| Focused automated tests | PASS | 20 SwiftPM tests passed with warnings as errors. They cover cursor ownership and restore retries, geometry, artwork, colour persistence, audio import and Presentation fail-open logic. The earlier 32-test suite and universal build results remain in the record above. |
| 3–4. Live characters and palettes | PASS | Captured all 24 combinations of The Finger, Cat Paw, Foam Finger and Comic Arrow in Original, Black and Custom `#298AD1` against light and dark backgrounds. Each capture showed one character alongside the native arrow. Disabling removed the overlay and the next fixture click arrived. |
| 6. Companion and Click-only | PASS | Companion stayed visible between clicks. In Click-only, captures showed the native arrow before the click, the character and arrow immediately after, and the arrow alone 1.2 seconds later. The click and the first post-disable click both reached the fixture. |
| 7. Click phases and intensity | PASS · sampled | The held primary gesture produced an early effect. The effect settled before release, the Click counter stayed unchanged during the hold, and release delivered exactly one click without a second visible effect in the post-release capture. One secondary click delivered a context event. Six clicks at each of the five intensities added 30 primary clicks. Captures sampled differing motion and comic marks. |
| 7. Audio and ordinary input | PASS · digital output | Process-scoped audio capture detected Cartoon Pop for both preview and live fixture clicks at 15% and 70%, with normalised peaks near 0.058 and 0.272 respectively. The 0% run produced no signal above 0.0001. All three live clicks reached the fixture and a post-disable click arrived with the native cursor visible. Physical audibility and output-device switching remain BLOCKED. |
| 8. App switching and display edges | PASS · one display | The same overlay survived WebKit → Finder → WebKit. At the left and right edges the character stayed inside the built-in display and the native cursor remained visible. A fixture click arrived after disabling each run. Cross-display transitions are BLOCKED because only one display was available. |
| 9. Companion Studio lifecycle | PASS · prior | Retains the approved Studio-closed, reopen and normal quit evidence in the menu-bar and Dock follow-up above. |
| 10. Restore state and exit in Companion | PASS | Normal quit restored ordinary input. With restore off, relaunch stayed off. With restore on, both a normal quit and an unexpected exit of the verified candidate PID restored the native cursor and fixture clicks. Both opt-in relaunches created exactly one overlay. The session ended with pointer and restore off, zero overlays and a working fixture click. |

### Replace in Studio follow-up · 21 November 2026

Used the same Release candidate with restore-state off and a timed backup quit tied to the verified PID. Captured the native arrow and recorded the first fixture click after each operation. The first close run used the backup quit when the fixture’s accessibility tree was still loading. The close test was repeated after adding a readiness check to the local harness.

| Check | Status | Evidence |
| --- | --- | --- |
| 5. Alignment and eligible content | PASS | Over exposed Studio content the replacement tip aligned with the recorded pointer coordinate. Rechecked Comic Arrow at 44, 76 and 132 points and The Finger at 76 points. The native arrow stayed visible over a floating WebKit target while Studio remained the active key window, over the app menu, outside Studio, and in the foreground fixture. A click reached the covering fixture. |
| 5. Disable inside Studio | PASS | Disabled while the pointer was still over eligible Studio content. The native arrow reappeared at that position, overlay count went to zero and the first fixture click arrived. |
| 9. Close and reopen | PASS | Command–W removed Studio and restored the native arrow immediately while the overlay stayed active. The fixture received a click. Launch Services reopened Studio in the same PID. Disabling returned the overlay count to zero and the next fixture click arrived. |
| 9. Normal termination | PASS | Before quit, a capture showed The Finger at the Studio pointer position. Normal quit removed the process and overlay. A native arrow capture and the fixture’s next click verified recovery. |
| 10. Unexpected termination | PASS | Sent SIGKILL to the verified candidate PID while Studio owned the native cursor hide. A post-exit capture showed the native arrow and the fixture counter advanced by one. Relaunch with restore off showed Pointer off and zero overlays. |

No pointer defect was confirmed in these controlled runs. No application code or regression tests changed. The candidate and fixture processes were stopped and the isolated settings domains were restored.

### Earlier checks 1–2 · 21 November 2026

| Check | Status | Evidence |
| --- | --- | --- |
| 1. Accessibility and Input Monitoring | PASS | The isolated Release candidate used bundle ID `uk.co.sammcnab.Pokelet.PointerAcceptance`. It started with Companion selected and the pointer off. The Privacy & Security panels showed zero Accessibility entries and two unrelated Input Monitoring entries. Counts remained the same after the cycle. No Pokelet permission prompt appeared and no grant changed. |
| 2. Companion activation, disable and click delivery | PASS | The native tool could not reach the macOS status item, so the Studio pointer switch provided the one enable–disable cycle. WindowServer reported zero candidate overlay windows before, one on, and zero after disable. One coordinate click reached the disposable WebKit fixture at each stage, taking its click count from 0 to 1, 2 and 3. Studio showed Pointer off after disable. No Pokelet error or fault appeared in the scoped log query. |
| 2. Physical shortcut, native cursor and recovery | PASS | The owner confirmed initial recovery and then physically exercised Control–Option–P. The owner confirmed that The Finger appeared beside the native cursor and that the native cursor and clicks were usable after disable. WindowServer recorded two complete transitions from zero to one overlay and back to zero. The automated key delivery did not trigger the global shortcut. |
| 2. New default shortcut | PASS | A fresh isolated Release build displayed Option–Command–P without a shortcut registration warning. The owner physically verified that the new shortcut showed and removed The Finger while the native pointer and clicks remained usable. WindowServer again reported zero, one and zero overlays, and Studio showed Pointer off. The regression test verified the new default after reset and preservation of a saved Control–Option–P binding. |
| 2. Status menu activation and disable | BLOCKED | The desktop tool did not expose the status item, and the owner reported that the icon or commands were unavailable during a separate physical attempt. The candidate recorded zero overlays throughout that attempt. The observations do not distinguish menu bar placement from a candidate defect. The Studio switch and physical shortcut have separate passing evidence. |

The exact candidate and fixture processes were stopped after the off state and post-disable click were observed. The dedicated acceptance preferences returned to their initial empty state. No application was replaced or installed, and no Presentation session was started.

### Reuse the controlled pointer checks

Get owner approval for Companion and Click-only, and separate approval for replacement. Use the verified Release candidate and disposable fixture with a second keyboard-accessible quit route. Start with the native pointer and fixture click baseline, with restore-state off. Use one activation per recovery route. After each run, verify a visible native cursor and a fixture click with the overlay off. Stop if either fails. Test unexpected exit only after disable, close and normal quit each restore input.

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

Every live item remains **NOT RUN**. After ordinary pointer acceptance, get independent owner approval for this session and for any permission changes. Use only a separate Debug candidate launched with `--settings --acceptance-profile --presentation-acceptance`. Start with the native cursor, the disposable fixture and a verified click. Confirm the candidate's exact PID, that an operator can reach Escape and Control–Option–T, and that a backup terminal can quit the process by keyboard. Establish a visible, reachable status indicator before testing its exit route. Run a fresh activation for each exit. Verify the native cursor and a fixture click after every stop and abort the session if either fails to recover.

| Feature | Status | Acceptance condition |
| --- | --- | --- |
| Permission denied and activation guards | NOT RUN | Attempt startup without Accessibility and record the actual Input Monitoring requirement. Confirm denial, a held button or an unavailable recovery shortcut leaves clicks working. Grant only the permission the owner separately authorises. |
| Active input | NOT RUN | Establish that the fixture receives left, right and other-button events before arming. While active, monitor the counters and the fixture’s button-event log for suppressed clicks. The pointer responds and arrow keys still advance the fixture slides. |
| Escape and Control–Option–T | NOT RUN | Exercise both keyboard exits separately. The fixture also receives the Escape key. After each exit, verify the first ordinary click. |
| Menu-bar indicator and keyboard menu command | NOT RUN | Test the indicator and keyboard navigation to **End Presentation Mode** in distinct activations. |
| Held-button exit | NOT RUN | End during a held gesture, release it and check that the next down/up pair arrives normally with no stuck drag. Check rapid stop/start independently. |
| Expiry, tap loss and session inactivity | NOT RUN | Observe the full 15-minute expiry. Separately exercise an agreed interruption and permission revocation. The session ends, input resumes and returning to the app leaves suppression off. |
| App termination during Presentation | NOT RUN | Use the verified candidate PID after the ordinary exit routes pass. Confirm immediate mouse and pointer recovery. Restore only the permissions changed for the approved session. |

## Phase 4 · Release audit

| Check | Status | Evidence |
| --- | --- | --- |
| Apple silicon and newer macOS | PASS | Actual Studio runtime on M2 and macOS 27.3. The runtime evidence is from the isolated Debug bundle. |
| Universal binary and macOS 14 minimum | PASS | Release ZIP contains `arm64` and `x86_64`, both with `LC_BUILD_VERSION` minimum macOS 14.0. The navigation material uses an availability-guarded macOS 26 path with a fallback. |
| Intel and macOS 14 runtime | BLOCKED | No Intel or macOS 14 desktop was available. Target metadata and fallback source review establish build compatibility. |
| Permissions and entitlements | PASS | Both Release slices passed strict signature checks and the test excluding `get-task-allow` and Debug acceptance flags. Pointer monitoring handles mouse events. Debug Presentation is the path that requests Accessibility and conditionally Input Monitoring. Actual grant and recovery checks are gated. |
| Ad hoc bundle signing | PASS | Ad hoc hardened-runtime signatures verified for both Release slices and inside the prior read-only test DMG. The staged replacement candidate passed strict signature verification again. |
| Developer ID, notarisation and Gatekeeper | BLOCKED | A local Keychain identity check found an Apple Development identity. Developer ID Application credentials, notary submission, stapling and Gatekeeper acceptance of a trusted download remain open. [Apple distribution guidance](https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution) |
| First-run onboarding and defaults | PASS | Fresh local Debug Studio started pointer off with Companion, Original, The Finger and muted sounds. Quick start was accessible. Automated coverage verifies preference migration, corrupt data recovery and defaults. |
| Quarantined first install and Beta 1 upgrade | BLOCKED | The previous Beta 1 download still matches its SHA-256 file. The earlier read-only candidate mount verified layout and resources. On a clean Mac or VM, test first install with browser quarantine, then upgrade a disposable Beta 1 profile and verify preserved character, custom RGB, sound, shortcut, window frame and pointer restore preference. Confirm one running copy and ordinary input recovery. [Apple Gatekeeper guidance](https://support.apple.com/102445) |
| Launch at login | NOT RUN | Static review found `SMAppService.mainApp` status, registration, removal and approval handling. Registration, OS approval, login relaunch and removal change account-level state and await separate authorisation. [Apple Service Management documentation](https://developer.apple.com/documentation/servicemanagement/smappservice) |
| Privacy and security | PASS | Source review matched the documented local data model. Preferences and imported audio stay on the Mac, and About links open in the browser. The release workflow uses no background updater or telemetry. See the [privacy statement](../PRIVACY.md). |
| Active pointer resource use | NOT RUN | This session exercised pointer functionality. A paired pointer-active CPU and memory workload and WindowServer or energy measurement remain open for the current candidate. |
| GitHub packaging | PASS | Verified [the Beta 1 prerelease](https://github.com/smcnab1/pokelet/releases/tag/v1.1.0-beta.1), its tag commit, the downloaded DMG and SHA-256 file, and the mounted Beta 1 bundle. The local workflow verified ZIP integrity and resources, both architectures, and read-only DMG layout. |
| Next release version | FAIL | Beta 1 and the candidate are both `1.1.0 (2)`. Recommend `v1.2.0-beta.1` with bundle version `1.2.0` and build `3` for the Studio redesign and new Dock controls. Version metadata is unchanged. |
| Exact-commit CI | BLOCKED | GitHub Actions returned zero runs for `3269ef0f41db535855a803ee71b42f2cbc4c7a6e`. Beta 1’s successful run belongs to `8baf2c994811429ca366e8d0352cf6e104150813`. Run the macOS workflow on the eventual release commit. [Beta 1 CI](https://github.com/smcnab1/pokelet/actions/runs/44760173269) |

## Reproduce the Studio-only session

```sh
xcodebuild -quiet -project Pokelet.xcodeproj -scheme Pokelet -configuration Debug \
  -destination "platform=macOS,arch=$(uname -m)" -derivedDataPath build/studio-acceptance \
  PRODUCT_BUNDLE_IDENTIFIER=uk.co.sammcnab.Pokelet.StudioAcceptance \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
open -n build/studio-acceptance/Build/Products/Debug/Pokelet.app --args --studio-acceptance
```

This profile accepts and persists a shortcut value for testing without registering it. The app and preferences suite identifiers are distinct. Release packaging rejects the Debug acceptance flags.

With the Studio-only candidate quit and the terminal already authorised for Accessibility, run the native reopen regression test against that build.

```sh
xcrun swiftc -warnings-as-errors -parse-as-library Tests/Native/StudioLifecycleSmoke.swift \
  -o build/studio-acceptance/StudioLifecycleSmoke
build/studio-acceptance/StudioLifecycleSmoke \
  build/studio-acceptance/Build/Products/Debug/Pokelet.app
```
