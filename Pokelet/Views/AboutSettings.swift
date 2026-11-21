import SwiftUI

struct AboutSettings: View {
    let wide: Bool
    private let repository = URL(string: "https://github.com/smcnab1/pokelet")!
    private let website = URL(string: "https://smcnab1.github.io/pokelet/")!
    private let quietPointer = URL(string: "https://github.com/quietapps/QuietPointer")!

    private var bundleVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return build.map { "\(version) (\($0))" } ?? version
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 19) {
            HStack(spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 66, height: 66)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    StudioHeading("Pokelet", detail: "A little character for your Mac pointer.")
                    Text("Version \(bundleVersion)")
                        .studioFont(.callout)
                        .monospacedDigit()
                        .foregroundStyle(StudioTheme.secondary)
                }
                Spacer(minLength: 4)
            }
            .padding(.bottom, 6)

            Divider()
            StudioColumns(wide: wide) {
                StudioSection("Free and open source") {
                    StudioNote("For Apple silicon and Intel Macs running macOS 14 or later.")
                    link("Pokelet website", symbol: "globe", url: website)
                    link("Project on GitHub", symbol: "chevron.left.forwardslash.chevron.right", url: repository)
                    link("Releases", symbol: "arrow.down.circle", url: repository.appending(path: "releases"))
                    link("MIT licence", symbol: "doc.text", url: repository.appending(path: "blob/main/LICENSE"))
                }
                StudioSection("Privacy and credits") {
                    StudioNote("Preferences and imported sounds stay on this Mac. Pokelet has no account, telemetry or recording service.")
                    link("Privacy details", symbol: "hand.raised", url: repository.appending(path: "blob/main/PRIVACY.md"))
                    StudioNote("Includes MIT-licensed overlay and shortcut code adapted from Quiet Pointer.")
                    link("Quiet Pointer", symbol: "chevron.left.forwardslash.chevron.right", url: quietPointer)
                }
            }
        }
    }

    private func link(_ title: String, symbol: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 8) {
                Label(title, systemImage: symbol)
                    .labelStyle(.titleAndIcon)
                Spacer(minLength: 8)
                Image(systemName: "arrow.up.right")
                    .font(.caption2.weight(.semibold))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(StudioTheme.accent)
            .padding(.vertical, 3)
        }
    }
}
