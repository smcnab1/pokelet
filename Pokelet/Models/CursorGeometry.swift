import CoreGraphics

enum CursorGeometry {
    static let canvas: CGFloat = 104
    static let gloveTip = CGPoint(x: 32, y: 15)

    static func layerAnchor(for tip: CGPoint) -> CGPoint {
        CGPoint(x: tip.x / canvas, y: 1 - tip.y / canvas)
    }

    static func local(_ point: CGPoint, in frame: CGRect) -> CGPoint {
        CGPoint(x: point.x - frame.minX, y: point.y - frame.minY)
    }
}

struct CompanionPlacement {
    /// Visible silhouette relative to the character's contact point, in AppKit points.
    let ink: CGRect
    /// Native arrow image relative to its hotspot, in AppKit points.
    let arrow: CGRect
    let gap: CGFloat

    func position(at point: CGPoint, in viewport: CGRect) -> CGPoint {
        let cursor = arrow.offsetBy(dx: point.x, dy: point.y)
        let right = cursor.maxX + gap - ink.minX
        let left = cursor.minX - gap - ink.maxX
        // Keep the tip beside the native arrow when there is room. Use the
        // actual ink edges when turning inward or fitting a clipped preview.
        let y = fit(point.y, min: viewport.minY - ink.minY, max: viewport.maxY - ink.maxY)
        if right + ink.maxX <= viewport.maxX { return CGPoint(x: right, y: y) }
        if left + ink.minX >= viewport.minX { return CGPoint(x: left, y: y) }

        let above = cursor.maxY + gap - ink.minY
        let below = cursor.minY - gap - ink.maxY
        let x = fit(point.x, min: viewport.minX - ink.minX, max: viewport.maxX - ink.maxX)
        if above + ink.maxY <= viewport.maxY { return CGPoint(x: x, y: above) }
        if below + ink.minY >= viewport.minY { return CGPoint(x: x, y: below) }
        // A very small visible region can clip the illustration. Preserve
        // separation from the cursor even when the character cannot fit.
        return CGPoint(x: viewport.maxX - cursor.maxX >= cursor.minX - viewport.minX ? right : left, y: y)
    }

    private func fit(_ value: CGFloat, min lower: CGFloat, max upper: CGFloat) -> CGFloat {
        lower <= upper ? min(max(value, lower), upper) : (lower + upper) / 2
    }
}

struct CursorMotion {
    static let stopDelay: Double = 0.085
    private var direction = CGVector.zero
    private var lastTurn: Double = 0
    private var lastFastMotion: Double = 0

    mutating func resetDirection() {
        direction = .zero
        lastFastMotion = 0
    }

    mutating func turn(from previous: CGPoint, to point: CGPoint, now: Double) -> Double? {
        let dx = point.x - previous.x
        let dy = point.y - previous.y
        let distance = hypot(dx, dy)
        guard distance >= 15 else { return nil }
        lastFastMotion = now
        let next = CGVector(dx: dx / distance, dy: dy / distance)
        let dot = next.dx * direction.dx + next.dy * direction.dy
        direction = next
        guard dot < -0.55, now - lastTurn > 0.38 else { return nil }
        lastTurn = now
        return next.dx < 0 ? -1 : 1
    }

    mutating func stopped(at now: Double) -> Double? {
        guard now - lastFastMotion < 0.15, now - lastTurn > 0.22 else { return nil }
        lastTurn = now
        return direction.dx < 0 ? -0.32 : 0.32
    }
}
