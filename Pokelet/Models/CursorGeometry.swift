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
