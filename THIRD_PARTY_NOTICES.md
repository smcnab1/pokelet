# Third-party notices

## Quiet Pointer

Pokelet adapts the overlay window, mouse tracking and display link, click cadence, key-code names and Carbon global shortcut registration from Quiet Pointer. The original source reference is [Quiet Pointer commit 96458f0](https://github.com/quietapps/QuietPointer/tree/96458f0efd3cc011af5541386554dcb25bfd108f).

The [upstream MIT notice](Pokelet/Resources/QuietPointer-MIT.txt) is carried verbatim in source and in the app’s resources. Pokelet’s original changes and assets are covered by the [Pokelet MIT licence](LICENSE), also included in the bundle.

## Artwork and audio

| Asset | Origin |
| --- | --- |
| Finger, Cat Paw, Foam Finger and Comic Arrow | Original vector artwork in [PointerArt.swift](Pokelet/Cursor/PointerArt.swift). |
| App icon and menu bar icon | Original Pokelet artwork. The [icon generator](script/make_icon.swift) builds the source icon and [StatusIcon.swift](Pokelet/Views/StatusIcon.swift) draws the template menu bar image. |
| Tap, pop, wood and squeak | Original waveforms synthesised by [make_audio.py](script/make_audio.py). |
| Documentation gallery | Output of [make_gallery.swift](script/make_gallery.swift) using the app’s vector paths. |

The app depends on system frameworks and uses SF Symbols supplied by macOS. It ships no external package, font, stock audio or third-party artwork. [Vorssaint’s public Settings images](https://github.com/vorssaint/vorssaint-utils/tree/main/docs/assets/readme) informed the use of a compact sidebar and grouped controls. No Vorssaint source or assets are included.
