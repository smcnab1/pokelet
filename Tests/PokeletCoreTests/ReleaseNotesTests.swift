import Foundation
import XCTest
@testable import PokeletCore

final class ReleaseNotesTests: XCTestCase {
    func testPublishedEntriesPreserveTagDateAndBuild() throws {
        let source = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("CHANGELOG.md")
        let releases = ReleaseNote.parse(try String(contentsOf: source, encoding: .utf8))
            .filter { ["v1.2.0-beta.1", "v1.1.0-beta.1"].contains($0.tag) }
        XCTAssertEqual(releases.map(\.tag), ["v1.2.0-beta.1", "v1.1.0-beta.1"])
        XCTAssertEqual(releases.map(\.date), ["2026-11-22", "2026-11-20"])
        XCTAssertEqual(releases.map(\.build), [3, 2])
        XCTAssertEqual(releases.first?.version, "1.2.0")
        XCTAssertEqual(releases.first?.title, "Pokelet 1.2.0 Beta 2")
        XCTAssertEqual(releases.first?.isPrerelease, true)
    }

    func testUnreleasedAndIncompleteEntriesCannotBecomeReleaseNotes() {
        let fixture = """
        ## Unreleased

        ### Added

        - Upcoming change.

        ## [v2.0.0] - 2026-11-23

        Build: 4
        Title: Pokelet 2.0.0

        ### Fixed

        - First change.

        ## [v1.5.0] - 2026-11-21

        Build: 0
        Title: Invalid

        ### Fixed

        - Incomplete metadata.
        """
        let releases = ReleaseNote.parse(fixture)
        XCTAssertEqual(releases.map(\.tag), ["v2.0.0"])
        XCTAssertEqual(releases.first?.sections.first?.items, ["First change."])
        XCTAssertEqual(releases.first?.notesMarkdown, "### Fixed\n\n- First change.\n")
    }

    func testExistingPreferencesOfferNotesBeforeTheFirstTrackedVersion() {
        let domain = "Pokelet.ReleaseNotesTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        let history = ReleaseHistory(defaults: defaults)

        XCTAssertFalse(history.shouldOffer(build: 3, hasNotes: false, hasLegacyPreferences: true))
        XCTAssertTrue(history.shouldOffer(build: 4, hasNotes: true, hasLegacyPreferences: true))
        XCTAssertTrue(history.shouldOffer(build: 4, hasNotes: true, hasLegacyPreferences: true))
        history.markSeen(build: 4)
        XCTAssertFalse(history.shouldOffer(build: 4, hasNotes: true, hasLegacyPreferences: true))
    }

    func testFirstLaunchSkippedUpgradeDismissalDowngradeAndReset() {
        let domain = "Pokelet.ReleaseNotesTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        let history = ReleaseHistory(defaults: defaults)

        XCTAssertFalse(history.shouldOffer(build: 3, hasNotes: true))
        XCTAssertFalse(history.shouldOffer(build: 3, hasNotes: true))
        XCTAssertFalse(history.shouldOffer(build: 4, hasNotes: false))
        XCTAssertTrue(history.shouldOffer(build: 9, hasNotes: true))
        XCTAssertTrue(ReleaseHistory(defaults: defaults).shouldOffer(build: 9, hasNotes: true))
        history.markSeen(build: 9)
        XCTAssertFalse(ReleaseHistory(defaults: defaults).shouldOffer(build: 9, hasNotes: true))
        XCTAssertFalse(history.shouldOffer(build: 3, hasNotes: true))
        history.markSeen(build: 3)
        XCTAssertFalse(history.shouldOffer(build: 9, hasNotes: true))

        PreferenceStore(defaults: defaults).reset()
        XCTAssertFalse(history.shouldOffer(build: 9, hasNotes: true))
        defaults.removePersistentDomain(forName: domain)
        XCTAssertFalse(history.shouldOffer(build: 9, hasNotes: true))
    }
}
