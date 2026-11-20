import AppKit

enum StatusIcon {
    static func image(active: Bool, presentation: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 18), flipped: true) { _ in
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
            NSColor.black.set()
            if active { outline.fill() }
            else {
                outline.lineWidth = 1.55
                outline.lineJoinStyle = .round
                outline.stroke()
            }
            if presentation {
                NSBezierPath(ovalIn: CGRect(x: 15, y: 1.5, width: 4, height: 4)).fill()
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
