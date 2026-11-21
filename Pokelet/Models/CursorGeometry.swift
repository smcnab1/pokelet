import CoreGraphics

enum CursorGeometry {
    static let canvas: CGFloat = 104
    static let hotspot = CGPoint(x: 32, y: 15)
    static let layerAnchor = CGPoint(x: hotspot.x / canvas, y: 1 - hotspot.y / canvas)

    static func canvasRect(at point: CGPoint, size: CGFloat) -> CGRect {
        CGRect(x: point.x - size * layerAnchor.x, y: point.y - size * layerAnchor.y,
               width: size, height: size)
    }

    static func companion(at point: CGPoint, in frame: CGRect, size: CGFloat) -> CGPoint {
        let right = point.x + size * layerAnchor.x + 28
        let left = point.x - size * (1 - layerAnchor.x) - 28
        let rightEdge = canvasRect(at: CGPoint(x: right, y: point.y), size: size).maxX
        let x = rightEdge <= frame.maxX
            ? right : max(frame.minX + size * layerAnchor.x, left)
        let y = min(max(point.y + 8, frame.minY + size * layerAnchor.y),
                    frame.maxY - size * (1 - layerAnchor.y))
        return CGPoint(x: x, y: y)
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
