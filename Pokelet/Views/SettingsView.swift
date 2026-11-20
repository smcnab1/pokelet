import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var page: Page = .pointer
    @State private var confirmReset = false

    private enum Page: String, CaseIterable {
        case pointer = "Pointer", animation = "Animations", sound = "Sound", general = "General"

        var symbol: String {
            switch self {
            case .pointer: "cursorarrow"
            case .animation: "sparkle"
            case .sound: "speaker.wave.2"
            case .general: "gearshape"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            VStack(spacing: 0) {
                heading
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 17) {
                        switch page {
                        case .pointer: pointerPage
                        case .animation: animationsPage
                        case .sound: soundPage
                        case .general: generalPage
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(23)
                }
                .defaultScrollAnchor(.top)
                .id(page)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 650, minHeight: 450)
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("Reset Pokelet?", isPresented: $confirmReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Settings", role: .destructive) { model.reset() }
        } message: {
            Text("This turns the pointer off, restores the default shortcuts and removes any imported sound.")
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 9) {
                PointerPreview(style: .finger, palette: .original)
                    .frame(width: 32, height: 32)
                    .background(.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                Text("Pokelet").font(.system(size: 19, weight: .bold, design: .rounded))
            }
            .padding(.bottom, 14)
            .padding(.leading, 7)

            ForEach(Page.allCases, id: \.self) { item in
                Button {
                    page = item
                } label: {
                    Label(item.rawValue, systemImage: item.symbol)
                        .fontWeight(page == item ? .semibold : .regular)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(page == item ? Color.accentColor.opacity(0.16) : .clear,
                                    in: RoundedRectangle(cornerRadius: 7))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(page == item ? .isSelected : [])
            }
            Spacer()
            HStack(spacing: 7) {
                Image(systemName: model.mode.presentation ? "pause.circle.fill" : "circle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(model.mode.presentation ? Color.orange :
                                       model.mode.pointer ? Color.green : Color.secondary.opacity(0.6))
                    .accessibilityHidden(true)
                Text(model.mode.presentation ? "Clicks paused" : model.mode.pointer ? "Pointer on" : "Pointer off")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 8)
        }
        .padding(13)
        .frame(width: 164)
        .background(.regularMaterial)
    }

    private var heading: some View {
        HStack {
            Text(page.rawValue)
                .font(.system(size: 25, weight: .semibold))
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button(model.mode.pointer ? "Turn Pointer Off" : "Turn Pointer On") { model.togglePointer() }
                .buttonStyle(.bordered)
                .disabled(model.mode.presentation)
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 23)
    }

    private var pointerPage: some View {
        Group {
            HStack(spacing: 9) {
                ForEach(PointerStyle.allCases) { style in
                    let selected = model.prefs.style == style
                    Button {
                        model.update(\.style, style)
                    } label: {
                        VStack(spacing: 5) {
                            PointerPreview(style: style, palette: model.prefs.palette)
                                .frame(width: 64, height: 64)
                            Text(style.title)
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selected ? Color.accentColor.opacity(0.13) : Color.primary.opacity(0.035),
                                    in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(selected ? Color.accentColor : Color.primary.opacity(0.09),
                                          lineWidth: selected ? 1.5 : 1))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            settingsGroup {
                HStack {
                    Slider(value: binding(\.size), in: Preferences.sizeRange, step: 1) { Text("Size") }
                    Text("\(Int(model.prefs.size)) pt").monospacedDigit().foregroundStyle(.secondary)
                        .frame(width: 49, alignment: .trailing)
                        .accessibilityHidden(true)
                }
                Picker("Colour", selection: binding(\.palette)) {
                    ForEach(Palette.allCases) { Text($0.title).tag($0) }
                }
                HStack(spacing: 22) {
                    Toggle("Outline", isOn: binding(\.outline))
                    Toggle("Soft shadow", isOn: binding(\.shadow))
                }
            }

            settingsGroup {
                Toggle("Click-only mode", isOn: binding(\.clickOnly))
                Toggle("Always keep macOS cursor visible", isOn: binding(\.keepNative))
                    .disabled(model.prefs.clickOnly)
                note("macOS may keep its cursor visible while another app is active.")
                if let issue = model.pointerMessage { note(issue, warning: true) }
            }
        }
    }

    private var animationsPage: some View {
        Group {
            settingsGroup {
                Toggle("Animate on click", isOn: binding(\.animate))
                Picker("Intensity", selection: binding(\.intensity)) {
                    ForEach(Intensity.allCases) { Text($0.title).tag($0) }
                }
                .disabled(!model.prefs.animate)
                Toggle("React to fast clicks", isOn: binding(\.reactive)).disabled(!model.prefs.animate)
                Toggle("Comic impact effects", isOn: binding(\.effects)).disabled(!model.prefs.animate)
                Toggle("Celebration sparkles", isOn: binding(\.celebration))
                    .disabled(!model.prefs.animate || !model.prefs.effects || model.prefs.reducedMotion)
            }
            settingsGroup {
                Toggle("Reduced Motion", isOn: binding(\.reducedMotion))
                Toggle("Wobble on sharp turns and stops", isOn: binding(\.directionBounce))
                    .disabled(model.prefs.reducedMotion)
                note("Pokelet also follows the macOS Reduce Motion setting.")
            }
        }
    }

    private var soundPage: some View {
        Group {
            settingsGroup {
                Toggle("Play click sounds", isOn: binding(\.soundEnabled))
                Picker("Click sound", selection: binding(\.sound)) {
                    ForEach(ClickSound.allCases.filter { $0 != .custom || model.prefs.customSoundName != nil }) {
                        Text($0.title).tag($0)
                    }
                }
                HStack {
                    Slider(value: binding(\.volume), in: 0...1) { Text("Volume") }
                    Text("\(Int(model.prefs.volume * 100))%").monospacedDigit().foregroundStyle(.secondary)
                        .frame(width: 42, alignment: .trailing)
                        .accessibilityHidden(true)
                }
                Button("Preview Sound") { model.previewSound() }
                    .disabled(model.prefs.sound == .silent || model.prefs.volume == 0)
            }
            settingsGroup {
                Button("Import Audio…") { model.chooseCustomSound() }
                if let name = model.prefs.customSoundName { note(name) }
                note("Use an audio file up to 3 seconds and 5 MB. Pokelet saves a local copy.")
                if let issue = model.audioMessage { note(issue, warning: true) }
            }
        }
    }

    private var generalPage: some View {
        Group {
            settingsGroup {
                ShortcutField(label: "Toggle pointer", shortcut: model.prefs.pointerShortcut) {
                    model.setShortcut($0, presentation: false)
                }
                ShortcutField(label: "Presentation Mode", shortcut: model.prefs.presentationShortcut) {
                    model.setShortcut($0, presentation: true)
                }
                if let issue = model.shortcutMessage { note(issue, warning: true) }
            }
            settingsGroup {
                Toggle("Launch at login", isOn: Binding(
                    get: { model.loginStatus == .enabled || model.loginStatus == .requiresApproval },
                    set: model.toggleLaunchAtLogin
                ))
                Toggle("Restore pointer state on launch", isOn: binding(\.restoreEnabled))
                if model.loginStatus == .requiresApproval {
                    Button("Open Login Items") { SMAppService.openSystemSettingsLoginItems() }
                }
                if let issue = model.generalMessage { note(issue, warning: true) }
            }
            settingsGroup {
                Button(model.mode.presentation ? "End Presentation Mode" : "Start Presentation Mode") {
                    model.togglePresentation()
                }
                note("Presentation Mode pauses mouse clicks. Press Escape or ⌃⌥T to restore them.")
                if let issue = model.presentationMessage { note(issue, warning: true) }
            }
            Button("Reset Settings…") { confirmReset = true }
        }
    }

    private func binding<T>(_ path: WritableKeyPath<Preferences, T>) -> Binding<T> {
        Binding(get: { model.prefs[keyPath: path] }, set: { model.update(path, $0) })
    }

    private func settingsGroup<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 11, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(13)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 9))
    }

    private func note(_ message: String, warning: Bool = false) -> some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(warning ? Color.orange : Color.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct PointerPreview: View {
    let style: PointerStyle
    let palette: Palette

    var body: some View {
        Canvas { context, size in
            context.withCGContext { cg in
                cg.scaleBy(x: size.width / PointerArt.canvas, y: size.height / PointerArt.canvas)
                cg.translateBy(x: -8, y: -2)
                PointerArt.draw(in: cg, style: style, palette: palette, outline: true, shadow: true)
            }
        }
        .accessibilityHidden(true)
    }
}
