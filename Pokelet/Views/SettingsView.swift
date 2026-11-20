import ServiceManagement
import SwiftUI

enum SettingsPage: String, CaseIterable {
    case general = "General"
    case pointer = "Pointer"
    case animations = "Animations"
    case sounds = "Sounds"
    case presentation = "Presentation"
    case about = "About"

    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .pointer: "cursorarrow"
        case .animations: "sparkles"
        case .sounds: "speaker.wave.2"
        case .presentation: "play.rectangle"
        case .about: "info.circle"
        }
    }

    var description: String {
        switch self {
        case .general: "Set up the menu bar and global shortcuts."
        case .pointer: "Choose a character and how it follows your cursor."
        case .animations: "Try click effects here before using them on screen."
        case .sounds: "Choose or import a sound for clicks."
        case .presentation: "Pause mouse clicks while you present."
        case .about: "Version, source code and data handling."
        }
    }
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var confirmReset = false

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(model.settingsPage.rawValue)
                            .font(.title.bold())
                            .accessibilityAddTraits(.isHeader)
                        Text(model.settingsPage.description).foregroundStyle(.secondary)
                    }
                    switch model.settingsPage {
                    case .general: generalPage
                    case .pointer: pointerPage
                    case .animations: animationsPage
                    case .sounds: soundPage
                    case .presentation: presentationPage
                    case .about: aboutPage
                    }
                }
                .frame(maxWidth: 680, alignment: .leading)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .id(model.settingsPage)
        }
        .frame(minWidth: 670, minHeight: 470)
        .alert("Reset Pokelet?", isPresented: $confirmReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Settings", role: .destructive) { model.reset() }
        } message: {
            Text("This turns the pointer off, restores the default shortcuts and removes any imported sound.")
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable().frame(width: 30, height: 30).accessibilityHidden(true)
                Text("Pokelet").font(.headline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            List(SettingsPage.allCases, id: \.self, selection: Binding<SettingsPage?>(
                get: { model.settingsPage },
                set: { if let page = $0 { model.settingsPage = page } }
            )) { page in
                Label(page.rawValue, systemImage: page.symbol).tag(page)
            }
            .listStyle(.sidebar)
            Label(model.mode.presentation ? "Clicks paused" : model.mode.pointer ? "Pointer on" : "Pointer off",
                  systemImage: model.mode.presentation ? "pause.circle.fill" : "circle.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(16)
        }
        .frame(width: 170)
        .background(.regularMaterial)
    }

    private var generalPage: some View {
        Group {
            SettingsGroup("Startup") {
                Toggle("Enable Pokelet", isOn: Binding(get: { model.mode.pointer }, set: { enabled in
                    if enabled != model.mode.pointer { model.togglePointer() }
                }))
                .disabled(model.mode.presentation)
                if let issue = model.pointerMessage { SettingsNote(issue, warning: true) }
                Divider()
                Toggle("Launch at login", isOn: Binding(
                    get: { model.loginStatus == .enabled || model.loginStatus == .requiresApproval },
                    set: model.toggleLaunchAtLogin
                ))
                if model.loginStatus == .requiresApproval {
                    SettingsNote("Approve Pokelet in Login Items to finish enabling this setting.")
                    Button("Open Login Items") { SMAppService.openSystemSettingsLoginItems() }
                }
                Toggle("Restore pointer state on launch", isOn: binding(\.restoreEnabled))
                if let issue = model.generalMessage { SettingsNote(issue, warning: true) }
            }
            SettingsGroup("Global shortcuts") {
                ShortcutField(label: "Toggle pointer", shortcut: model.prefs.pointerShortcut) {
                    model.setShortcut($0, presentation: false)
                }
                if model.presentationAvailable {
                    ShortcutField(label: "Alternate presentation shortcut", shortcut: model.prefs.presentationShortcut) {
                        model.setShortcut($0, presentation: true)
                    }
                    .disabled(model.mode.presentation)
                    SettingsNote("Control–Option–T remains available to end an active presentation.")
                }
                if let issue = model.shortcutMessage { SettingsNote(issue, warning: true) }
            }
            Button("Reset Settings…") { confirmReset = true }
        }
    }

    private var pointerPage: some View {
        Group {
            SettingsGroup("Character") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(PointerStyle.allCases) { style in
                        let selected = model.prefs.style == style
                        Button {
                            model.update(\.style, style)
                        } label: {
                            VStack(spacing: 7) {
                                SplitPointerPreview(prefs: model.prefs, style: style)
                                    .frame(height: 77)
                                Text(style.title).font(.caption.weight(selected ? .semibold : .regular))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(5)
                            .padding(.bottom, 3)
                            .background(selected ? Color.accentColor.opacity(0.13) : Color.primary.opacity(0.035),
                                        in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9)
                                .strokeBorder(selected ? Color.accentColor : Color.primary.opacity(0.10)))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
            }
            SettingsGroup("Appearance") {
                Picker("Colour", selection: binding(\.palette)) {
                    ForEach(Palette.allCases) { Text($0.title).tag($0) }
                }
                if model.prefs.palette == .custom {
                    ColorPicker("Custom colour", selection: customColour, supportsOpacity: false)
                }
                HStack {
                    Slider(value: binding(\.size), in: Preferences.sizeRange, step: 1) { Text("Size") }
                        .accessibilityValue("\(Int(model.prefs.size)) points")
                    Text("\(Int(model.prefs.size)) pt").monospacedDigit().foregroundStyle(.secondary)
                        .frame(width: 48, alignment: .trailing)
                        .accessibilityHidden(true)
                }
                Toggle("Contrasting outline", isOn: binding(\.outline))
                Toggle("Soft shadow", isOn: binding(\.shadow))
            }
            SettingsGroup("Cursor behaviour") {
                Picker("Display mode", selection: binding(\.keepNative)) {
                    Text("Companion").tag(true)
                    Text("Replace in Pokelet Settings").tag(false)
                }
                .disabled(model.prefs.clickOnly)
                SettingsNote(model.prefs.clickOnly
                    ? "Click-only mode keeps the macOS cursor visible."
                    : "In other apps, the character sits beside the native cursor.")
            }
        }
    }

    private var animationsPage: some View {
        Group {
            SettingsGroup("Preview") {
                AnimationPreview(prefs: model.prefs, reducedMotion: systemReduceMotion || model.prefs.reducedMotion)
            }
            SettingsGroup("Click response") {
                Toggle("Animate on click", isOn: binding(\.animate))
                Group {
                    Picker("Intensity", selection: binding(\.intensity)) {
                        ForEach(Intensity.allCases) { Text($0.title).tag($0) }
                    }
                    Toggle("React to fast clicks", isOn: binding(\.reactive))
                    Toggle("Comic impact effects", isOn: binding(\.effects))
                    Toggle("Celebration sparkles", isOn: binding(\.celebration))
                        .disabled(!model.prefs.effects || model.prefs.reducedMotion || systemReduceMotion)
                }
                .disabled(!model.prefs.animate)
            }
            SettingsGroup("Motion and visibility") {
                Toggle("Click-only mode", isOn: binding(\.clickOnly))
                Toggle("Reduced Motion", isOn: binding(\.reducedMotion))
                SettingsNote(systemReduceMotion ? "macOS Reduce Motion is on." : "Pokelet also follows macOS Reduce Motion.")
                Toggle("Wobble on sharp turns and stops", isOn: binding(\.directionBounce))
                    .disabled(model.prefs.reducedMotion || systemReduceMotion)
            }
        }
    }

    private var soundPage: some View {
        Group {
            SettingsGroup("Playback") {
                Toggle("Play click sounds", isOn: binding(\.soundEnabled))
                Picker("Click sound", selection: binding(\.sound)) {
                    ForEach(ClickSound.allCases.filter { $0 != .custom || model.prefs.customSoundName != nil ||
                        model.prefs.sound == .custom }) { Text($0.title).tag($0) }
                }
                HStack {
                    Slider(value: binding(\.volume), in: 0...1) { Text("Volume") }
                        .accessibilityValue("\(Int(model.prefs.volume * 100)) percent")
                    Text("\(Int(model.prefs.volume * 100))%").monospacedDigit().foregroundStyle(.secondary)
                        .frame(width: 42, alignment: .trailing)
                        .accessibilityHidden(true)
                }
                Button("Preview Sound") { model.previewSound() }
                    .disabled(model.prefs.sound == .silent || model.prefs.volume == 0)
            }
            SettingsGroup("Custom audio") {
                LabeledContent("Imported file", value: model.prefs.customSoundName ?? "No file imported")
                Button("Import Audio…") { model.chooseCustomSound() }
                SettingsNote("Choose a file up to 3 seconds and 5 MB. Pokelet keeps a local copy.")
                if let issue = model.audioMessage { SettingsNote(issue, warning: true) }
            }
        }
    }

    private var presentationPage: some View {
        Group {
            SettingsGroup("Click suppression") {
                if model.presentationAvailable {
                    Button(model.mode.presentation ? "End Presentation Mode" : "Start Presentation Mode") {
                        model.togglePresentation()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.accessibilityGranted && !model.mode.presentation)
                    SettingsNote("Mouse clicks animate your pointer. You can still use the keyboard to advance slides.")
                    if let issue = model.presentationMessage { SettingsNote(issue, warning: true) }
                } else {
                    Label("Disabled pending live safety testing", systemImage: "lock.shield")
                        .fontWeight(.medium)
                }
            }
            SettingsGroup("Restore clicks") {
                LabeledContent("Exit shortcut", value: "Control–Option–T")
                LabeledContent("Quick exit", value: "Escape")
                SettingsNote("Click the Pokelet menu bar indicator to end the session. From the keyboard, open the menu and choose End Presentation Mode.")
                SettingsNote("Click suppression ends automatically after 15 minutes or when your session becomes inactive.")
            }
            SettingsGroup("Permissions") {
                if model.presentationAvailable {
                    LabeledContent("Accessibility", value: model.accessibilityGranted ? "Granted" : "Required")
                    if !model.accessibilityGranted {
                        Button("Request Accessibility Access") { model.requestAccessibility() }
                    }
                    if model.needsInputMonitoring {
                        LabeledContent("Input Monitoring", value: model.inputMonitoringGranted ? "Granted" : "Required")
                        if !model.inputMonitoringGranted {
                            Button("Request Input Monitoring Access") { model.requestInputMonitoring() }
                        }
                    }
                } else {
                    SettingsNote("The pointer, click animations and sounds work independently of Presentation Mode. Permission requests are disabled in this launch.")
                }
            }
        }
        .onAppear { model.refreshPermissionStatus() }
    }

    private var aboutPage: some View {
        Group {
            SettingsGroup("Pokelet") {
                LabeledContent("Version", value: bundleVersion)
                LabeledContent("Compatibility", value: "macOS 14 or later · Apple silicon and Intel")
                Link("Project on GitHub", destination: projectURL)
                Link("MIT licence", destination: projectURL.appending(path: "blob/main/LICENSE"))
            }
            SettingsGroup("Privacy") {
                SettingsNote("Preferences and imported sounds are stored on this Mac. Pokelet has no account, telemetry or recording service.")
                Link("Privacy details", destination: projectURL.appending(path: "blob/main/PRIVACY.md"))
            }
            SettingsGroup("Credits") {
                SettingsNote("Includes MIT-licensed overlay and shortcut code adapted from Quiet Pointer.")
                Link("Quiet Pointer", destination: URL(string: "https://github.com/quietapps/QuietPointer")!)
            }
        }
    }

    private var projectURL: URL { URL(string: "https://github.com/smcnab1/pokelet")! }

    private var bundleVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(version) (\(build))"
    }

    private var customColour: Binding<Color> {
        Binding {
            let rgb = PointerArt.RGB(model.prefs.customColour ?? Preferences.defaultCustomColour)
            return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
        } set: { colour in
            guard let rgb = NSColor(colour).usingColorSpace(.sRGB) else { return }
            func byte(_ component: CGFloat) -> UInt32 { UInt32((min(1, max(0, component)) * 255).rounded()) }
            model.update(\.customColour, byte(rgb.redComponent) << 16 | byte(rgb.greenComponent) << 8 | byte(rgb.blueComponent))
        }
    }

    private func binding<T>(_ path: WritableKeyPath<Preferences, T>) -> Binding<T> {
        Binding(get: { model.prefs[keyPath: path] }, set: { model.update(path, $0) })
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 10, content: content)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(13)
                .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.primary.opacity(0.07)))
        }
    }
}

private struct SettingsNote: View {
    let message: String
    let warning: Bool

    init(_ message: String, warning: Bool = false) {
        self.message = message
        self.warning = warning
    }

    var body: some View {
        if warning {
            Label(message, systemImage: "exclamationmark.circle")
                .font(.callout).fixedSize(horizontal: false, vertical: true)
        } else {
            Text(message).font(.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
