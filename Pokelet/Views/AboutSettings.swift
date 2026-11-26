import SwiftUI

struct AboutSettings: View {
    let wide: Bool
    let diagnostics: FeedbackDiagnostics
    @Environment(\.openURL) private var openURL
    @State private var copyMessage: String?
    @State private var browserMessage: String?
    private let repository = GitHubFeedback.repository
    private let website = URL(string: "https://smcnab1.github.io/pokelet/")!
    private let quietPointer = URL(string: "https://github.com/quietapps/QuietPointer")!

    var body: some View {
        VStack(alignment: .leading, spacing: 19) {
            HStack(spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 66, height: 66)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    StudioHeading("Pokelet", detail: "A little character for your Mac pointer.")
                    Text("Version \(diagnostics.version)")
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
                    VStack(spacing: 2) {
                        link("Pokelet website", symbol: "globe", url: website)
                        link("Project on GitHub", symbol: "book.closed", url: repository)
                        link("Releases", symbol: "arrow.down.circle", url: repository.appending(path: "releases"))
                        link("MIT licence", symbol: "doc.text", url: repository.appending(path: "blob/main/LICENSE"))
                    }
                }
                StudioSection("Privacy and credits") {
                    StudioNote("Preferences and imported sounds stay on this Mac. Optional usage reporting is off by default. Manage it in General.")
                    link("Privacy details", symbol: "hand.raised", url: repository.appending(path: "blob/main/PRIVACY.md"))
                    StudioNote("Includes MIT-licensed overlay and shortcut code adapted from Quiet Pointer.")
                    link("Quiet Pointer", symbol: "hand.point.up.left", url: quietPointer)
                }
            }
            Divider()
            feedback
        }
    }

    private var feedback: some View {
        StudioSection("Help & Feedback") {
            StudioColumns(wide: wide) {
                Button(action: reportProblem) {
                    linkLabel("Report a problem", symbol: "ladybug", detail: "Something not working? Let us know.")
                }
                .buttonStyle(StudioButtonStyle(radius: 8))
                .help("Open the GitHub bug form with basic system information")
                Link(destination: GitHubFeedback.Form.feature.url) {
                    linkLabel("Request a feature", symbol: "lightbulb", detail: "Have an idea for Pokelet? Suggest it.")
                }
                .buttonStyle(StudioButtonStyle(radius: 8))
            }
            StudioNote("The bug form includes your app version, macOS version, Mac architecture and pointer settings for you to review before submitting.")
            Button {
                copyMessage = GitHubFeedback.copy(diagnostics.summary)
                    ? "System information copied." : "Could not copy system information."
            } label: {
                StudioLabel("Copy system information", symbol: "doc.on.doc")
            }
            if let copyMessage { StudioNote(copyMessage) }
            if let browserMessage { StudioNote(browserMessage, symbol: "exclamationmark.circle", warning: true) }
        }
    }

    private func reportProblem() {
        browserMessage = nil
        GitHubFeedback.openBugForm(diagnostics: diagnostics.summary, open: { url, completion in
            openURL(url, completion: completion)
        }) { result in
            switch result {
            case .openedWithDiagnostics: browserMessage = nil
            case .openedWithoutDiagnostics: browserMessage = "Use Copy system information to fill in the form."
            case .couldNotOpen: browserMessage = "The browser could not open the bug form."
            }
        }
    }

    private func link(_ title: String, symbol: String, url: URL) -> some View {
        Link(destination: url) { linkLabel(title, symbol: symbol) }
            .buttonStyle(StudioButtonStyle(radius: 8))
    }

    private func linkLabel(_ title: String, symbol: String, detail: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            StudioLabel(title, symbol: symbol, detail: detail)
                .studioFont(.body, weight: detail == nil ? .regular : .semibold)
            Spacer(minLength: 4)
            Image(systemName: "arrow.up.right")
                .font(.caption2.weight(.semibold))
                .accessibilityHidden(true)
        }
        .foregroundStyle(StudioTheme.accent)
        .padding(.horizontal, 7)
        .padding(.vertical, detail == nil ? 4 : 8)
        .frame(minHeight: detail == nil ? 27 : 52)
        .background {
            if detail != nil { RoundedRectangle(cornerRadius: 8).fill(StudioTheme.surface) }
        }
    }
}
