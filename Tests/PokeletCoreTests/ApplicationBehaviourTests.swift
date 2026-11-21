import XCTest
@testable import PokeletCore

final class ApplicationBehaviourTests: XCTestCase {
    func testDefaultDockFollowsRepeatedStudioOpenCloseAndReopen() {
        let behaviour = Preferences().applicationBehaviour
        XCTAssertTrue(behaviour.hideDockWhenStudioClosed)
        XCTAssertTrue(behaviour.showInMenuBar)

        for _ in 0..<4 {
            XCTAssertTrue(behaviour.showsDock(studioOpen: true, menuBarAvailable: true))
            XCTAssertFalse(behaviour.showsDock(studioOpen: false, menuBarAvailable: true))
            XCTAssertTrue(behaviour.showsDock(studioOpen: true, menuBarAvailable: true))
        }
    }

    func testDockStaysAvailableWithoutAnAccessibleStatusItem() {
        var behaviour = ApplicationBehaviour()
        XCTAssertTrue(behaviour.showsDock(studioOpen: false, menuBarAvailable: false))

        behaviour.showInMenuBar = false
        XCTAssertTrue(behaviour.showsDock(studioOpen: false, menuBarAvailable: true))
        XCTAssertTrue(behaviour.showsDock(studioOpen: false, menuBarAvailable: false))
        XCTAssertTrue(behaviour.hideDockWhenStudioClosed)

        behaviour.showInMenuBar = true
        XCTAssertFalse(behaviour.showsDock(studioOpen: false, menuBarAvailable: true))
    }

    func testApplicationBehaviourPersistsAndResetRestoresDefaults() throws {
        let suite = "PokeletTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PreferenceStore(defaults: defaults)
        var prefs = store.load()
        prefs.applicationBehaviour.hideDockWhenStudioClosed = false
        prefs.applicationBehaviour.showInMenuBar = false
        store.save(prefs)

        var relaunched = PreferenceStore(defaults: try XCTUnwrap(UserDefaults(suiteName: suite))).load()
        XCTAssertEqual(relaunched.applicationBehaviour, prefs.applicationBehaviour)
        relaunched.applicationBehaviour.showInMenuBar = true
        XCTAssertTrue(relaunched.applicationBehaviour.showsDock(studioOpen: false, menuBarAvailable: true))

        store.reset()
        XCTAssertEqual(store.load().applicationBehaviour, ApplicationBehaviour())
    }

    func testLegacySettingsKeepExistingValuesAndInheritVisibilityDefaults() throws {
        let suite = "PokeletTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PreferenceStore(defaults: defaults)
        var prefs = Preferences()
        prefs.style = .catPaw
        prefs.restoreEnabled = true
        prefs.lastEnabled = true
        prefs.applicationBehaviour.showInMenuBar = false
        let encoded = try JSONEncoder().encode(prefs)
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertNotNil(legacy.removeValue(forKey: "savedApplicationBehaviour"))
        defaults.set(try JSONSerialization.data(withJSONObject: legacy), forKey: PreferenceStore.key)

        let migrated = store.load()
        XCTAssertEqual(migrated.style, .catPaw)
        XCTAssertTrue(migrated.restoreEnabled)
        XCTAssertTrue(migrated.lastEnabled)
        XCTAssertEqual(migrated.applicationBehaviour, ApplicationBehaviour())
    }
}
