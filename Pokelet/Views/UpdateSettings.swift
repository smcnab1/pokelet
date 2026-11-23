import SwiftUI

struct UpdateSettings: View {
    @ObservedObject var updates: UpdateService
    let presentation: Bool
    let showWhatsNew: () -> Void

    private var status: String {
        if !updates.isAvailable { return "This build uses manual updates." }
        if let pendingVersion = updates.pendingVersion { return "Pokelet \(pendingVersion) is available." }
        if updates.sessionInProgress { return "An update check or installation is in progress." }
        if let result = updates.result { return result.message }
        return updates.checksBetaFeed ? "Pokelet checks for beta releases." : "Pokelet checks for stable releases."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 19) {
            StudioHeading("Updates", detail: "Version \(updates.version) (build \(updates.build))")

            Divider()
            StudioSection("Software Update") {
                let warning = updates.result.map { $0 != .noUpdate } ?? false
                StudioNote(status, symbol: warning ? "exclamationmark.circle" : nil, warning: warning)
                if let lastCheck = updates.lastCheck {
                    Text("Last check attempt: \(lastCheck, format: .dateTime.month(.abbreviated).day().year().hour().minute())")
                        .studioFont(.callout)
                        .foregroundStyle(StudioTheme.secondary)
                }
                if updates.isAvailable {
                    Button(updates.pendingVersion == nil ? "Check for Updates…" : "View Update…", action: updates.checkForUpdates)
                        .buttonStyle(.bordered)
                        .disabled(!updates.canCheck || presentation)
                    if presentation {
                        StudioNote("End Presentation Mode before opening the update window.")
                    }
                    StudioSwitch("Automatically check for updates", isOn: Binding(
                        get: { updates.automaticallyChecks }, set: updates.setAutomaticChecks
                    ))
                    StudioNote("Pokelet checks in the background and waits for you to open and install an available update.")
                }
                if !updates.isAvailable || warning {
                    Link("Download from GitHub Releases", destination: GitHubFeedback.repository.appending(path: "releases"))
                        .studioFont(.callout)
                }
            }

            Divider()
            StudioSection("Release notes") {
                if updates.offersWhatsNew {
                    StudioNote("See what changed in this version.", symbol: "sparkle")
                }
                Button("What’s New & Version History…", action: showWhatsNew)
                    .buttonStyle(.bordered)
            }
        }
    }
}

struct WhatsNewView: View {
    let version: String
    let current: ReleaseNote?
    let history: [ReleaseNote]
    let windowHeight: CGFloat
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StudioHeading("What’s New", detail: "Version \(version)")
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    if let current {
                        release(current)
                    } else {
                        StudioNote("Release notes aren’t bundled for this build.")
                    }
                    let older = history.filter { $0.id != current?.id }
                    if !older.isEmpty {
                        Divider()
                        Text("Version history")
                            .studioFont(.headline)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(older) { release($0) }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 9)
            }
            Divider()
            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(22)
        .frame(width: 500, height: min(540, max(350, windowHeight - 60)))
        .studioFont(.body)
        .background(StudioTheme.window)
    }

    private func release(_ note: ReleaseNote) -> some View {
        StudioSection(note.title) {
            StudioNote("Build \(note.build) · \(note.date)")
            ForEach(note.sections) { section in
                VStack(alignment: .leading, spacing: 5) {
                    Text(section.title)
                        .studioFont(.callout, weight: .semibold)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(Array(section.items.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .firstTextBaseline, spacing: 7) {
                            Text("•").accessibilityHidden(true)
                            Text(item).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            Link("View \(note.title) on GitHub", destination: GitHubFeedback.repository.appending(path: "releases/tag/\(note.tag)"))
                .studioFont(.callout)
        }
    }
}
