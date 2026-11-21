import SwiftUI

struct PresentationSettings: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 19) {
            StudioHeading("Presentation", detail: "Pause mouse clicks while you present. Keep using the keyboard to advance slides.")
            recovery
            StudioSection("Click suppression") {
                if model.presentationAvailable {
                    Button(model.mode.presentation ? "End Presentation Mode" : "Start Presentation Mode") {
                        model.togglePresentation()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.accessibilityGranted && !model.mode.presentation)
                    StudioNote("While clicks are paused, they still animate your Pokelet character.")
                    if let issue = model.presentationMessage {
                        StudioNote(issue, symbol: "exclamationmark.circle", warning: true)
                    }
                } else {
                    Label("Unavailable in this build", systemImage: "lock.shield")
                        .fontWeight(.medium)
                    StudioNote("You can still use your character, click animations and sounds.")
                }
            }
            if model.presentationAvailable {
                Divider()
                StudioSection("Permissions") {
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
                }
            }
        }
        .onAppear { model.refreshPermissionStatus() }
    }

    private var recovery: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Restore clicks", systemImage: "arrow.uturn.backward.circle")
                .studioFont(.headline)
                .foregroundStyle(StudioTheme.accent)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 8) {
                keycap("Esc", spoken: "Escape")
                Text("or").foregroundStyle(StudioTheme.secondary)
                keycap("⌃⌥T", spoken: "Control–Option–T")
            }
            StudioNote("You can also click the Pokelet indicator in the menu bar or use its End Presentation Mode command.")
            StudioNote("Clicks resume after 15 minutes or when your Mac session becomes inactive.", symbol: "clock")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .studioSurface()
    }

    private func keycap(_ title: String, spoken: String) -> some View {
        Text(title)
            .font(.body.monospaced().weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(StudioTheme.selection, in: RoundedRectangle(cornerRadius: 6))
            .accessibilityLabel(spoken)
    }
}
