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
