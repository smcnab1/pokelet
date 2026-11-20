import XCTest
@testable import PokeletCore

final class PresentationSafetyTests: XCTestCase {
    func testRequiresReadyTapAndBothRecoveryPaths() {
        var session = PresentationSession()
        XCTAssertFalse(session.arm(tapReady: false, shortcutReady: true, now: 0))
        XCTAssertFalse(session.arm(tapReady: true, shortcutReady: false, now: 0))
        XCTAssertFalse(session.suppresses(button: 0, phase: .down))
        XCTAssertTrue(session.arm(tapReady: true, shortcutReady: true, now: 0))
        XCTAssertTrue(session.suppresses(button: 0, phase: .down))
    }

    func testExitDrainsOnlyPreviouslySuppressedGestures() {
        var session = PresentationSession()
        XCTAssertTrue(session.arm(tapReady: true, shortcutReady: true, now: 10))
        XCTAssertFalse(session.suppresses(button: 2, phase: .drag))
        XCTAssertTrue(session.suppresses(button: 0, phase: .down))
        XCTAssertTrue(session.suppresses(button: 1, phase: .down))
        session.end(now: 11)
        session.end(now: 11.5)
        XCTAssertFalse(session.isActive)
        XCTAssertTrue(session.isDraining)
        XCTAssertFalse(session.arm(tapReady: true, shortcutReady: true, now: 11.5))
        XCTAssertFalse(session.suppresses(button: 2, phase: .down))
        XCTAssertFalse(session.suppresses(button: 2, phase: .up))
        XCTAssertTrue(session.suppresses(button: 0, phase: .drag))
        XCTAssertTrue(session.suppresses(button: 0, phase: .up))
        XCTAssertTrue(session.suppresses(button: 1, phase: .up))
        XCTAssertFalse(session.isDraining)
    }

    func testUnhealthyTapAndLeaseBothFailOpen() {
        var session = PresentationSession()
        XCTAssertTrue(session.arm(tapReady: true, shortcutReady: true, now: 10))
        XCTAssertTrue(session.suppresses(button: 0, phase: .down))
        XCTAssertEqual(session.recovery(tapHealthy: false, now: 11), .tapUnavailable)
        session.reset()
        XCTAssertFalse(session.suppresses(button: 0, phase: .up))
        XCTAssertTrue(session.arm(tapReady: true, shortcutReady: true, now: 10))
        XCTAssertNil(session.recovery(tapHealthy: true, now: 11))
        XCTAssertEqual(session.recovery(tapHealthy: true, now: 10 + PresentationSession.maximumDuration), .leaseExpired)
    }

    func testFreshDownReleasesAnUnpairedGestureDuringDrain() {
        var session = PresentationSession()
        XCTAssertTrue(session.arm(tapReady: true, shortcutReady: true, now: 10))
        XCTAssertTrue(session.suppresses(button: 0, phase: .down))
        session.end(now: 11)
        XCTAssertFalse(session.suppresses(button: 0, phase: .down))
        XCTAssertFalse(session.isDraining)
        XCTAssertFalse(session.suppresses(button: 0, phase: .up))
    }

    func testMissingReleaseCannotLeaveTapDrainingIndefinitely() {
        var session = PresentationSession()
        XCTAssertTrue(session.arm(tapReady: true, shortcutReady: true, now: 10))
        XCTAssertTrue(session.suppresses(button: 0, phase: .down))
        session.end(now: 11)
        XCTAssertEqual(session.recovery(tapHealthy: true, now: 12), .drainExpired)
        session.reset()
        XCTAssertFalse(session.suppresses(button: 0, phase: .drag))
        XCTAssertTrue(session.arm(tapReady: true, shortcutReady: true, now: 12))
    }
}
