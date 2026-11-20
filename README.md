# Pokelet

Pokelet is a free, native macOS menu bar app. Give your cursor an oversized finger, a cat paw, a foam finger or a comic arrow. Click to make it squash and spring back. Click faster and the reaction builds.

## Install and use

1. Open `dist/Pokelet.app` in Finder, or unzip `dist/Pokelet.zip` and drag the app to Applications.
2. Launch Pokelet and click its hand icon in the menu bar.
3. Choose **Enable Pointer** or press **Control–Option–P**. Choose **Settings…** to change its look, movement and sound.

The Release build includes Apple Silicon and Intel slices, targets macOS 14 or later, and is signed ad hoc for local use. If a downloaded copy is blocked by Gatekeeper, build it locally from source. A paid Apple Developer account is unnecessary for the local build.

| Shortcut | Action |
| --- | --- |
| **Control–Option–P** | Toggle the pointer. Change the shortcut in **Settings → General**. |
| **Control–Option–T** | Toggle Presentation Mode. A secondary shortcut is configurable. This shortcut remains available as an exit. |
| **Escape** | Leave Presentation Mode and restore normal clicks. |

Click sounds start muted. You can preview the original tap, pop, knock and squeak while muted, or import a local audio file up to 3 seconds and 5 MB. **Click-only mode** keeps your normal cursor and shows Pokelet briefly when you click.

## Presentation Mode and permissions

Normal pointer use needs no Accessibility or Input Monitoring permission. Presentation Mode asks macOS for **Accessibility** when you enable it. If macOS omits key events from the tap, Pokelet may also ask for **Input Monitoring** so it can see Escape. After granting a requested permission in **System Settings → Privacy & Security**, try the mode again. macOS may require a relaunch.

While **Clicks Paused** is active, mouse clicks animate the pointer without activating what is underneath. Keyboard input and scrolling continue. Press **Escape** or **Control–Option–T** to resume clicks. Pokelet verifies the tap before it starts blocking and disarms it if the tap becomes unavailable, the session goes inactive, or the Mac sleeps.

Launch at login is optional and uses macOS Login Items. Preferences and imported audio stay on the Mac. Pokelet makes no network requests and uses no external services.

## Build and test

Open `Pokelet.xcodeproj` and run the **Pokelet** scheme, or use these commands from the project directory.

```sh
./script/build_and_run.sh --build
swift test
./script/test_native.sh
./script/build_and_run.sh --package
```

Use `./script/build_and_run.sh` to build and launch. The native tests require a logged-in graphical session. The Xcode project uses Apple frameworks only.

## Known limitations

- Public macOS APIs restrict cursor hiding in background apps. Pokelet follows the pointer system-wide, with both pointers visible where macOS keeps its cursor onscreen. Use **Always keep macOS cursor visible** to retain the system pointer everywhere. [Apple’s cursor API documentation](https://developer.apple.com/documentation/coregraphics/cgdisplayhidecursor(_:))
- Capture the **entire display** to include the overlay. Single-window captures exclude it. Hearing clicks in a recording requires system audio capture in the recording app.
- Locked screens, secure input and some system-controlled full-screen surfaces can restrict overlays or Presentation Mode.
- This local build was tested on macOS 27.3 with an Apple M2. See [verification](VERIFICATION.md) for what was exercised and what still needs a physical check.

## Credits

Pokelet adapts the AppKit overlay, display-link tracking, click cadence and Carbon hotkeys from [Quiet Pointer at commit 96458f0](https://github.com/quietapps/QuietPointer/tree/96458f0efd3cc011af5541386554dcb25bfd108f). [The upstream MIT notice](LICENSE) is included in source and in the app bundle.

The interaction references were the [Pokey site](https://pokeyapp.com/), [Pokey guides](https://pokeyapp.com/guides/), and the [ThisIsE demonstration at 02:05–03:04](https://www.youtube.com/watch?v=jRo82SllAvQ&t=125s). Pokelet’s character artwork, icon and click sounds are original to this project.
