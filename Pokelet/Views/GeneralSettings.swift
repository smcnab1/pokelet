import ServiceManagement
import SwiftUI

struct GeneralSettings: View {
    @ObservedObject var model: AppModel
    let wide: Bool
    @State private var confirmReset = false

    var body: some View {
        VStack(alignment: .leading, spacing: 19) {
            StudioHeading("General", detail: "Manage startup, Dock and menu bar visibility, and global shortcuts.")
            StudioColumns(wide: wide) {
                VStack(alignment: .leading, spacing: 17) {
                    StudioSection("Startup") {
                        StudioSwitch("Launch at login", isOn: Binding(
                            get: { model.loginStatus == .enabled || model.loginStatus == .requiresApproval },
                            set: model.toggleLaunchAtLogin
                        ))
                        .disabled(model.isStudioAcceptance)
                        if model.loginStatus == .requiresApproval {
                            StudioNote("Approve Pokelet in Login Items to finish enabling this setting.")
                            Button("Open Login Items") { SMAppService.openSystemSettingsLoginItems() }
                        }
                        StudioSwitch("Restore pointer state on launch", isOn: model.preference(\.restoreEnabled))
                        if let issue = model.generalMessage {
                            StudioNote(issue, symbol: "exclamationmark.circle", warning: true)
                        }
                    }
                    Divider()
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
                }
                VStack(alignment: .leading, spacing: 17) {
                    StudioSection("Application behaviour") {
                        StudioSwitch("Show Pokelet in the menu bar", isOn: model.preference(\.applicationBehaviour.showInMenuBar))
                        StudioNote("Keep Pokelet accessible from the macOS menu bar.")
                        StudioSwitch("Hide Dock icon when Studio is closed", isOn: model.preference(\.applicationBehaviour.hideDockWhenStudioClosed))
                            .disabled(!model.prefs.applicationBehaviour.showInMenuBar)
                        if model.prefs.applicationBehaviour.showInMenuBar {
                            StudioNote("When Studio is closed, keep Pokelet running in the menu bar without showing its Dock icon.")
                        } else {
                            StudioNote("The Dock icon stays visible while the menu bar icon is off, so you can reopen Studio.")
                        }
                    }
                    Divider()
                    StudioSection("Accessibility") {
                        StudioSwitch("Larger Studio text", isOn: Binding(
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
                .frame(maxWidth: .infinity, alignment: .leading)
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
