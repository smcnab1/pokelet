# Pokelet Studio

The existing Settings window put the character gallery inside a narrow preferences column and gave the live preview its own page. Studio makes the current character the primary workspace, with the appearance controls beside it on wider windows and below it on compact windows.

| Area | Design |
| --- | --- |
| Window | Titled AppKit window with a transparent title bar, native traffic lights and frame restoration. Fresh windows open at up to 1,000 × 650 points. The minimum is 540 × 440 points. |
| Navigation | Floating rail with six labelled destinations. It becomes a horizontal dock in compact windows. Command–1 through Command–6 select the destinations in order. |
| Type and colour | System typography with a clear hierarchy for headings, labels and tabular values. General offers a larger text setting for Studio. The website's aubergine, lavender and warm paper inform the adaptive palettes. |
| Materials | Builds made with Xcode 26 or later use Liquid Glass for navigation on macOS 26 and later. Earlier versions and toolchains use a standard material. Reduce Transparency uses a solid surface. |
| Preview | Native character art and the existing click response renderer, with a choice of light or dark test surfaces. Playing a preview is a local interaction. |
| Safety | Studio talks to the existing app model. Permission prompts and Presentation Mode keep their existing availability rules. The Presentation page places recovery instructions before the start action. |

The app targets macOS 14 and later.
