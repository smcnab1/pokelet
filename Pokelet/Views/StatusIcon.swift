import AppKit

enum StatusIcon {
    static func image(active: Bool, presentation: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 18), flipped: true) { _ in
            NSColor.black.set()
            if presentation {
                let ring = NSBezierPath(ovalIn: CGRect(x: 2.75, y: 1.75, width: 14.5, height: 14.5))
                ring.lineWidth = 1.5
                ring.stroke()
                for x in [7.0, 11.1] {
                    NSBezierPath(roundedRect: CGRect(x: x, y: 5.1, width: 1.9, height: 7.8),
                                 xRadius: 0.8, yRadius: 0.8).fill()
                }
                return true
            }
            let outline = NSBezierPath()
            outline.move(to: NSPoint(x: 5, y: 2.5))
            outline.curve(to: NSPoint(x: 8, y: 3.8), controlPoint1: NSPoint(x: 6, y: 1.8),
                          controlPoint2: NSPoint(x: 7.6, y: 2.6))
            outline.line(to: NSPoint(x: 10, y: 8))
            outline.curve(to: NSPoint(x: 16, y: 9.4), controlPoint1: NSPoint(x: 12, y: 6.9),
                          controlPoint2: NSPoint(x: 15.1, y: 7.4))
            outline.curve(to: NSPoint(x: 13, y: 16), controlPoint1: NSPoint(x: 17, y: 12),
                          controlPoint2: NSPoint(x: 15, y: 14.8))
            outline.line(to: NSPoint(x: 9, y: 16))
            outline.line(to: NSPoint(x: 3.1, y: 10.8))
            outline.curve(to: NSPoint(x: 4.7, y: 8.8), controlPoint1: NSPoint(x: 1.4, y: 9.5),
                          controlPoint2: NSPoint(x: 2.7, y: 7.7))
            outline.line(to: NSPoint(x: 6.3, y: 9.7))
            outline.line(to: NSPoint(x: 3.6, y: 5.3))
            outline.curve(to: NSPoint(x: 5, y: 2.5), controlPoint1: NSPoint(x: 2.7, y: 4),
                          controlPoint2: NSPoint(x: 3.4, y: 3))
            outline.close()
            if active { outline.fill() }
            else {
                outline.lineWidth = 1.55
                outline.lineJoinStyle = .round
                outline.stroke()
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
