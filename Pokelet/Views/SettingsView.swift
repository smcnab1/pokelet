import SwiftUI

enum SettingsPage: String, CaseIterable {
    case pointer = "Studio"
    case animations = "Animations"
    case sounds = "Sounds"
    case presentation = "Presentation"
    case general = "General"
    case about = "About"

    var symbol: String {
        switch self {
        case .pointer: "cursorarrow"
        case .animations: "sparkles"
        case .sounds: "speaker.wave.2"
        case .presentation: "play.rectangle"
        case .general: "gearshape"
        case .about: "info.circle"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var showQuickStart = false

    private var largerText: Bool { model.prefs.largerStudioText == true }

    var body: some View {
        GeometryReader { geometry in
            let rail = geometry.size.width >= 790
            let layout = rail ? AnyLayout(HStackLayout(alignment: .top, spacing: 24)) :
                AnyLayout(VStackLayout(alignment: .center, spacing: 14))
            VStack(spacing: 12) {
                header
                    .padding(.leading, 88)
                    .padding(.trailing, rail ? 24 : 20)
                layout {
                    StudioNavigation(selection: $model.settingsPage, vertical: rail)
                        .padding(.leading, rail ? 24 : 0)
                        .padding(.horizontal, rail ? 0 : 12)
                    workspace(wide: geometry.size.width >= (largerText ? 925 : 865), rail: rail)
                }
                .frame(maxHeight: .infinity, alignment: .top)
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
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 23, height: 23)
                .accessibilityHidden(true)
            Text("Pokelet Studio")
                .studioFont(.headline)
            Spacer(minLength: 8)
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
                Label("Clicks paused", systemImage: "pause.circle.fill")
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
                .accessibilityLabel("Enable pointer")
                .help("Toggle pointer (\(model.prefs.pointerShortcut.title))")
            }
        }
        .frame(minHeight: 39)
    }

    private func workspace(wide: Bool, rail: Bool) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let issue = model.pointerMessage {
                    StudioNote(issue, symbol: "exclamationmark.circle", warning: true)
                }
                switch model.settingsPage {
                case .pointer: PointerStudio(model: model, wide: wide)
                case .animations: AnimationSettings(model: model, wide: wide)
                case .sounds: SoundSettings(model: model)
                case .presentation: PresentationSettings(model: model)
                case .general: GeneralSettings(model: model)
                case .about: AboutSettings()
                }
            }
            .frame(maxWidth: model.settingsPage == .pointer ? 1060 : 850, alignment: .leading)
            .padding(.horizontal, rail ? 0 : 22)
            .padding(.trailing, rail ? 28 : 0)
            .padding(.top, 3)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .id(model.settingsPage)
        .transition(.opacity)
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
            ForEach(Array(SettingsPage.allCases.enumerated()), id: \.element) { index, page in
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.16)) { selection = page }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: page.symbol)
                            .font(.body.weight(.medium))
                            .accessibilityHidden(true)
                        Text(page.rawValue)
                            .studioFont(.caption, weight: selection == page ? .semibold : .medium)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, vertical ? 8 : largerText ? 2 : 6)
                    .frame(minWidth: vertical ? 88 : 0, maxWidth: vertical ? nil : .infinity, minHeight: 47)
                    .foregroundStyle(selection == page ? StudioTheme.accent : StudioTheme.secondary)
                    .background {
                        if selection == page {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(StudioTheme.selection)
                                .matchedGeometryEffect(id: "navigation", in: selectionHighlight)
                        }
                    }
                }
                .buttonStyle(StudioButtonStyle(radius: 12))
                .keyboardShortcut(KeyEquivalent(Character(String(index + 1))))
                .help("\(page.rawValue) (⌘\(index + 1))")
                .accessibilityAddTraits(selection == page ? .isSelected : [])
                .accessibilityIdentifier("studio.navigation.\(page.rawValue)")
            }
        }
        .padding(5)
        .frame(maxWidth: vertical ? nil : 565)
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
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 17))
        } else {
            fallback(content)
        }
        #else
        fallback(content)
        #endif
    }

    private func fallback(_ content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 17)
        return content
            .background {
                if solid { shape.fill(StudioTheme.surface) }
                else { shape.fill(.regularMaterial) }
            }
            .overlay(shape.strokeBorder(StudioTheme.line).allowsHitTesting(false))
    }
}
