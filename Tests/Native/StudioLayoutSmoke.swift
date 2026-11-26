import AppKit
import Sparkle
import SwiftUI

@main
enum StudioLayoutSmoke {
    @MainActor
    static func main() {
        _ = NSApplication.shared
        precondition(Set(ProcessInfo.processInfo.arguments).isSuperset(of: [
            "--acceptance-profile", "--presentation-acceptance", "--studio-acceptance"
        ]))
        let releaseModel = AppModel()
        precondition(!releaseModel.presentationAvailable && !releaseModel.isAcceptanceProfile && !releaseModel.isStudioAcceptance,
                     "A Release build must ignore Debug acceptance flags")
        precondition(!releaseModel.analytics.isAvailable, "Acceptance profiles must exclude analytics")
        releaseModel.startPresentation()
        precondition(!releaseModel.mode.presentation && !releaseModel.mode.pointer)
        print("Release ignored the Debug profiles and kept Presentation Mode disabled.")
        let comparator = SUStandardVersionComparator.default
        precondition(comparator.compareVersion("10", toVersion: "9") == .orderedDescending)
        precondition(comparator.compareVersion("3", toVersion: "3") == .orderedSame)
        precondition(comparator.compareVersion("2", toVersion: "3") == .orderedAscending)
        precondition(SettingsPage.about.shortcut == 6 && SettingsPage.updates.shortcut == 7)

        let updates = UpdateService(defaults: nil)
        updates.start()
        precondition(!updates.isAvailable && !updates.canCheck && !updates.automaticallyChecks,
                     "A bundle without an update feed must remain usable with updates disabled.")
        for scheme in [ColorScheme.light, .dark] {
            for larger in [false, true] {
                let pane = size(of: UpdateSettings(updates: updates, presentation: false, showWhatsNew: {}),
                                scheme: scheme, larger: larger, width: 508)
                precondition(pane.width == 508, "Updates overflowed the minimum Studio width.")
                let notes = size(of: WhatsNewView(version: "1.2.0", current: nil, history: [], windowHeight: 440),
                                 scheme: scheme, larger: larger)
                precondition(notes.width <= 508 && notes.height <= 400, "What's New cannot fit in minimum Studio.")
                let window = SettingsView.defaultWindowSize(largerText: larger)
                let pointer = size(of: PointerStudio(model: releaseModel, wide: true, windowHeight: window.height),
                                   scheme: scheme, larger: larger, width: window.width - 102)
                precondition(pointer.height + 74 <= window.height,
                             "Default Studio size must fit the main pane. Pointer content is \(pointer.height).")

                let blackBox = StudioLabel("Project", symbol: "chevron.left.forwardslash.chevron.right")
                let compact = StudioLabel("Project", symbol: "book.closed")
                let website = StudioLabel("Project", symbol: "globe")
                let sizes = [blackBox, compact, website].map {
                    size(of: $0.studioFont(.body), scheme: scheme, larger: larger)
                }
                precondition(sizes.allSatisfy { abs($0.width - sizes[0].width) < 0.1 },
                             "Leading symbols changed the title column")

                let analytics = size(of: PrivacyAnalyticsSettings(analytics: releaseModel.analytics),
                                     scheme: scheme, larger: larger, width: 508)
                precondition(analytics.width == 508, "Privacy & Analytics overflowed its proposed width.")

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
