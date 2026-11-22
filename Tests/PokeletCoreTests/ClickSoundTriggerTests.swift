import ApplicationServices
import XCTest
@testable import PokeletCore

final class ClickSoundTriggerTests: XCTestCase {
    func testInteractiveOnlyStaysSilentWhenDetectionIsUnavailable() {
        XCTAssertEqual(Preferences().soundTrigger, .everyClick)
        XCTAssertEqual(SoundTrigger.everyClick.playback(accessibility: false, presentation: false), .play)
        XCTAssertEqual(SoundTrigger.everyClick.playback(accessibility: true, presentation: true), .play)
        XCTAssertEqual(SoundTrigger.interactiveOnly.playback(accessibility: true, presentation: false), .classify)
        XCTAssertEqual(SoundTrigger.interactiveOnly.playback(accessibility: false, presentation: false), .silent)
        XCTAssertEqual(SoundTrigger.interactiveOnly.playback(accessibility: true, presentation: true), .silent)
    }

    func testOnlyEnabledControlsOrActionableElementsClassify() {
        XCTAssertTrue(InteractiveClickSound.isActionable(role: "AXButton", enabled: true, actions: []))
        XCTAssertTrue(InteractiveClickSound.isActionable(role: "AXGroup", enabled: nil, actions: [kAXPressAction]))
        XCTAssertFalse(InteractiveClickSound.isActionable(role: "AXButton", enabled: false, actions: [kAXPressAction]))
        XCTAssertFalse(InteractiveClickSound.isActionable(role: "AXStaticText", enabled: nil, actions: []))
        XCTAssertFalse(InteractiveClickSound.isActionable(role: "AXWindow", enabled: true, actions: [kAXPressAction]))
    }
}
