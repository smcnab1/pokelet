import QuartzCore
import XCTest
@testable import PokeletCore

final class PresenterArmTests: XCTestCase {
    func testAnchorAndCuffGeometryAcrossViewportsAndRapidMovement() {
        let viewports = [
            CGRect(x: 0, y: 0, width: 1512, height: 982),
            CGRect(x: -1920, y: 180, width: 1920, height: 1080),
            CGRect(x: 0, y: 0, width: 330, height: 100)
        ]
        for viewport in viewports {
            for size in [44.0, 76, 132] {
                let points = [
                    CGPoint(x: viewport.minX, y: viewport.minY),
                    CGPoint(x: viewport.maxX - 1, y: viewport.maxY - 1),
                    CGPoint(x: viewport.minX, y: viewport.maxY - 1),
                    CGPoint(x: viewport.maxX - 1, y: viewport.minY),
                    CGPoint(x: viewport.midX, y: viewport.midY),
                    CGPoint(x: viewport.midX, y: viewport.minY + 1)
                ]
                for point in points + points.reversed() {
                    let pose = PresenterArmGeometry(tip: point, viewport: viewport, size: size)
                    XCTAssertEqual(pose.tip, point)
                    XCTAssertLessThan(pose.anchor.y, viewport.minY)
                    XCTAssertTrue((viewport.minX...viewport.maxX).contains(pose.anchor.x))
                    let scale = size / CursorGeometry.canvas
                    let cuff = PresenterArmGeometry.cuff
                        .applying(CGAffineTransform(scaleX: scale, y: scale))
                        .applying(CGAffineTransform(rotationAngle: pose.angle))
                        .applying(CGAffineTransform(translationX: point.x, y: point.y))
                    XCTAssertEqual(pose.wrist.x, cuff.x, accuracy: 0.0001)
                    XCTAssertEqual(pose.wrist.y, cuff.y, accuracy: 0.0001)
                    let bounds = pose.sleeve.boundingBoxOfPath.insetBy(dx: -0.01, dy: -0.01)
                    XCTAssertTrue(bounds.contains(cuff))
                    XCTAssertTrue(bounds.contains(pose.anchor))
                    XCTAssertFalse(pose.sleeve.isEmpty)
                }
            }
        }
    }

    func testOnePointMovementDoesNotSnapTheAnchorOrGlove() {
        let viewport = CGRect(x: 0, y: 0, width: 1440, height: 900)
        for y in [1.0, 38, 76, 450, 899] {
            for x in stride(from: 0.0, to: 1440, by: 1) {
                let before = PresenterArmGeometry(tip: CGPoint(x: x, y: y), viewport: viewport, size: 76)
                let after = PresenterArmGeometry(tip: CGPoint(x: x + 1, y: y), viewport: viewport, size: 76)
                XCTAssertLessThan(abs(before.anchor.x - after.anchor.x), 3)
                XCTAssertLessThan(abs(before.angle - after.angle), 0.1)
            }
        }
    }

    func testGloveTucksInsideTheLowerRightEdge() {
        let viewport = CGRect(x: 0, y: 0, width: 496, height: 298)
        let point = CGPoint(x: 467, y: 26)
        let pose = PresenterArmGeometry(tip: point, viewport: viewport, size: 76)
        XCTAssertGreaterThan(pose.wrist.y, point.y)
        XCTAssertLessThan(pose.wrist.x + 14, viewport.maxX)
    }

    func testLayerKeepsTipAndSleeveTogetherAndClearsWhenDisabled() throws {
        let prefs = Preferences()
        for scale in [1.0, 2] {
            let layer = PointerLayer()
            let armImage = try XCTUnwrap(PointerArt.image(prefs: prefs, scale: scale, presenterArm: true))
            XCTAssertEqual(armImage.width, Int(prefs.size * scale))
            layer.configure(image: armImage, prefs: prefs, presenterArm: true)
            let sleeve = try XCTUnwrap(layer.root.sublayers?.first as? PresenterSleeveLayer)
            let viewport = CGRect(x: 0, y: 0, width: 1280, height: 850)
            let first = CGPoint(x: 240.25, y: 335.5)
            let second = CGPoint(x: 1279, y: 0.5)
            layer.place(first, visible: true, viewport: viewport)
            XCTAssertFalse(sleeve.isHidden)
            XCTAssertTrue(sleeve.animationKeys()?.isEmpty != false)
            let sleeveShape = try XCTUnwrap(sleeve.sublayers?.first as? CAShapeLayer)
            let sleevePath = try XCTUnwrap(sleeveShape.path)
            layer.place(first, visible: true, viewport: viewport)
            XCTAssertTrue(sleeveShape.path === sleevePath)
            layer.poke(at: first, energy: 1, secondary: true, motion: true, effects: true,
                       celebration: false, reduced: false)
            layer.place(second, visible: true, viewport: viewport)
            let artwork = try XCTUnwrap(layer.root.sublayers?.dropFirst().first)
            let glove = try XCTUnwrap(artwork.sublayers?.last)
            let anchor = CursorGeometry.layerAnchor(for: CursorGeometry.gloveTip)
            let contact = CGPoint(x: prefs.size * anchor.x, y: prefs.size * anchor.y)
            XCTAssertEqual(glove.convert(contact, to: layer.root).x, second.x, accuracy: 0.0001)
            XCTAssertEqual(glove.convert(contact, to: layer.root).y, second.y, accuracy: 0.0001)
            XCTAssertNil(glove.animation(forKey: "motion"))
            XCTAssertNotNil(glove.animation(forKey: "pulse"))
            let marks = try XCTUnwrap(layer.root.sublayers?.last)
            XCTAssertEqual(marks.sublayers?.first?.position, first)

            layer.reset()
            let reducedResponse = ClickResponse(prefs: prefs, count: 1, reduced: true)
            layer.poke(at: second, energy: reducedResponse.energy, secondary: false, motion: false,
                       effects: reducedResponse.effects, celebration: reducedResponse.celebration, reduced: true)
            XCTAssertNil(glove.animation(forKey: "motion"))
            XCTAssertNil(glove.animation(forKey: "pulse"))
            let impact = try XCTUnwrap(marks.sublayers?.first?.animation(forKey: "impact") as? CAAnimationGroup)
            let scaleEffect = try XCTUnwrap(impact.animations?.last as? CABasicAnimation)
            XCTAssertEqual(scaleEffect.fromValue as? Double, scaleEffect.toValue as? Double)

            layer.place(.zero, visible: false)
            XCTAssertTrue(sleeve.isHidden)
            let character = try XCTUnwrap(PointerArt.image(prefs: prefs, scale: scale))
            layer.configure(image: character, prefs: prefs)
            XCTAssertNil(sleeve.superlayer)
            XCTAssertTrue(glove.affineTransform().isIdentity)
        }
    }

    func testModesPersistIndependentlyAndRestoreThePreviousCharacter() throws {
        let name = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = PreferenceStore(defaults: defaults)
        var prefs = store.load()
        XCTAssertFalse(prefs.usesPresenterArm(presentation: false))
        XCTAssertFalse(prefs.usesPresenterArm(presentation: true))

        prefs.style = .foamFinger
        prefs.presenterEffects.normal = true
        store.save(prefs)
        prefs = store.load()
        XCTAssertTrue(prefs.usesPresenterArm(presentation: false))
        XCTAssertFalse(prefs.usesPresenterArm(presentation: true))
        prefs.presenterEffects.presentation = true
        prefs.presenterEffects.normal = false
        store.save(prefs)
        prefs = store.load()
        XCTAssertFalse(prefs.usesPresenterArm(presentation: false))
        XCTAssertTrue(prefs.usesPresenterArm(presentation: true))
        XCTAssertEqual(prefs.style, .foamFinger)
    }
}
