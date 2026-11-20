# Pokelet 1.0.0 verification

Verified on 20 November 2026 on an **Apple M2** with one built-in Retina display, macOS **27.3** (26C5035r), and Xcode **27.2** (27B52). The Release bundle contains arm64 and x86_64 slices, both targeting macOS 14.0.

## Executed checks

| Check | Observed result |
| --- | --- |
| Release build and archive | Xcode built the app. The packaged app launched from `dist`, its ad hoc signature passed strict verification, and the ZIP passed its integrity test. |
| `swift test` | Six tests passed for click cadence and its cap, animation intensity, settings persistence and reset, malformed settings recovery, and presentation transitions and button pairing. |
| `./script/test_native.sh` | Three overlay creation and teardown cycles passed. The test checked actual window flags, hotspot geometry, four rendered styles, distinct left and right click animations, and click-only reveal. AVFoundation decoded all four bundled samples. The runner also verified and disarmed a real session event tap. |
| Settings and permissions | Enabled the pointer, switched to Cat Paw, toggled click audio, imported a local WAV and verified style and custom audio persistence after relaunch. Without Accessibility, the app showed the permission requirement and stayed out of Presentation Mode. |
| Browser interaction | A local test page received three ordinary clicks, one double-click and one context click with the overlay enabled. Dragging selected the intended text. |
| Display recording | A frame extracted from a two-second full-display recording showed Cat Paw with its tip aligned to the native arrow in another app. |

The first interactive enable exposed an AppKit initialiser crash. The fix uses AppKit’s designated window initialiser. The native lifecycle smoke test and a second live enable both passed after that change.

## Runtime measurements

Samples were taken with macOS `top` at one-second intervals. These are Pokelet process figures. They do not include WindowServer work.

| Scenario | CPU | Memory |
| --- | --- | --- |
| Pointer disabled, fresh launch | 0.0% in six of seven samples, 0.3% once | 12–13 MiB in `top`. A later `ps` RSS snapshot was about 61 MiB. |
| Pointer enabled and stationary | 0.0% in six of seven samples, 0.1% once | 41 MiB in `top`, about 42 MiB in the `ps` RSS snapshot. |
| Mixed automated UI and drag stress | 0.0–12.1% | 38–45 MiB in `top`. |

The mixed workload includes Settings and automation overhead. Ordinary pointer-only movement, display refresh rate and battery impact remain unmeasured.

## Physical checks still open

- Global hotkey delivery, live Presentation Mode click suppression and both emergency exits in the installed app. The automation did not verify global hotkey delivery, and no Accessibility or Input Monitoring permissions were granted.
- Finder click and drag animations, foreground native cursor restoration on quit, display hot-plug, cross-display transitions, Spaces and full-screen apps.
- Audible playback through the selected output device, system audio in a recording, launch at login, sleep and wake, and runtime compatibility on Intel or earlier macOS versions.
