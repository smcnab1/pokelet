import AppKit
import XCTest
@testable import PokeletCore

final class CursorSafetyTests: XCTestCase {
    func testHideAndShowAreBalancedAcrossRepeatedDecisions() {
        var state = CursorVisibility()
        var hides = 0
        var shows = 0
        for eligible in [false, true, true, false, false, true, false] {
            state.update(eligible: eligible, hide: { hides += 1; return true }, show: { shows += 1; return true })
        }
        XCTAssertEqual(hides, 2)
        XCTAssertEqual(shows, 2)
        XCTAssertFalse(state.ownsHide)
    }

    func testHideFailureFallsBackUntilEligibilityChanges() {
        var state = CursorVisibility()
        var hides = 0
        for eligible in [true, true, false, true] {
            state.update(eligible: eligible, hide: { hides += 1; return false }, show: { XCTFail(); return false })
            XCTAssertFalse(state.ownsHide)
        }
        XCTAssertEqual(hides, 2)
    }

    func testFailedRestoreRetainsOwnershipAndRetriesWithoutAnotherHide() {
        var state = CursorVisibility()
        state.update(eligible: true, hide: { true }, show: { XCTFail(); return false })
        state.update(eligible: false, hide: { XCTFail(); return false }, show: { false })
        XCTAssertTrue(state.needsRestore)
        state.update(eligible: true, hide: { XCTFail(); return false }, show: { true })
        XCTAssertFalse(state.ownsHide)
        XCTAssertFalse(state.needsRestore)
    }

    func testCompanionStaysSeparateAndOnScreenAtBothEdges() {
        _ = NSApplication.shared
        let frame = CGRect(x: -1440, y: 210, width: 1440, height: 900)
        for style in PointerStyle.allCases {
            for size in [44.0, 76.0, 132.0] {
                var prefs = Preferences()
                prefs.style = style
                prefs.size = size
                let layout = PointerArt.companionPlacement(for: prefs)
                XCTAssertGreaterThan(layout.arrow.width, 0)
                for x in [frame.minX, frame.midX, frame.maxX - 1] {
                    for y in [frame.minY, frame.midY, frame.maxY - 1] {
                        let point = CGPoint(x: x, y: y)
                        let companion = layout.position(at: point, in: frame)
                        let ink = layout.ink.offsetBy(dx: companion.x, dy: companion.y)
                        let arrow = layout.arrow.offsetBy(dx: x, dy: y)
                        XCTAssertFalse(ink.intersects(arrow))
                        XCTAssertTrue(frame.insetBy(dx: -0.01, dy: -0.01).contains(ink))
                    }
                }
            }
        }
    }

    func testWobbleUsesSharpReversalsAndRespectsCooldown() {
        var motion = CursorMotion()
        let left = CGPoint(x: 0, y: 0)
        let right = CGPoint(x: 40, y: 0)
        XCTAssertNil(motion.turn(from: left, to: right, now: 1))
        XCTAssertEqual(motion.turn(from: right, to: left, now: 1.1), -1)
        XCTAssertNil(motion.turn(from: left, to: right, now: 1.2))
        XCTAssertNil(motion.stopped(at: 1.29))
        XCTAssertEqual(motion.turn(from: right, to: left, now: 1.6), -1)
    }

    func testWobbleAtStopRequiresRecentFastMovement() {
        var motion = CursorMotion()
        let origin = CGPoint.zero
        XCTAssertNil(motion.turn(from: origin, to: CGPoint(x: 4, y: 0), now: 1))
        XCTAssertNil(motion.stopped(at: 1.09))
        XCTAssertNil(motion.turn(from: origin, to: CGPoint(x: 20, y: 0), now: 2))
        XCTAssertEqual(motion.stopped(at: 2.09), 0.32)
        XCTAssertNil(motion.stopped(at: 2.12))
        motion.resetDirection()
        XCTAssertNil(motion.stopped(at: 2.36))
    }

    func testScreenLocalConversionPreservesPointPrecisionOnAnOffsetScreen() {
        let point = CGPoint(x: -340.25, y: 876.75)
        let screen = CGRect(x: -1440, y: 280, width: 1440, height: 900)
        XCTAssertEqual(CursorGeometry.local(point, in: screen), CGPoint(x: 1099.75, y: 596.75))
    }
}
