import CoreGraphics
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
        let frame = CGRect(x: -1440, y: 210, width: 1440, height: 900)
        for size in [44.0, 76.0, 132.0] {
            let left = CGPoint(x: frame.minX, y: frame.minY)
            let right = CGPoint(x: frame.maxX - 1, y: frame.maxY - 1)
            let a = CursorGeometry.companion(at: left, in: frame, size: size)
            let b = CursorGeometry.companion(at: right, in: frame, size: size)
            XCTAssertGreaterThanOrEqual(a.x - left.x, 28)
            XCTAssertGreaterThanOrEqual(right.x - b.x, size * 0.75 + 20)
            for point in [a, b] {
                let canvas = CursorGeometry.canvasRect(at: point, size: size)
                XCTAssertTrue(frame.contains(canvas))
            }
        }
    }

    func testHotspotSurvivesSizeAndCoordinateConversion() {
        for size in [44.0, 76.0, 132.0] {
            let point = CGPoint(x: -340, y: 876)
            let rect = CursorGeometry.canvasRect(at: point, size: size)
            XCTAssertEqual(rect.minX + rect.width * CursorGeometry.layerAnchor.x, point.x, accuracy: 0.0001)
            XCTAssertEqual(rect.minY + rect.height * CursorGeometry.layerAnchor.y, point.y, accuracy: 0.0001)
        }
    }
}
