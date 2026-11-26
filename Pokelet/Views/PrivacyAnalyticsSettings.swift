import SwiftUI

struct PrivacyAnalyticsSettings: View {
    @ObservedObject var analytics: UsageAnalytics

    var body: some View {
        StudioSection("Privacy & Analytics") {
            StudioNote("Help Sam McNab count new reporting installations, daily activity and app versions. If you opt in, Pokelet sends TelemetryDeck your version and build and whether this is your first report, at most once a day.")
            StudioSwitch("Share basic usage", isOn: Binding(
                get: { analytics.isEnabled },
                set: { analytics.setEnabled($0) }
            ))
            .disabled(!analytics.isAvailable)

            StudioNote("Reports have no installation identifier. Turn sharing off here at any time.")
            if !analytics.isAvailable {
                StudioNote("Usage reporting is unavailable in this installation.")
            }
            Link("Read the privacy policy", destination: URL(string: "https://smcnab1.github.io/pokelet/privacy/")!)
        }
    }
}
