import SwiftUI

struct PrivacyAnalyticsSettings: View {
    @ObservedObject var analytics: UsageAnalytics

    var body: some View {
        StudioSection("Privacy & Analytics") {
            StudioNote("Help estimate how many installations use Pokelet and which versions they run. Pokelet works the same with reporting off.")
            StudioNote("If you opt in, TelemetryDeck receives a random installation code in hashed form, the Pokelet version and build, and whether this is the first report. Pokelet sends at most one report per UTC day. TelemetryDeck hosts the reports in Germany and Finland.")
            StudioSwitch("Share basic usage", isOn: Binding(
                get: { analytics.isEnabled },
                set: { analytics.setEnabled($0) }
            ))
            .disabled(!analytics.isAvailable)

            if analytics.isAvailable {
                StudioNote("Turn this off at any time to stop sending reports and clear the installation code from this Mac.")
            } else {
                StudioNote("Usage reporting is unavailable in this installation.")
            }

            Divider()
            StudioSwitch("Share additional diagnostics", isOn: .constant(false))
                .disabled(true)
            StudioNote("Automatic diagnostics are unavailable.")
            Link("Read the privacy policy", destination: URL(string: "https://smcnab1.github.io/pokelet/privacy/")!)
        }
    }
}
