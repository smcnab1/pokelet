import QuartzCore

/// All points are in AppKit coordinates. The glove rotates around the fingertip,
/// and the sleeve ends beneath the same transformed cuff.
struct PresenterArmGeometry {
    let tip: CGPoint
    let angle: CGFloat
    let anchor: CGPoint
    let wrist: CGPoint
    let sleeve: CGPath
    let seam: CGPath

    static let cuff = CGPoint(x: 30, y: -65)

    init(tip: CGPoint, viewport: CGRect, size: CGFloat) {
        self.tip = tip
        let scale = size / CursorGeometry.canvas
        let x = tip.x - viewport.minX
        let y = tip.y - viewport.minY
        // Start the turn early enough for the knuckles to clear the lower
        // edge as the wrist moves above the fingertip.
        let turn = Self.ease((size - y) / (size * 0.64))
        let right = Self.ease((x - viewport.width + size) / size)
        angle = .pi / 180 * ((115 + 54 * right) * turn - 49 * right * (1 - turn))

        let towardsWrist = CGPoint(x: Self.cuff.x * cos(angle) - Self.cuff.y * sin(angle),
                                   y: Self.cuff.x * sin(angle) + Self.cuff.y * cos(angle))
        let length = hypot(towardsWrist.x, towardsWrist.y)
        let direction = CGVector(dx: towardsWrist.x / length, dy: towardsWrist.y / length)
        let normal = CGVector(dx: -direction.dy, dy: direction.dx)
        wrist = CGPoint(x: tip.x + towardsWrist.x * scale, y: tip.y + towardsWrist.y * scale)

        let halfWidth = min(15, max(6, 14 * scale))
        let reach = Self.ease(y / max(1, viewport.height * 0.72))
        let desiredX = wrist.x + (viewport.midX - wrist.x) * reach * 0.62
        let inset = min(halfWidth, viewport.width / 2)
        anchor = CGPoint(x: min(max(desiredX, viewport.minX + inset), viewport.maxX - inset),
                         y: viewport.minY - halfWidth - 3)

        let bend = min(210, max(8, hypot(wrist.x - anchor.x, wrist.y - anchor.y) * 0.28))
        let wristControl = wrist.offset(direction, by: bend)
        let baseControl = CGPoint(x: anchor.x, y: anchor.y + bend)
        let centreline = CGMutablePath()
        centreline.move(to: wrist)
        centreline.addCurve(to: anchor, control1: wristControl, control2: baseControl)
        sleeve = centreline.copy(strokingWithWidth: 2 * halfWidth, lineCap: .butt, lineJoin: .round, miterLimit: 1)

        var seamInset = CGAffineTransform(translationX: normal.dx * halfWidth * 0.42,
                                          y: normal.dy * halfWidth * 0.42)
        seam = centreline.copy(using: &seamInset)!
    }

    private static func ease(_ value: CGFloat) -> CGFloat {
        let t = min(max(value, 0), 1)
        return t * t * (3 - 2 * t)
    }
}

private extension CGPoint {
    func offset(_ direction: CGVector, by distance: CGFloat) -> CGPoint {
        CGPoint(x: x + direction.dx * distance, y: y + direction.dy * distance)
    }
}

final class PresenterSleeveLayer: CALayer {
    private let sleeve = CAShapeLayer()
    private let seam = CAShapeLayer()

    override init() {
        super.init()
        addSublayer(sleeve)
        addSublayer(seam)
        sleeve.fillColor = PointerArt.RGB(0x14121A).color()
        sleeve.strokeColor = PointerArt.RGB(0xF5EAF8).color(0.60)
        sleeve.lineWidth = 1.65
        sleeve.lineJoin = .round
        seam.fillColor = nil
        seam.strokeColor = PointerArt.RGB(0x4F445A).color(0.85)
        seam.lineWidth = 1.15
        seam.lineCap = .round
    }

    override init(layer: Any) { super.init(layer: layer) }
    required init?(coder: NSCoder) { nil }

    func place(tip: CGPoint, viewport: CGRect, size: CGFloat) -> CGFloat {
        let next = PresenterArmGeometry(tip: tip, viewport: viewport, size: size)
        let paddedBounds = next.sleeve.boundingBoxOfPath.insetBy(dx: -3, dy: -3).integral
        var origin = CGAffineTransform(translationX: -paddedBounds.minX, y: -paddedBounds.minY)
        let sleevePath = next.sleeve.copy(using: &origin)
        let seamPath = next.seam.copy(using: &origin)
        withoutLayerActions {
            frame = paddedBounds
            sleeve.frame = bounds
            seam.frame = bounds
            sleeve.path = sleevePath
            seam.path = seamPath
            isHidden = false
        }
        return next.angle
    }

    func setScale(_ scale: CGFloat) {
        contentsScale = scale
        sleeve.contentsScale = scale
        seam.contentsScale = scale
    }
}

extension PointerArt {
    // The cuff overlaps the sleeve around the point (62, 80). The round tip
    // shares the same keyed canvas origin as the other Pokelet characters.
    private static let glove = makePath { p in
        p.m(32, 15); p.c(36, 13, 41, 16, 44, 22)
        p.l(56, 42); p.c(62, 36, 69, 39, 71, 46)
        p.c(78, 42, 84, 46, 84, 52)
        p.c(92, 52, 96, 58, 93, 66)
        p.c(90, 75, 82, 81, 75, 84)
        p.l(56, 91); p.c(51, 88, 48, 82, 47, 76)
        p.l(33, 66); p.c(27, 61, 27, 55, 32, 52)
        p.c(36, 49, 42, 52, 47, 55)
        p.l(25, 28); p.c(21, 22, 26, 17, 32, 15); p.z()
    }

    private static let cuffDetail = makePath { p in
        p.m(47, 77); p.c(54, 79, 67, 75, 77, 71)
        p.c(80, 73, 82, 77, 82, 80)
        p.c(73, 85, 63, 91, 56, 93)
        p.c(52, 91, 48, 85, 47, 77); p.z()
    }

    private static let gloveDetail = makePath { p in
        p.m(56, 42); p.l(61, 50)
        p.m(71, 46); p.l(74, 53)
        p.m(84, 52); p.l(85, 58)
        p.m(47, 55); p.c(51, 57, 55, 60, 57, 65)
        p.m(64, 63); p.c(68, 60, 72, 59, 77, 60)
    }

    static func drawPresenterGlove(in context: CGContext, shadow: Bool) {
        context.setLineJoin(.round)
        context.setLineCap(.round)
        if shadow {
            context.saveGState()
            context.setShadow(offset: CGSize(width: 0, height: -2), blur: 4, color: ink.color(0.45))
            context.addPath(glove)
            context.setFillColor(RGB(0xFFFFFF).color())
            context.fillPath()
            context.restoreGState()
        }

        context.addPath(glove)
        context.setFillColor(RGB(0xFFFFFF).color())
        context.setStrokeColor(ink.color())
        context.setLineWidth(3.2)
        context.drawPath(using: .fillStroke)

        context.addPath(cuffDetail)
        context.setFillColor(RGB(0xEAE3F3).color())
        context.setLineWidth(2.7)
        context.drawPath(using: .fillStroke)

        context.addPath(gloveDetail)
        context.setStrokeColor(RGB(0x645772).color())
        context.setLineWidth(1.8)
        context.strokePath()

    }
}
