import AppKit
import XCTest
@testable import PokeletCore

final class FeedbackTests: XCTestCase {
    func testPrefillTargetsOneFieldAndEncodesPunctuationAndLineBreaks() throws {
        let summary = "Pokelet: 1.2.0+build (3)\nCharacter: A & B #1 ?= café"
        let url = GitHubFeedback.bugURL(diagnostics: summary)
        let parts = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(parts.scheme, "https")
        XCTAssertEqual(parts.host, "github.com")
        XCTAssertEqual(parts.path, "/smcnab1/pokelet/issues/new")
        XCTAssertEqual(parts.queryItems, [
            URLQueryItem(name: "template", value: "bug_report.yml"),
            URLQueryItem(name: "environment", value: summary)
        ])
        XCTAssertTrue(url.absoluteString.contains("%2B"))
        XCTAssertTrue(url.absoluteString.contains("%0A"))
        XCTAssertFalse(url.absoluteString.contains("#"))
        XCTAssertEqual(GitHubFeedback.Form.feature.url.absoluteString,
                       "https://github.com/smcnab1/pokelet/issues/new?template=feature_request.yml")
        XCTAssertEqual(GitHubFeedback.bugURL(diagnostics: String(repeating: "?", count: 2_000)),
                       GitHubFeedback.Form.bug.url)
    }

    func testRuntimeDiagnosticsUseOnlyTheAllowedFields() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".bundle")
        let contents = directory.appending(path: "Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let plist = ["CFBundleIdentifier": "uk.co.sammcnab.Pokelet.FeedbackTest",
                     "CFBundleShortVersionString": "9.8.7", "CFBundleVersion": "42"]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: contents.appending(path: "Info.plist"))
        let bundle = try XCTUnwrap(Bundle(url: directory))
        var prefs = Preferences()
        prefs.style = .catPaw
        prefs.customSoundName = "personal@example.org"
        prefs.keepNative = false
        prefs.presenterEffects.presentation = true
        let diagnostics = FeedbackDiagnostics(prefs: prefs, presentation: false, bundle: bundle)
        let system = ProcessInfo.processInfo.operatingSystemVersion
        let lines = diagnostics.summary.components(separatedBy: "\n")
        XCTAssertEqual(lines, [
            "Pokelet: 9.8.7 (42)",
            "macOS: \(system.majorVersion).\(system.minorVersion).\(system.patchVersion)",
            try XCTUnwrap(lines.first(where: { ["Architecture: Apple silicon", "Architecture: Intel"].contains($0) })),
            "Character: Cat Paw", "Display mode: Replace in Studio", "Presenter Arm: Off", "Presentation Mode: Off"
        ])
        let presentation = FeedbackDiagnostics(prefs: prefs, presentation: true)
        XCTAssertTrue(presentation.summary.contains("Character: Presenter Arm\nDisplay mode: Presenter Arm"))
        XCTAssertTrue(presentation.summary.hasSuffix("Presenter Arm: On\nPresentation Mode: Active"))
    }

    func testExternalOpeningFallsBackToPlainFormAndNeverSubmits() {
        var opened: [URL] = []
        var result: GitHubFeedback.BugFormResult?
        let summary = "Pokelet: 1.1.0 (2)"
        GitHubFeedback.openBugForm(diagnostics: summary, open: { url, completion in
            opened.append(url)
            completion(opened.count > 1)
        }, result: { result = $0 })
        XCTAssertEqual(opened, [GitHubFeedback.bugURL(diagnostics: summary), GitHubFeedback.Form.bug.url])
        XCTAssertEqual(result, .openedWithoutDiagnostics)

        opened.removeAll()
        GitHubFeedback.openBugForm(diagnostics: summary, open: { url, completion in
            opened.append(url)
            completion(true)
        }, result: { result = $0 })
        XCTAssertEqual(opened, [GitHubFeedback.bugURL(diagnostics: summary)])
        XCTAssertEqual(result, .openedWithDiagnostics)
    }

    func testCopyWritesTheSameTextToATemporaryPasteboard() {
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        let summary = FeedbackDiagnostics(prefs: Preferences(), presentation: false).summary
        XCTAssertTrue(GitHubFeedback.copy(summary, to: board))
        XCTAssertEqual(board.string(forType: .string), summary)
    }
}
