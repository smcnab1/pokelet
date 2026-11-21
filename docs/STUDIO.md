# Pokelet Studio

The existing Settings window put the character gallery inside a narrow preferences column and gave the live preview its own page. Studio makes the current character the primary workspace, with the appearance controls beside it on wider windows and below it on compact windows.

| Area | Design |
| --- | --- |
| Window | Titled AppKit window with a transparent title bar, native traffic lights and frame restoration. Fresh windows open at up to 936 × 598 points. The minimum is 540 × 440 points. |
| Navigation | Floating icon rail with destination names in tooltips and accessibility labels. It becomes a labelled horizontal dock in compact windows. Command–1 through Command–6 select the destinations in order. |
| Type and colour | System typography with a clear hierarchy for headings, labels and tabular values. General offers a larger text setting for Studio. The website's aubergine, lavender and warm paper inform the adaptive palettes. |
| Materials | Builds made with Xcode 26 or later use Liquid Glass for navigation on macOS 26 and later. Earlier versions and toolchains use a thin standard material. Reduce Transparency uses a solid surface. |
| Preview | The selected character follows the cursor at its configured size when you move inside the preview. Primary and secondary clicks use the same response renderer as the pointer. Click-only mode reveals the character briefly. The preview supports light and dark test surfaces and works with the global pointer turned off. |
| Safety | Studio talks to the existing app model. Permission prompts and Presentation Mode keep their existing availability rules. The Presentation page places recovery instructions before the start action. |

The app targets macOS 14 and later.

## Dock and menu bar

| What you do | What happens |
| --- | --- |
| Open or minimise Studio | The Pokelet icon stays in the Dock. Click it to focus or restore Studio. |
| Close Studio with Command–W or the red close button | Pokelet keeps running, including any enabled pointer. The Dock icon hides by default when the menu bar item is available. |
| Reopen Studio | Choose **Open Pokelet Studio** in the status menu, click its Dock icon when visible, or open Pokelet in Finder. |
| Quit Pokelet | Choose **Quit Pokelet** or press Command–Q while Pokelet is active. The app closes and releases its pointer overlay. |

Under **General → Application behaviour**, turn off **Hide Dock icon when Studio is closed** to keep Pokelet in the Dock. Turn off **Show Pokelet in the menu bar** for a Dock-only setup. This keeps the Dock icon available and preserves your automatic hiding preference for when you switch the menu bar item back on.

macOS controls placement of status items, and menu bar managers can put Pokelet in a hidden section. If AppKit reports that the item is hidden or has no usable frame, Pokelet keeps its Dock icon. Finder can reopen Studio if another app covers the item. [Apple’s guide to menu bar settings](https://support.apple.com/en-asia/guide/mac-help/mchlad96d366/mac)
