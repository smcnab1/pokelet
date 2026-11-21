import AppKit
import QuartzCore

final class PointerLayer {
    let root = CALayer()
    private let character = CALayer()
    private let effect = CAShapeLayer()
    private let effectOutline = CAShapeLayer()
    private var style = PointerStyle.finger
    private var retiringCharacter: CALayer?

    init() {
        root.addSublayer(effectOutline)
        root.addSublayer(effect)
        root.addSublayer(character)
        root.isHidden = true
        for layer in [effectOutline, effect] {
            layer.fillColor = nil
            layer.lineJoin = .round
            layer.lineCap = .round
            layer.opacity = 0
        }
        effectOutline.lineWidth = 5
        effect.lineWidth = 2.45
    }

    func configure(image: CGImage, prefs: Preferences, crossfade: Bool = false) {
        let previous = crossfade ? snapshotCharacter() : nil
        reset()
        style = prefs.style
        let scale = CGFloat(image.width) / prefs.size
        withoutLayerActions {
            character.contents = image
            character.contentsScale = scale
            character.bounds = CGRect(x: 0, y: 0, width: prefs.size, height: prefs.size)
            character.anchorPoint = CursorGeometry.layerAnchor
            character.position = .zero
            let inks = PointerArt.inks(for: prefs)
            effect.strokeColor = inks.effect.color()
            effectOutline.strokeColor = (inks.effect.luminance < 0.18 ? inks.highlight : inks.shadow).color(0.85)
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
        withoutLayerActions { root.insertSublayer(previous, below: character) }
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

    func place(_ location: CGPoint, visible: Bool) {
        withoutLayerActions {
            root.position = location
            root.isHidden = !visible
        }
    }

    func reset() {
        retiringCharacter?.removeFromSuperlayer()
        retiringCharacter = nil
        character.removeAllAnimations()
        effect.removeAllAnimations()
        effectOutline.removeAllAnimations()
        withoutLayerActions { character.opacity = 1 }
    }

    func poke(energy: Double, secondary: Bool, motion: Bool, effects: Bool, celebration: Bool,
              reduced: Bool) {
        if motion {
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
            impact(secondary: secondary, celebration: celebration, reduced: reduced, energy: energy)
        } else if reduced {
            let blink = CAKeyframeAnimation(keyPath: "opacity")
            blink.values = [1.0, 0.76, 1.0]
            blink.duration = 0.15
            character.add(blink, forKey: "pulse")
        }
    }

    func wobble(turn: Double) {
        guard character.animation(forKey: "motion") == nil else { return }
        let bounce = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        bounce.values = [0, turn * 0.11, -turn * 0.035, 0]
        bounce.duration = 0.21
        character.add(bounce, forKey: "motion")
    }

    private func pose(x: Double, y: Double, angle: Double) -> CATransform3D {
        CATransform3DScale(CATransform3DMakeRotation(angle, 0, 0, 1), x, y, 1)
    }

    private func impact(secondary: Bool, celebration: Bool, reduced: Bool, energy: Double) {
        let path: CGPath
        if reduced { path = Self.ring }
        else if style == .catPaw, !secondary, !celebration { path = Self.pawPrint }
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

        withoutLayerActions {
            for layer in [effectOutline, effect] {
                layer.path = path
                layer.add(animation, forKey: "impact")
            }
        }
    }

    private static let ring = CGPath(ellipseIn: CGRect(x: -15, y: -15, width: 30, height: 30), transform: nil)

    private static let pawPrint: CGPath = {
        let path = CGMutablePath()
        for dot in [CGRect(x: -27, y: 7, width: 6, height: 7), CGRect(x: -21, y: 16, width: 6, height: 7),
                    CGRect(x: -12, y: 17, width: 6, height: 7), CGRect(x: -4, y: 11, width: 6, height: 7),
                    CGRect(x: -20, y: 3, width: 13, height: 10)] {
            path.addEllipse(in: dot)
        }
        return path.copy()!
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
