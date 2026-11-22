import SwiftUI

struct PresentationSettings: View {
    @ObservedObject var model: AppModel
    let wide: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 19) {
            StudioHeading("Presentation", detail: "Pause mouse clicks while you present. Keep using the keyboard to advance slides.")
            StudioColumns(wide: wide) {
                recovery
                availability
                    .frame(width: wide ? 310 : nil, alignment: .leading)
            }
        }
        .onAppear { model.refreshPermissionStatus() }
    }

    private var availability: some View {
        VStack(alignment: .leading, spacing: 15) {
            StudioSection("Click suppression") {
                if model.presentationAvailable {
                    if model.mode.presentation {
                        Button("End Presentation Mode") { model.endPresentation(nil) }
                            .buttonStyle(.borderedProminent)
                    } else {
                        Button("Start Presentation Mode") { model.startPresentation() }
                            .buttonStyle(.borderedProminent)
                            .disabled(!model.accessibilityGranted)
                    }
                    StudioNote("While clicks are paused, they still animate your Pokelet character.")
                    if let issue = model.presentationMessage {
                        StudioNote(issue, symbol: "exclamationmark.circle", warning: true)
                    }
                } else {
                    StudioLabel("Unavailable in this build", symbol: "lock.shield")
                        .fontWeight(.medium)
                    StudioNote("You can still use your character, click animations and sounds.")
                }
            }
            Divider()
            StudioSection("Presentation pointer") {
                StudioSwitch("Use Presenter Arm during presentations",
                             isOn: model.preference(\.presenterEffects.presentation))
                    .disabled(!model.presentationAvailable)
                StudioNote("This setting applies only during an active presentation.")
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
    }

    private var recovery: some View {
        VStack(alignment: .leading, spacing: 12) {
            StudioLabel("Restore clicks", symbol: "shield.lefthalf.filled")
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
        .padding(19)
        .background(StudioTheme.selection.opacity(0.63), in: RoundedRectangle(cornerRadius: 15))
    }

    private func keycap(_ title: String, spoken: String) -> some View {
        Text(title)
            .studioFont(.body, weight: .semibold)
            .monospaced()
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(StudioTheme.selection, in: RoundedRectangle(cornerRadius: 6))
            .accessibilityLabel(spoken)
    }
}
