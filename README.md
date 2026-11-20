# Pokelet

A free, MIT-licensed animated cursor companion for macOS. Give your pointer a cartoon finger, a cat paw, a foam finger or a comic arrow. Each click makes the character poke, and faster clicks bring out bigger reactions.

**Requires macOS 14 or later.** The Xcode build supports Apple silicon and Intel.

![Original and true-black artwork for the Finger, Cat Paw, Foam Finger and Comic Arrow](docs/site/assets/pokelet-pointer-character-colours.png)

The gallery is rendered from Pokelet’s vector artwork.

<details>
<summary>Settings screenshots</summary>

![Pointer Settings showing all four true-black characters against light and dark swatches](docs/screenshots/pokelet-settings-pointer-dark.png)

![Animations Settings with an in-window click preview and intensity controls](docs/screenshots/pokelet-settings-animations-dark.png)

</details>

<details>
<summary>Watch the click animation demo</summary>

![Pokelet’s Finger follows the native cursor and animates on clicks in a full-display recording](docs/site/assets/pokelet-cursor-demo.gif)

</details>

## Get Pokelet

The first public download is pending. The [GitHub Releases page](https://github.com/smcnab1/pokelet/releases) is the planned download location. Local builds are ad hoc signed and lack Apple notarisation. To try Pokelet before a trusted public build is available, build it from source with Xcode.

For an approved distribution, verify `Pokelet.zip` against the accompanying SHA-256 checksum, extract it and open `Pokelet.app`. Move the app to Applications if you want to keep it. For a Gatekeeper block, use a trusted signed distribution or build from source.

## Use the pointer

1. Choose **Enable Pointer** in the Pokelet menu bar menu or press **Control–Option–P**.
2. Open **Settings → Pointer** to choose a character, size and colour. Use Original, White, Black, Custom or one of the original colour tints.
3. In **Animations**, try five levels of click intensity in the in-window preview. Click-only mode shows Pokelet briefly when you click. Pokelet follows macOS Reduce Motion.
4. In **Sounds**, choose one of four click sounds, mute playback, or import a local file up to 3 seconds and 5 MB.

**Companion** mode keeps the system cursor and places the character beside it. The optional **Replace in Pokelet Settings** mode aligns the character’s fingertip with the click point inside the exposed part of Pokelet’s active Settings window. Everywhere else it uses Companion mode. Quartz generally requires the calling app to be foregrounded for cursor hiding. [Apple’s cursor API](https://developer.apple.com/documentation/coregraphics/cgdisplayhidecursor(_:))

| Shortcut | What it does |
| --- | --- |
| Control–Option–P | Toggles the pointer. Change the shortcut in **General**. |
| Control–Option–T | Toggles Presentation Mode in an acceptance launch. |
| Escape | Ends an active presentation. Escape continues to reach the active app. |

## Presentation Mode and privacy

Presentation Mode is **disabled during ordinary launches** while the remaining safety checks are open. Desktop acceptance verified that it pauses browser clicks while keyboard input continues. Control–Option–T, Escape and the fixed-width pause symbol in the menu bar each restored clicks. A 15-minute limit and a tap health check provide automatic recovery. [Acceptance evidence](VERIFICATION.md#desktop-acceptance)

The everyday pointer uses passive mouse monitoring. Presentation Mode requires Accessibility and can request Input Monitoring when macOS withholds Escape from the tap. Launch at login is optional. Pokelet stores preferences and imported sounds locally, with no account, telemetry or background network activity. [Privacy details](PRIVACY.md)

## Build and verify

Install Xcode 16 or later with the macOS SDK and select its command-line tools.

```sh
swift test
./script/build_and_run.sh --build
./script/test_native.sh
./script/package_release.sh
```

These commands compile and test without opening the app. The final command creates a universal bundle, ZIP and checksum in `dist/candidate/`. Supply a fresh output directory to repeat packaging. Open `Pokelet.xcodeproj` at the **Pokelet** scheme for normal Xcode development.

## Screen sharing and performance

Choose **Entire Screen** or **Full Display** in your capture app so it can include Pokelet’s separate overlay window. An individual window capture generally excludes it. Enable system audio in the capture app if you want viewers to hear click sounds. Desktop acceptance verified full-display recording and a full-screen browser on one built-in Retina display. Capture behaviour on other setups is still open.

On an Apple M2 with Settings closed, the current candidate measured 0.0% CPU while stationary, 5.0% median for pointer-only movement and 5.6% peak during scripted click bursts. Its process RSS snapshots ranged from 60 to 65 MiB across the five workloads. [Verification and measurement method](VERIFICATION.md)

## Contribute

Use the [contributing guide](CONTRIBUTING.md) to report a problem, propose a change or test a build. Pokelet is an independent project with no affiliation with Pokey. The [comparison](docs/COMPETITOR_COMPARISON.md) covers Pokey and other macOS cursor tools.

[MIT licence](LICENSE) · [Third-party notices](THIRD_PARTY_NOTICES.md) · [Changelog](CHANGELOG.md) · [Security](SECURITY.md)
