import ApplicationServices
import XCTest
@testable import PokeletCore

final class ClickSoundTriggerTests: XCTestCase {
    func testDefaultAndMissingAccessRetainEveryClick() {
        XCTAssertEqual(Preferences().soundTrigger, .everyClick)
        XCTAssertFalse(SoundTrigger.everyClick.needsHitTest(accessibility: true, presentation: false))
        XCTAssertTrue(SoundTrigger.interactiveOnly.needsHitTest(accessibility: true, presentation: false))
        XCTAssertFalse(SoundTrigger.interactiveOnly.needsHitTest(accessibility: false, presentation: false))
        XCTAssertFalse(SoundTrigger.interactiveOnly.needsHitTest(accessibility: true, presentation: true))
    }

    func testOnlyEnabledControlsOrActionableElementsClassify() {
        XCTAssertTrue(InteractiveClickSound.isActionable(role: "AXButton", enabled: true, actions: []))
        XCTAssertTrue(InteractiveClickSound.isActionable(role: "AXGroup", enabled: nil, actions: [kAXPressAction]))
        XCTAssertFalse(InteractiveClickSound.isActionable(role: "AXButton", enabled: false, actions: [kAXPressAction]))
        XCTAssertFalse(InteractiveClickSound.isActionable(role: "AXStaticText", enabled: nil, actions: []))
        XCTAssertFalse(InteractiveClickSound.isActionable(role: "AXWindow", enabled: true, actions: [kAXPressAction]))
    }
}
