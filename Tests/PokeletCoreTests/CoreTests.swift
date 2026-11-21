import XCTest
@testable import PokeletCore

final class CoreTests: XCTestCase {
    func testClickHistoryIsRollingAndBounded() {
        var cadence = ClickCadence()
        XCTAssertEqual(cadence.record(at: 0), 1)
        XCTAssertEqual(cadence.record(at: 0.3), 2)
        XCTAssertEqual(cadence.record(at: 0.6), 3)
        XCTAssertEqual(cadence.record(at: 0.9), 3)
        for _ in 0..<50 { _ = cadence.record(at: 1) }
        XCTAssertEqual(cadence.record(at: 1.1), 8)
        XCTAssertEqual(cadence.record(at: 2), 1)
        XCTAssertEqual(cadence.record(at: 1), 1)
    }

    func testAnimationEnergyRespectsPreferenceAndCaps() {
        XCTAssertLessThan(Intensity.barelyThere.energy(clicks: 1, reactive: true),
                          Intensity.unhinged.energy(clicks: 1, reactive: true))
        XCTAssertGreaterThan(Intensity.playful.energy(clicks: 5, reactive: true),
                             Intensity.playful.energy(clicks: 1, reactive: true))
        XCTAssertEqual(Intensity.playful.energy(clicks: 6, reactive: false),
                       Intensity.playful.energy(clicks: 1, reactive: false))
        XCTAssertEqual(Intensity.unhinged.energy(clicks: 8, reactive: true),
                       Intensity.unhinged.energy(clicks: 800, reactive: true))
    }

    func testEachIntensityIncreasesAndReduceMotionPreventsCelebration() {
        let energies = Intensity.allCases.map { $0.energy(clicks: 2, reactive: true) }
        XCTAssertEqual(Set(energies).count, 5)
        XCTAssertEqual(energies, energies.sorted())
        let prefs = Preferences()
        XCTAssertTrue(ClickResponse(prefs: prefs, count: 6, reduced: false).celebration)
        XCTAssertFalse(ClickResponse(prefs: prefs, count: 6, reduced: true).celebration)
    }

    func testSettingsRoundTripAndReset() throws {
        let suite = "PokeletTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PreferenceStore(defaults: defaults)
        var prefs = store.load()
        XCTAssertFalse(prefs.soundEnabled)
        XCTAssertFalse(prefs.lastEnabled)
        prefs.style = .catPaw
        prefs.palette = .custom
        prefs.customColour = 0xAA04BB
        prefs.size = 88
        prefs.sound = .wood
        prefs.reducedMotion = true
        prefs.largerStudioText = true
        prefs.restoreEnabled = true
        prefs.lastEnabled = true
        prefs.pointerShortcut = .init(keyCode: 1, modifiers: Shortcut.pointerDefault.modifiers)
        store.save(prefs)
        XCTAssertEqual(PreferenceStore(defaults: defaults).load(), prefs)
        store.reset()
        XCTAssertEqual(store.load(), Preferences())
    }

    func testVersionOnePreferencesWithoutCustomColourArePreserved() throws {
        let suite = "PokeletTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PreferenceStore(defaults: defaults)
        var original = Preferences()
        original.palette = .mint
        original.keepNative = false
        original.restoreEnabled = true
        original.size = 99
        let encoded = try JSONEncoder().encode(original)
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        legacy.removeValue(forKey: "customColour")
        defaults.set(try JSONSerialization.data(withJSONObject: legacy), forKey: PreferenceStore.key)
        XCTAssertEqual(store.load(), original)
    }

    func testMalformedSettingsAndRangeRecovery() throws {
        let suite = "PokeletTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PreferenceStore(defaults: defaults)
        defaults.set(Data([0, 1, 2]), forKey: PreferenceStore.key)
        XCTAssertEqual(store.load(), Preferences())
        var prefs = Preferences()
        prefs.size = 1000
        prefs.volume = -1
        store.save(prefs)
        XCTAssertEqual(store.load().size, Preferences.sizeRange.upperBound)
        XCTAssertEqual(store.load().volume, 0)
    }

    func testPresentationRequiresVerifiedTapAndDoesNotChangePointerIntent() {
        var mode = InteractionMode()
        XCTAssertFalse(mode.startPresentation(tapReady: false))
        XCTAssertFalse(mode.showsPointer)
        XCTAssertTrue(mode.startPresentation(tapReady: true))
        XCTAssertTrue(mode.showsPointer)
        XCTAssertTrue(mode.presentation)
        mode.stopPresentation()
        XCTAssertFalse(mode.showsPointer)
        mode.setPointer(true)
        XCTAssertTrue(mode.startPresentation(tapReady: true))
        mode.stopPresentation()
        XCTAssertTrue(mode.showsPointer)
        _ = mode.startPresentation(tapReady: true)
        mode.setPointer(false)
        XCTAssertFalse(mode.presentation)
        XCTAssertFalse(mode.showsPointer)
    }

    func testSuppressionKeepsExistingDragsAndPairsSuppressedButtons() {
        var buttons = PresentationButtons()
        XCTAssertFalse(buttons.blocks(button: 0, phase: .drag))
        XCTAssertFalse(buttons.blocks(button: 0, phase: .up))
        XCTAssertTrue(buttons.blocks(button: 0, phase: .down))
        XCTAssertTrue(buttons.blocks(button: 0, phase: .drag))
        XCTAssertTrue(buttons.blocks(button: 0, phase: .up))
        XCTAssertFalse(buttons.blocks(button: 0, phase: .up))
        XCTAssertTrue(buttons.blocks(button: 1, phase: .down))
        XCTAssertFalse(buttons.blocks(button: 0, phase: .drag))
    }
}
