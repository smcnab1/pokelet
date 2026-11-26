import SwiftUI

struct PrivacyAnalyticsSettings: View {
    @ObservedObject var analytics: UsageAnalytics

    var body: some View {
        StudioSection("Privacy & Analytics") {
            StudioNote("Sam McNab uses optional reports to count active installations and see which Pokelet versions they run. Sharing is off by default.")
            StudioNote("If you agree, Pokelet sends TelemetryDeck a hashed random installation code, the app version and build, and whether this is your first report. The code links reports from this installation. The service sees your IP address while receiving the request.")
            StudioSwitch("Share basic usage", isOn: Binding(
                get: { analytics.isEnabled },
                set: { analytics.setEnabled($0) }
            ))
            .disabled(!analytics.isAvailable)

            StudioNote("Pokelet attempts one report per UTC day at most. Turn sharing off here to stop reporting and clear your local code. Reports already received remain subject to the privacy notice.")
            if !analytics.isAvailable {
                StudioNote("Usage reporting is unavailable in this installation.")
            }
            Link("Read the privacy policy", destination: URL(string: "https://smcnab1.github.io/pokelet/privacy/")!)
        }
    }
}
