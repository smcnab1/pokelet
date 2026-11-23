import SwiftUI

enum SettingsPage: String, CaseIterable {
    case pointer = "Studio"
    case animations = "Animations"
    case sounds = "Sounds"
    case presentation = "Presentation"
    case general = "General"
    case updates = "Updates"
    case about = "About"

    var shortcut: Int {
        switch self {
        case .pointer: 1
        case .animations: 2
        case .sounds: 3
        case .presentation: 4
        case .general: 5
        case .about: 6
        case .updates: 7
        }
    }

    var symbol: String {
        switch self {
        case .pointer: "cursorarrow"
        case .animations: "sparkles"
        case .sounds: "speaker.wave.2"
        case .presentation: "play.rectangle"
        case .general: "gearshape"
        case .updates: "arrow.clockwise"
        case .about: "info.circle"
        }
    }
}

struct SettingsView: View {
    static func defaultWindowSize(largerText: Bool) -> CGSize {
        CGSize(width: 936, height: largerText ? 736 : 680)
    }

    @ObservedObject var model: AppModel
    @ObservedObject var updates: UpdateService
    @State private var showQuickStart = false
    @State private var showWhatsNew = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var largerText: Bool { model.prefs.largerStudioText == true }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let rail = size.width >= 710
            let layout = rail ? AnyLayout(HStackLayout(alignment: .top, spacing: 18)) :
                AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            VStack(spacing: 10) {
                header
                    .padding(.leading, 80)
                    .padding(.trailing, 22)
                layout {
                    StudioNavigation(selection: $model.settingsPage, vertical: rail)
                        .padding(.leading, rail ? 14 : 0)
                        .padding(.horizontal, rail ? 0 : 16)
                    workspace(wide: size.width >= (largerText ? 835 : 760),
                              rail: rail, height: size.height)
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)
            }
            .sheet(isPresented: $showWhatsNew, onDismiss: updates.markWhatsNewSeen) {
                WhatsNewView(version: updates.version, current: updates.currentRelease, history: updates.releases,
                             windowHeight: size.height)
                    .environment(\.studioLargerText, largerText)
                    .tint(StudioTheme.accent)
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .background(StudioTheme.window.ignoresSafeArea())
        .sheet(isPresented: $showQuickStart) { quickStart }
        .studioFont(.body)
        .tint(StudioTheme.accent)
        .environment(\.studioLargerText, largerText)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("Pokelet Studio")
                .studioFont(.callout, weight: .semibold)
                .foregroundStyle(StudioTheme.secondary)
            Spacer(minLength: 8)
            if updates.offersWhatsNew, model.settingsPage != .updates {
                Button("What’s New") { showWhatsNew = true }
                    .studioFont(.callout)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            Button {
                showQuickStart = true
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.title3)
                    .frame(width: 27, height: 28)
            }
            .buttonStyle(StudioButtonStyle(radius: 8))
            .accessibilityLabel("Quick start")
            .help("Quick start")
            if model.mode.presentation {
                StudioLabel("Clicks paused", symbol: "pause.circle.fill")
                    .studioFont(.callout, weight: .semibold)
                    .foregroundStyle(StudioTheme.warning)
                    .help("Press Escape or Control–Option–T to resume clicks.")
            } else {
                Toggle(isOn: Binding(get: { model.mode.pointer }, set: { enabled in
                    if enabled != model.mode.pointer { model.togglePointer() }
                })) {
                    Text(model.mode.pointer ? "Pointer on" : "Pointer off")
                        .studioFont(.callout, weight: .medium)
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(model.isStudioAcceptance)
                .accessibilityLabel("Enable pointer")
                .help("Toggle pointer (\(model.prefs.pointerShortcut.title))")
            }
        }
        .frame(minHeight: 37)
    }

    private func workspace(wide: Bool, rail: Bool, height: CGFloat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let issue = model.pointerMessage {
                    StudioNote(issue, symbol: "exclamationmark.circle", warning: true)
                }
                switch model.settingsPage {
                case .pointer: PointerStudio(model: model, wide: wide, windowHeight: height)
                case .animations: AnimationSettings(model: model, wide: wide)
                case .sounds: SoundSettings(model: model, wide: wide)
                case .presentation: PresentationSettings(model: model, wide: wide)
                case .general: GeneralSettings(model: model, wide: wide)
                case .updates: UpdateSettings(updates: updates, presentation: model.mode.presentation) {
                    showWhatsNew = true
                }
                case .about: AboutSettings(wide: wide, diagnostics: FeedbackDiagnostics(
                    prefs: model.prefs, presentation: model.mode.presentation
                ))
                }
            }
            .frame(maxWidth: model.settingsPage == .pointer ? 1160 : 860, alignment: .leading)
            .padding(.horizontal, rail ? 0 : 16)
            .padding(.trailing, rail ? 24 : 0)
            .padding(.top, rail ? 3 : 1)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .id(model.settingsPage)
        .transition(reduceMotion ? .identity : .opacity)
    }

    private var quickStart: some View {
        VStack(alignment: .leading, spacing: 17) {
            StudioHeading("Make your cursor yours", detail: "Pokelet adds an animated character alongside your Mac pointer.")
            StudioNote("Pick a character in Studio and click the preview to try its reaction.", symbol: "cursorarrow")
            StudioNote("Turn on the pointer here or in the menu bar. Your current shortcut is \(model.prefs.pointerShortcut.title).",
                       symbol: "command")
            if model.presentationAvailable {
                StudioNote("Presentation Mode requires Accessibility access. Press Escape or Control–Option–T to restore clicks.",
                           symbol: "shield")
            }
            HStack {
                Spacer()
                Button("Done") { showQuickStart = false }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(25)
        .frame(idealWidth: 420)
    }
}

private struct StudioNavigation: View {
    @Binding var selection: SettingsPage
    let vertical: Bool
    @Environment(\.studioLargerText) private var largerText
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var selectionHighlight

    var body: some View {
        let layout = vertical ? AnyLayout(VStackLayout(spacing: 3)) : AnyLayout(HStackLayout(spacing: 3))
        layout {
            ForEach(SettingsPage.allCases, id: \.self) { page in
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.16)) { selection = page }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: page.symbol)
                            .font(.system(size: 15, weight: selection == page ? .semibold : .medium))
                            .accessibilityHidden(true)
                        if !vertical {
                            Text(page.rawValue)
                                .studioFont(.caption, weight: selection == page ? .semibold : .medium)
                                .lineLimit(1)
                        }
                    }
                    .frame(width: vertical ? 38 : nil)
                    .frame(maxWidth: vertical ? nil : .infinity, minHeight: vertical ? 36 : largerText ? 45 : 40)
                    .foregroundStyle(selection == page ? StudioTheme.accent : StudioTheme.secondary)
                    .background {
                        if selection == page {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(StudioTheme.selection)
                                .overlay(alignment: vertical ? .leading : .bottom) {
                                    Capsule().fill(StudioTheme.accent)
                                        .frame(width: vertical ? 2 : 15, height: vertical ? 13 : 2)
                                        .padding(vertical ? .leading : .bottom, 2)
                                }
                                .matchedGeometryEffect(id: "navigation", in: selectionHighlight)
                        }
                    }
                }
                .buttonStyle(StudioButtonStyle(radius: 12))
                .keyboardShortcut(KeyEquivalent(Character(String(page.shortcut))))
                .help("\(page.rawValue) (⌘\(page.shortcut))")
                .accessibilityLabel(page.rawValue)
                .accessibilityAddTraits(selection == page ? .isSelected : [])
                .accessibilityIdentifier("studio.navigation.\(page.rawValue)")
            }
        }
        .padding(4)
        .modifier(NavigationMaterial(solid: reduceTransparency))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.19), value: selection)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Studio navigation")
    }
}

private struct NavigationMaterial: ViewModifier {
    let solid: Bool

    @ViewBuilder func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26, *), !solid {
            content.glassEffect(.clear, in: RoundedRectangle(cornerRadius: 15))
        } else {
            fallback(content)
        }
        #else
        fallback(content)
        #endif
    }

    private func fallback(_ content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 15)
        return content
            .background {
                if solid { shape.fill(StudioTheme.surface) }
                else { shape.fill(.thinMaterial) }
            }
            .overlay(shape.strokeBorder(StudioTheme.line).allowsHitTesting(false))
    }
}
