import AppKit
import SwiftUI

@main
enum StudioLayoutSmoke {
    @MainActor
    static func main() {
        _ = NSApplication.shared
        for scheme in [ColorScheme.light, .dark] {
            for larger in [false, true] {
                let blackBox = StudioLabel("Project", symbol: "chevron.left.forwardslash.chevron.right")
                let compact = StudioLabel("Project", symbol: "book.closed")
                let website = StudioLabel("Project", symbol: "globe")
                let sizes = [blackBox, compact, website].map {
                    size(of: $0.studioFont(.body), scheme: scheme, larger: larger)
                }
                precondition(sizes.allSatisfy { abs($0.width - sizes[0].width) < 0.1 },
                             "Leading symbols changed the title column")

                let diagnostics = FeedbackDiagnostics(prefs: Preferences(), presentation: false)
                let about = size(of: AboutSettings(wide: false, diagnostics: diagnostics),
                                 scheme: scheme, larger: larger, width: 508)
                let standard = size(of: AboutSettings(wide: true, diagnostics: diagnostics),
                                    scheme: scheme, larger: larger, width: 834)
                precondition(about.width == 508 && standard.width == 834,
                             "About overflowed its proposed width")
                precondition(about.height > standard.height,
                             "Compact About should stack sections and wrap the longer text")
            }
        }
        let label = StudioLabel("Project on GitHub", symbol: "book.closed").studioFont(.body)
        precondition(size(of: label, scheme: .light, larger: true).width >
                     size(of: label, scheme: .light, larger: false).width,
                     "Larger Studio text did not increase the label size")

        if let display = NSScreen.screens.first {
            let overlay = CursorOverlayWindow(display: display)
            precondition(overlay.ignoresMouseEvents && !overlay.canBecomeKey && !overlay.canBecomeMain)
            precondition(!overlay.isVisible && overlay.contentView?.isFlipped == false)
            overlay.close()
        }
        print("Native Studio layout passed in light and dark, compact and wide, and both text sizes.")
    }

    @MainActor
    private static func size(of content: some View, scheme: ColorScheme, larger: Bool,
                             width: CGFloat? = nil) -> CGSize {
        let renderer = ImageRenderer(content: content
            .environment(\.studioLargerText, larger)
            .environment(\.colorScheme, scheme))
        renderer.proposedSize = ProposedViewSize(width: width, height: nil)
        guard let image = renderer.nsImage else { fatalError("Studio view failed to render") }
        return image.size
    }
}
