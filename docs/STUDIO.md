# Pokelet Studio

Studio is part of the unpublished Beta 2. See the [usage guide](README.md) for public Beta 1.

The existing Settings window put the character gallery inside a narrow preferences column and gave the live preview its own page. Studio makes the current character the primary workspace, with the appearance controls beside it on wider windows and below it on compact windows.

| Area | Design |
| --- | --- |
| Window | Titled AppKit window with a transparent title bar, native traffic lights and frame restoration. Fresh windows open at up to 936 × 598 points. The minimum is 540 × 440 points. |
| Navigation | Floating icon rail with destination names in tooltips and accessibility labels. It becomes a labelled horizontal dock in compact windows. Command–1 through Command–6 select the destinations in order. |
| Type and colour | System typography with a clear hierarchy for headings, labels and tabular values. General offers a larger text setting for Studio. The website's aubergine, lavender and warm paper inform the adaptive palettes. |
| Materials | Builds made with Xcode 26 or later use Liquid Glass for navigation on macOS 26 and later. Earlier versions and toolchains use a thin standard material. Reduce Transparency uses a solid surface. |
| Preview | The preview uses the same placement and click effects as the live pointer. Turn the live pointer off to try the stage on its own. Companion keeps the character beside the Mac cursor and marks the actual click. Click-only reveals the character at the click position. |
| Safety | Studio talks to the existing app model. Permission prompts and Presentation Mode keep their existing availability rules. The Presentation page places recovery instructions before the start action. |

The app targets macOS 14 and later.

## Pointer modes

| Mode | What you see |
| --- | --- |
| **Companion** | The character follows beside the native Mac cursor and reacts to clicks. |
| **Click-only** | The character appears at the click position and fades out. |
| **Replace in Studio** | The character replaces the native cursor in eligible areas of the active Studio window. The Mac cursor returns outside those areas. |

## Presenter Arm

Open **Studio → Presenter effects** and turn on **Enable Presenter Arm**. Move or click inside the preview to try the glove while the main pointer switch is off. Use the preview’s sun or moon button to test against a different background.

| Control | Effect |
| --- | --- |
| **Pointer on** | Shows the glove and sleeve across apps. The sleeve attaches to the bottom of the current display and your Mac cursor stays visible. |
| **Size** | Changes the glove size. Sleeve thickness grows within a limited range. |
| **Enable Presenter Arm** off | Returns to the previous character, colour and display settings. |
| **Use Presenter Arm during presentations** | A separate setting for active Presentation Mode in eligible Debug acceptance builds. The public Release build keeps Presentation Mode unavailable. |

## Click sounds

In **Sounds → Playback**, choose **Every click** or **Interactive clicks only** for clicks in other apps while the pointer is on. Interactive mode uses macOS Accessibility information to identify controls such as buttons, links and text fields. If macOS cannot identify the receiving app or control, the click is silent. If Accessibility access is unavailable, interactive click sounds pause. Choose **Use Every click** to switch modes or **Preview sound** to hear the selected sound in Studio.

## Feedback

In **About → Help & Feedback**, open the GitHub bug or feature form. The bug form can prefill the app version, macOS version, Mac architecture and pointer settings for review. Use **Copy system information** if you need to paste the details manually. Use the [security policy](../SECURITY.md) for private reports.

[See About and the feedback actions](screenshots/pokelet-studio-about-dark.png) · [See the compact Presenter Arm preview](screenshots/pokelet-studio-presenter-compact-light.png)

## Dock and menu bar

| What you do | What happens |
| --- | --- |
| Open or minimise Studio | The Pokelet icon stays in the Dock. Use Command–M to minimise, and click the Dock icon to focus or restore Studio. |
| Close Studio with Command–W or the red close button | Pokelet keeps running, including any enabled pointer. The Dock icon hides by default when the menu bar item is available. |
| Reopen Studio | Choose **Open Pokelet Studio** in the status menu, click its Dock icon when visible, or open Pokelet in Finder. |
| Quit Pokelet | Choose **Quit Pokelet** or press Command–Q while Pokelet is active. The app closes and releases its pointer overlay. |

Under **General → Application behaviour**, turn off **Hide Dock icon when Studio is closed** to keep Pokelet in the Dock. Turn off **Show Pokelet in the menu bar** for a Dock-only setup. This keeps the Dock icon available and preserves your automatic hiding preference for when you switch the menu bar item back on.

macOS controls placement of status items, and menu bar managers can put Pokelet in a hidden section. If AppKit reports that the item is hidden or has no usable frame, Pokelet keeps its Dock icon. Finder can reopen Studio if another app covers the item. [Apple’s guide to menu bar settings](https://support.apple.com/en-asia/guide/mac-help/mchlad96d366/mac)
