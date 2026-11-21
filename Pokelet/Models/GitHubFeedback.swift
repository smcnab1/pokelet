import AppKit

enum GitHubFeedback {
    static let repository = URL(string: "https://github.com/smcnab1/pokelet")!

    enum Form: String {
        case bug = "bug_report.yml"
        case feature = "feature_request.yml"

        var url: URL { GitHubFeedback.url(for: self, diagnostics: nil)! }
    }

    static func bugURL(diagnostics: String) -> URL {
        guard let prefilled = url(for: .bug, diagnostics: diagnostics),
              prefilled.absoluteString.utf8.count <= 1_800 else { return Form.bug.url }
        return prefilled
    }

    enum BugFormResult {
        case openedWithDiagnostics, openedWithoutDiagnostics, couldNotOpen
    }

    static func openBugForm(
        diagnostics: String,
        open: @escaping (URL, @escaping (Bool) -> Void) -> Void,
        result: @escaping (BugFormResult) -> Void
    ) {
        let plain = Form.bug.url
        let prepared = bugURL(diagnostics: diagnostics)
        func openPlain() {
            open(plain) { result($0 ? .openedWithoutDiagnostics : .couldNotOpen) }
        }

        if prepared == plain {
            openPlain()
        } else {
            open(prepared) { accepted in
                if accepted { result(.openedWithDiagnostics) }
                else { openPlain() }
            }
        }
    }

    private static func url(for form: Form, diagnostics: String?) -> URL? {
        guard var url = URLComponents(url: repository.appending(path: "issues/new"), resolvingAgainstBaseURL: false) else { return nil }
        var items = [URLQueryItem(name: "template", value: form.rawValue)]
        if let diagnostics { items.append(URLQueryItem(name: "environment", value: diagnostics)) }
        url.queryItems = items
        // Form decoders treat a bare + in a query as a space.
        url.percentEncodedQuery = url.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return url.url
    }

    static func copy(_ diagnostics: String, to pasteboard: NSPasteboard = .general) -> Bool {
        pasteboard.clearContents()
        return pasteboard.setString(diagnostics, forType: .string)
    }
}

struct FeedbackDiagnostics {
    let prefs: Preferences
    let presentation: Bool
    var bundle: Bundle = .main
    var operatingSystem: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion

    var version: String {
        let release = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return build.map { "\(release) (\($0))" } ?? release
    }

    var summary: String {
        let arm = prefs.usesPresenterArm(presentation: presentation)
        let displayMode = arm ? "Presenter Arm" :
            prefs.clickOnly && !presentation ? "Click only" : prefs.keepNative ? "Companion" : "Replace in Studio"
        let os = operatingSystem
        return [
            "Pokelet: \(version)",
            "macOS: \(os.majorVersion).\(os.minorVersion).\(os.patchVersion)",
            "Architecture: \(Self.architecture)",
            "Character: \(arm ? "Presenter Arm" : prefs.style.title)",
            "Display mode: \(displayMode)",
            "Presenter Arm: \(arm ? "On" : "Off")",
            "Presentation Mode: \(presentation ? "Active" : "Off")"
        ].joined(separator: "\n")
    }

    private static var architecture: String {
        // The hardware value also identifies Apple silicon under Rosetta.
        var arm64: Int32 = 0
        var size = MemoryLayout.size(ofValue: arm64)
        if sysctlbyname("hw.optional.arm64", &arm64, &size, nil, 0) == 0, arm64 == 1 {
            return "Apple silicon"
        }
        #if arch(arm64)
        return "Apple silicon"
        #else
        return "Intel"
        #endif
    }
}
