# Pokelet verification

## Local 1.1 candidate

Built and checked on 20 November 2026 on Apple M2, macOS 27.3 (26C5035r), Xcode 27.2 (27B52). The bundle identifies itself as 1.1.0, build 2. The public release version will be decided after desktop acceptance.

| Check | Result |
| --- | --- |
| Xcode Debug | Build and static analysis completed with Swift warnings treated as errors. |
| `swift test -Xswiftc -warnings-as-errors` | 24 passed. Covers preference migration, geometry, cursor ownership and restoration decisions, four characters and eight palette options at 1× and 2×, true-black pixels, animation state, click cadence, presentation gesture pairing and fail-open logic, and isolated audio import. |
| `./script/package_release.sh` | Universal Release compiled. Both `arm64` and `x86_64` slices target macOS 14.0. Archive integrity, SHA-256 verification, extraction, resource decode and strict code-signature verification passed. |
| Extracted bundle | App icon present, four WAV files decoded, both MIT notices present and matching source. Ad hoc signature with hardened runtime. Developer ID signing and notarisation are pending. |
| Repository and documentation | `git diff --check`, ShellCheck, Actionlint and the local documentation link checker passed. The static site rendered without horizontal overflow at 1160 px in light appearance and 390 px in dark appearance in a headless browser. |
| Inherited source and assets | Quiet Pointer’s notice matches the upstream pinned commit. The baseline asset generators reproduced the four WAV files and the original 1024 px app icon. |
| Existing distribution | The 1.0.0 ZIP and app executable retained their original SHA-256 hashes. The new bundle, archive and checksum are in `dist/candidate/`. |

The packaging command stages the archive, validates an extracted copy and refuses to overwrite an existing output directory. Builds can be regenerated from source. ZIP bytes can vary with build metadata, so use the checksum that accompanies each archive.

## Live verification pending

The candidate has not been launched in a GUI session during these checks. Its listener, cursor replacement, click suppression and permission recovery have only source and headless test evidence. Hosted CI and Apple distribution trust have not been exercised.

The [interactive acceptance plan](docs/INTERACTIVE_ACCEPTANCE.md) covers actual click suppression and every exit, native cursor restoration, Finder and browser input, colour contrast, audio playback and device changes, Settings accessibility and screenshots, capture, launch at login, sleep and wake, Spaces and full-screen apps. Intel, older supported macOS versions and multi-display hardware require separate runtime coverage.

## Runtime measurements

The following 1.0.0 measurements predate the candidate. They were taken on an Apple M2, macOS 27.3, at one-second intervals with `top`. They are Pokelet process metrics. WindowServer was outside the measurement.

| Historical 1.0.0 scenario | CPU | Memory |
| --- | --- | --- |
| Pointer disabled at fresh launch | 0.0% in six of seven samples, 0.3% once | 12–13 MiB in `top`. A later `ps` RSS snapshot was about 61 MiB. |
| Pointer enabled and stationary | 0.0% in six of seven samples, 0.1% once | 41 MiB in `top`, about 42 MiB `ps` RSS. |
| Mixed automated UI and drag stress | 0.0–12.1% | 38–45 MiB in `top`. |

There are no candidate runtime measurements yet. The mixed workload cannot isolate movement, animation, Settings or test overhead.

After approval, repeat on the same hardware with matched pointer size, effects, display scaling and audio settings. Sample disabled, enabled stationary, steady pointer-only movement, click bursts, sustained drag, Settings preview and mixed workload independently. Record 30 one-second CPU samples per workload, omitting the first `top` sample, and record median and peak CPU with separate RSS snapshots. Record display refresh rate and the capture and automation state used for each run. Include WindowServer figures where the sampling permits it. If a peak remains repeatable, capture a short profile during that separate workload to attribute the cost.
