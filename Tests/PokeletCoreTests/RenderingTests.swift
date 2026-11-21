import QuartzCore
import XCTest
@testable import PokeletCore

final class RenderingTests: XCTestCase {
    func testEveryStyleAndColourRendersAtBothDisplayScales() throws {
        for style in PointerStyle.allCases {
            for palette in Palette.allCases {
                var prefs = Preferences()
                prefs.style = style
                prefs.palette = palette
                for scale in [1.0, 2.0] {
                    let image = try XCTUnwrap(PointerArt.image(prefs: prefs, scale: scale))
                    XCTAssertEqual(image.width, Int(prefs.size * scale))
                    XCTAssertEqual(image.height, image.width)
                }
            }
        }
    }

    func testBlackCharacterHasOpaqueBlackBodyAndVisibleFeatures() throws {
        for style in PointerStyle.allCases {
            var prefs = Preferences()
            prefs.style = style
            prefs.palette = .black
            prefs.shadow = false
            let image = try XCTUnwrap(PointerArt.image(prefs: prefs, scale: 2))
            let provider = try XCTUnwrap(image.dataProvider)
            let bytes = try XCTUnwrap(provider.data)
            let data = try XCTUnwrap(CFDataGetBytePtr(bytes))
            var black = 0
            var light = 0
            for y in 0..<image.height {
                for x in 0..<image.width {
                    let pixel = data + y * image.bytesPerRow + x * 4
                    guard pixel[3] == 255 else { continue }
                    if pixel[0] == 0, pixel[1] == 0, pixel[2] == 0 { black += 1 }
                    if pixel[0] > 200, pixel[1] > 200, pixel[2] > 200 { light += 1 }
                }
            }
            XCTAssertGreaterThan(black, 850, "\(style)")
            XCTAssertGreaterThan(light, 50, "\(style)")
        }
    }

    func testCustomFillAndOutlineRespondToLuminance() {
        var prefs = Preferences()
        prefs.palette = .custom
        prefs.customColour = 0x000033
        let dark = PointerArt.inks(for: prefs)
        prefs.customColour = 0xFFFF88
        let light = PointerArt.inks(for: prefs)
        XCTAssertEqual(dark.primary.hex, 0x000033)
        XCTAssertEqual(light.primary.hex, 0xFFFF88)
        XCTAssertGreaterThan(dark.outline.luminance, 0.8)
        XCTAssertLessThan(light.outline.luminance, 0.1)
    }

    func testAllCharacterHotspotsAndIndependentMouseDownImpacts() throws {
        let first = CGPoint(x: 32.25, y: 84.75)
        let second = CGPoint(x: 73.5, y: 92.25)
        for style in PointerStyle.allCases {
            for size in [44.0, 76, 132] {
                for scale in [1.0, 2] {
                    var prefs = Preferences()
                    prefs.style = style
                    prefs.size = size
                    let layer = PointerLayer()
                    layer.configure(image: try XCTUnwrap(PointerArt.image(prefs: prefs, scale: scale)), prefs: prefs)
                    layer.place(first, visible: true)
                    let artwork = try XCTUnwrap(layer.root.sublayers?.last)
                    let character = try XCTUnwrap(artwork.sublayers?.last)
                    let contact = CGPoint(x: size * CursorGeometry.hotspot.x / CursorGeometry.canvas,
                                          y: size * (1 - CursorGeometry.hotspot.y / CursorGeometry.canvas))
                    XCTAssertEqual(character.convert(contact, to: layer.root).x, first.x, accuracy: 0.0001)
                    XCTAssertEqual(character.convert(contact, to: layer.root).y, first.y, accuracy: 0.0001)

                    layer.place(CGPoint(x: 120, y: 120), visible: true) // Companion offset
                    layer.poke(at: first, energy: 1, secondary: false, motion: true, effects: true,
                               celebration: false, reduced: false)
                    layer.place(second, visible: true)
                    layer.poke(at: second, energy: 1, secondary: true, motion: true, effects: true,
                               celebration: false, reduced: false)
                    layer.place(.zero, visible: false)

                    let impacts = try XCTUnwrap(layer.root.sublayers?.first)
                    XCTAssertEqual(impacts.sublayers?.map(\.position), [first, second])
                    XCTAssertFalse(impacts.isHidden)
                    layer.reset()
                    XCTAssertNil(impacts.sublayers)
                }
            }
        }
    }

    func testCharacterCrossfadeIsOptInAndCancellable() throws {
        var prefs = Preferences()
        let layer = PointerLayer()
        layer.configure(image: try XCTUnwrap(PointerArt.image(prefs: prefs, scale: 1)), prefs: prefs)
        let character = try XCTUnwrap(layer.root.sublayers?.last?.sublayers?.last)
        XCTAssertNil(character.animation(forKey: "characterChange"))

        prefs.style = .catPaw
        layer.configure(image: try XCTUnwrap(PointerArt.image(prefs: prefs, scale: 1)), prefs: prefs, crossfade: true)
        let outgoing = try XCTUnwrap(layer.root.sublayers?.last?.sublayers?.dropLast().last)
        let fadeOut = try XCTUnwrap(outgoing.animation(forKey: "characterChange") as? CABasicAnimation)
        let fadeIn = try XCTUnwrap(character.animation(forKey: "characterChange") as? CABasicAnimation)
        XCTAssertEqual(fadeOut.toValue as? Int, 0)
        XCTAssertEqual(fadeIn.toValue as? Int, 1)
        layer.reset()
        XCTAssertNil(outgoing.superlayer)
        XCTAssertNil(character.animation(forKey: "characterChange"))
    }

    func testSwitchingCharactersAndResetCancelAnimations() throws {
        var prefs = Preferences()
        let layer = PointerLayer()
        layer.configure(image: try XCTUnwrap(PointerArt.image(prefs: prefs, scale: 1)), prefs: prefs)
        let character = try XCTUnwrap(layer.root.sublayers?.last?.sublayers?.last)
        layer.poke(at: .zero, energy: 0.8, secondary: false, motion: true, effects: true, celebration: false, reduced: false)
        XCTAssertNotNil(character.animation(forKey: "motion"))
        prefs.style = .catPaw
        layer.configure(image: try XCTUnwrap(PointerArt.image(prefs: prefs, scale: 1)), prefs: prefs)
        XCTAssertNil(character.animation(forKey: "motion"))
        layer.poke(at: .zero, energy: 0.8, secondary: true, motion: false, effects: false, celebration: false, reduced: true)
        XCTAssertNil(character.animation(forKey: "motion"))
        XCTAssertNotNil(character.animation(forKey: "pulse"))
        layer.reset()
        XCTAssertTrue(character.animationKeys()?.isEmpty != false)
    }
}
