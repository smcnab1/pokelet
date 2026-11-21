import ServiceManagement
import SwiftUI

struct GeneralSettings: View {
    @ObservedObject var model: AppModel
    @State private var confirmReset = false

    var body: some View {
        VStack(alignment: .leading, spacing: 19) {
            StudioHeading("General", detail: "Manage startup and the shortcuts you use from any app.")
            StudioSection("Startup") {
                Toggle("Launch at login", isOn: Binding(
                    get: { model.loginStatus == .enabled || model.loginStatus == .requiresApproval },
                    set: model.toggleLaunchAtLogin
                ))
                if model.loginStatus == .requiresApproval {
                    StudioNote("Approve Pokelet in Login Items to finish enabling this setting.")
                    Button("Open Login Items") { SMAppService.openSystemSettingsLoginItems() }
                }
                Toggle("Restore pointer state on launch", isOn: model.preference(\.restoreEnabled))
                StudioNote("Pokelet stays in the menu bar when you close Studio.", symbol: "menubar.rectangle")
                if let issue = model.generalMessage {
                    StudioNote(issue, symbol: "exclamationmark.circle", warning: true)
                }
            }
            .padding(15)
            .studioSurface()

            StudioSection("Global shortcuts") {
                ShortcutField(label: "Toggle pointer", shortcut: model.prefs.pointerShortcut) {
                    model.setShortcut($0, presentation: false)
                }
                if model.presentationAvailable {
                    Divider()
                    ShortcutField(label: "Alternate presentation shortcut", shortcut: model.prefs.presentationShortcut) {
                        model.setShortcut($0, presentation: true)
                    }
                    .disabled(model.mode.presentation)
                    StudioNote("Control–Option–T remains available to end an active presentation.", symbol: "shield")
                }
                if let issue = model.shortcutMessage {
                    StudioNote(issue, symbol: "exclamationmark.circle", warning: true)
                }
            }
            Divider()
            StudioSection("Accessibility") {
                Toggle("Larger Studio text", isOn: Binding(
                    get: { model.prefs.largerStudioText == true },
                    set: { model.update(\.largerStudioText, $0 ? true : nil) }
                ))
            }
            Divider()
            StudioSection("Reset") {
                StudioNote("Restore the original settings and remove any imported click sound.")
                Button("Reset Settings…") { confirmReset = true }
            }
        }
        .alert("Reset Pokelet?", isPresented: $confirmReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Settings", role: .destructive) { model.reset() }
        } message: {
            Text("This turns the pointer off, restores the default shortcuts and removes any imported sound.")
        }
    }
}
