# Interactive acceptance

Run this sequence only after the desktop owner approves it. Start with a disposable document and the [local browser test page](../Tests/Interactive/InputTargets.html) with left-click, context-click and double-click counters, a keyboard-controlled slide counter and a text-selection area. Close or hide personal windows before recording.

## Set up and recover

1. Record the running Pokelet version, state and bundle location so they can be restored. Ask the owner to finish any active input and quit that instance normally.
2. Build the **Debug** configuration for Presentation Mode acceptance. With approval, launch the local app with `--settings --acceptance-profile`. This uses a separate preferences suite, window frame and audio directory. The everyday app profile stays available to the original build. Beta 2 Release builds ignore the acceptance flags.
3. Use deliberate, physical input against the test targets. Stop immediately on request, on unexpectedly lost pointer or keyboard control, or on an app activation you did not request.
4. To restore input, try **Escape**, **Control–Option–T** or click the Pokelet menu bar indicator. Use the pointer shortcut shown in **Settings → General** or **Quit Pokelet** to remove the overlay. If the app is unresponsive, press **Command–Option–Escape** to force quit if Pokelet is listed. An agreed second terminal can terminate the exact candidate PID as a backup. Confirm the native cursor and clicks return before continuing.
5. At the end, quit the candidate, restore any permission and Login Items state changed for the test and relaunch the original build if it was running before the test.

## Desktop checks

| Order | Exercise | Expected observation |
| --- | --- | --- |
| 1 | Start disabled; navigate all six Settings panes at minimum and wider sizes. Try keyboard navigation, VoiceOver, light and dark appearance, custom tint, and both preview buttons. | No permission prompts on open. Controls fit and have usable labels. Changing or playing a preview does not animate the live pointer. |
| 2 | Use Companion mode in Finder and a clean browser window. Switch foreground apps. Click, right-click, double-click, drag, select text and try modifier-clicks. | The native cursor stays visible. The animated character follows beside it. Target actions and focus behave normally. |
| 3 | Try replacement inside active Pokelet Settings. Move outside the window, open a menu and switch apps. Repeat rapid toggles, disable and quit. | The animation’s contact point aligns inside the eligible window. The macOS cursor resumes outside it and on disable or quit. |
| 4 | Exercise each character in Original, White, Black and Custom. Test both backgrounds, small and large sizes, all five intensities, rapid clicks, character switching, click-only and both Reduce Motion controls. | Style, motion, outlines, visibility and selection remain consistent. |
| 5 | Test all sounds, mute, volume, audio import, output-device change, restore previous state, conflicting shortcuts and Login Items. Relaunch using the same acceptance profile. | Click playback and preview behave as labelled, invalid audio preserves the previous sound, and settings persist. System permission or login changes require an agreed owner action. |
| 6 | Test Spaces, full screen, sleep and wake, 1×/2× and a second display if available. Record a short whole-display demonstration on a disposable desktop. | Cursor and input recover from each transition. Record display and capture conditions and any omitted surfaces. |
| 7 | Relaunch with `--acceptance-profile --presentation-acceptance`. Test denial before granting anything. Use the in-app request only if authorised. Start the mode against the harmless targets. | No suppression until the tap and shortcuts are ready. Left, right and other clicks leave counters unchanged while the pointer animates. Scrolling, slide keys and ordinary Escape delivery are retained. |
| 8 | Run separate sessions for Escape, Control–Option–T, clicking the status indicator, keyboard navigation to **End Presentation Mode**, automatic expiry and loss of access. Exit while a button is held and try rapid stop/start. | Each exit restores clicks. No stuck drag, unpaired gesture activation or unintended rearm. Denial or revocation fails open. |
| 9 | Measure baseline and candidate using the same workload, then close the test apps. | See the measurement method in [verification](../VERIFICATION.md). Mark any skipped scenario or unavailable hardware as unverified. |

The candidate launch may change cursor visibility in Settings. The presentation test briefly suppresses mouse clicks. The desktop owner should approve any permission prompts, VoiceOver, display or session setting changes used for a particular check. The default plan uses physical input, without injected mouse or keyboard events.
