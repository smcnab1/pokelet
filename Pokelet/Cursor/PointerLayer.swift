import AppKit
import QuartzCore

final class PointerLayer {
    let root = CALayer()
    private let character = CALayer()
    private let impacts = CALayer()
    private let artwork = CALayer()
    private var effectInk = CGColor(gray: 1, alpha: 1)
    private var effectEdge = CGColor(gray: 0, alpha: 1)
    private var style = PointerStyle.finger
    private var presenterArm = false
    private var sleeve: PresenterSleeveLayer?
    private var retiringCharacter: CALayer?

    init() {
        root.addSublayer(impacts)
        root.addSublayer(artwork)
        artwork.addSublayer(character)
        artwork.isHidden = true
    }

    func configure(image: CGImage, prefs: Preferences, presenterArm: Bool = false, crossfade: Bool = false) {
        let previous = crossfade && !presenterArm && !self.presenterArm ? snapshotCharacter() : nil
        reset()
        self.presenterArm = presenterArm
        style = prefs.style
        let scale = CGFloat(image.width) / prefs.size
        withoutLayerActions {
            if presenterArm {
                if sleeve == nil {
                    let next = PresenterSleeveLayer()
                    next.isHidden = true
                    root.insertSublayer(next, below: impacts)
                    sleeve = next
                }
                sleeve?.setScale(scale)
            } else {
                sleeve?.removeFromSuperlayer()
                sleeve = nil
                character.setAffineTransform(.identity)
            }
            character.contents = image
            character.contentsScale = scale
            character.bounds = CGRect(x: 0, y: 0, width: prefs.size, height: prefs.size)
            character.anchorPoint = CursorGeometry.layerAnchor
            character.position = .zero
            let inks = PointerArt.inks(for: prefs)
            effectInk = presenterArm ? CGColor(gray: 1, alpha: 1) : inks.effect.color()
            effectEdge = presenterArm ? PointerArt.ink.color() :
                (inks.effect.luminance < 0.18 ? inks.highlight : inks.shadow).color(0.85)
        }
        if let previous { transition(from: previous) }
    }

    private func snapshotCharacter() -> CALayer? {
        guard let contents = character.contents else { return nil }
        let layer = CALayer()
        layer.contents = contents
        layer.contentsScale = character.contentsScale
        layer.bounds = character.bounds
        layer.anchorPoint = character.anchorPoint
        layer.position = character.position
        layer.opacity = 0
        return layer
    }

    private func transition(from previous: CALayer) {
        withoutLayerActions { artwork.insertSublayer(previous, below: character) }
        retiringCharacter = previous
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self, weak previous] in
            guard let self, let previous, self.retiringCharacter === previous else { return }
            previous.removeFromSuperlayer()
            self.retiringCharacter = nil
        }
        for (layer, start, end) in [(previous, 1, 0), (character, 0, 1)] {
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = start
            fade.toValue = end
            fade.duration = 0.17
            fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer.add(fade, forKey: "characterChange")
        }
        CATransaction.commit()
    }

    func place(_ location: CGPoint, visible: Bool, viewport: CGRect = .zero) {
        withoutLayerActions {
            artwork.position = location
            artwork.isHidden = !visible
            if visible, let sleeve {
                let angle = sleeve.place(tip: location, viewport: viewport, size: character.bounds.width)
                character.setAffineTransform(CGAffineTransform(rotationAngle: angle))
            } else {
                sleeve?.isHidden = true
            }
        }
    }

    func reset() {
        retiringCharacter?.removeFromSuperlayer()
        retiringCharacter = nil
        character.removeAllAnimations()
        impacts.sublayers?.forEach { $0.removeFromSuperlayer() }
        withoutLayerActions { character.opacity = 1 }
    }

    var artworkPosition: CGPoint { artwork.position }

    func poke(at point: CGPoint, energy: Double, secondary: Bool, motion: Bool, effects: Bool, celebration: Bool,
              reduced: Bool) {
        if motion && !presenterArm {
            let next = CAKeyframeAnimation(keyPath: "transform")
            next.duration = secondary ? 0.29 : 0.24
            next.keyTimes = [0, 0.17, 0.43, 0.70, 1]
            let current = character.presentation()?.transform ?? CATransform3DIdentity
            let angle = (secondary ? -0.20 : 0.055) * energy
            let squash = style == .catPaw ? 0.25 : style == .comicArrow ? 0.12 : 0.20
            let press = pose(x: 1 + energy * 0.17, y: 1 - energy * squash, angle: angle)
            let spring = pose(x: 1 - energy * 0.05, y: 1 + energy * 0.13, angle: -angle * 0.55)
            let settle = pose(x: 1 + energy * 0.035, y: 1 - energy * 0.035, angle: angle * 0.17)
            next.values = [current, press, spring, settle, CATransform3DIdentity].map { NSValue(caTransform3D: $0) }
            next.timingFunctions = Array(repeating: CAMediaTimingFunction(name: .easeOut), count: 4)
            character.add(next, forKey: "motion")
        }
        if effects {
            impact(at: point, secondary: secondary, celebration: celebration, reduced: reduced, energy: energy)
        }
        if (presenterArm && motion) || (reduced && !effects) {
            let blink = CAKeyframeAnimation(keyPath: "opacity")
            blink.values = [1.0, presenterArm ? (secondary ? 0.85 : 0.92) : 0.76, 1.0]
            blink.duration = 0.15
            character.add(blink, forKey: "pulse")
        }
    }

    func wobble(turn: Double) {
        guard !presenterArm, character.animation(forKey: "motion") == nil else { return }
        let bounce = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        bounce.values = [0, turn * 0.11, -turn * 0.035, 0]
        bounce.duration = 0.21
        character.add(bounce, forKey: "motion")
    }

    private func pose(x: Double, y: Double, angle: Double) -> CATransform3D {
        CATransform3DScale(CATransform3DMakeRotation(angle, 0, 0, 1), x, y, 1)
    }

    private func impact(at point: CGPoint, secondary: Bool, celebration: Bool, reduced: Bool, energy: Double) {
        let path: CGPath
        if reduced { path = Self.ring }
        else if !presenterArm, style == .catPaw, !secondary, !celebration { path = Self.pawPrint }
        else if secondary { path = Self.ring }
        else { path = celebration ? Self.celebration : Self.rays }

        let fade = CAKeyframeAnimation(keyPath: "opacity")
        fade.values = [0, min(1, 0.38 + energy * 0.45), 0]
        fade.keyTimes = [0, 0.22, 1]
        let expand = CABasicAnimation(keyPath: "transform.scale")
        expand.fromValue = reduced ? 0.65 : 0.37
        expand.toValue = reduced ? 0.65 : min(1.55, 0.73 + energy * 0.59)
        expand.timingFunction = CAMediaTimingFunction(name: .easeOut)
        let animation = CAAnimationGroup()
        animation.duration = reduced ? 0.16 : 0.32
        fade.duration = animation.duration
        expand.duration = animation.duration
        animation.animations = [fade, expand]

        let mark = CALayer()
        mark.position = point
        mark.opacity = 0
        for (width, colour) in [(5.0, effectEdge), (2.45, effectInk)] {
            let stroke = CAShapeLayer()
            stroke.path = path
            stroke.fillColor = nil
            stroke.lineJoin = .round
            stroke.lineCap = .round
            stroke.lineWidth = width
            stroke.strokeColor = colour
            mark.addSublayer(stroke)
        }

        // The mark belongs to the viewport, so pointer movement cannot drag an
        // existing impact away from the mouse-down point.
        if let marks = impacts.sublayers, marks.count >= 16 {
            marks.first?.removeFromSuperlayer()
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setCompletionBlock { [weak mark] in mark?.removeFromSuperlayer() }
        impacts.addSublayer(mark)
        mark.add(animation, forKey: "impact")
        CATransaction.commit()
    }

    private static let ring = CGPath(ellipseIn: CGRect(x: -15, y: -15, width: 30, height: 30), transform: nil)

    private static let pawPrint: CGPath = {
        let path = CGMutablePath()
        for dot in [CGRect(x: -27, y: 7, width: 6, height: 7), CGRect(x: -21, y: 16, width: 6, height: 7),
                    CGRect(x: -12, y: 17, width: 6, height: 7), CGRect(x: -4, y: 11, width: 6, height: 7),
                    CGRect(x: -20, y: 3, width: 13, height: 10)] {
            path.addEllipse(in: dot)
        }
        let bounds = path.boundingBoxOfPath
        var centre = CGAffineTransform(translationX: -bounds.midX, y: -bounds.midY)
        return path.copy(using: &centre)!
    }()

    private static let rays = burst(count: 5, sparks: false)
    private static let celebration = burst(count: 7, sparks: true)

    private static func burst(count: Int, sparks: Bool) -> CGPath {
        let result = CGMutablePath()
        for index in 0..<count {
            let angle = CGFloat(index) / CGFloat(count) * .pi * 2 + 0.35
            let reach: CGFloat = sparks ? 32 : 22
            result.move(to: CGPoint(x: cos(angle) * 10, y: sin(angle) * 10))
            let tip = CGPoint(x: cos(angle) * reach, y: sin(angle) * reach)
            result.addLine(to: tip)
            if sparks && index.isMultiple(of: 2) {
                result.addEllipse(in: CGRect(x: tip.x * 1.28 - 1, y: tip.y * 1.28 - 1, width: 2, height: 2))
            }
        }
        return result.copy()!
    }
}

func withoutLayerActions(_ update: () -> Void) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    update()
    CATransaction.commit()
}
