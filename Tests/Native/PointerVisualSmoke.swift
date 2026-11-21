import AppKit
import QuartzCore

/// Samples actual Core Animation presentation frames in a disposable window.
/// Reference points are fixture coordinates. This does not post input or hide the cursor.
@main
enum PointerVisualSmoke {
    static let viewport = CGRect(x: 0, y: 0, width: 340, height: 240)
    static let target = CGPoint(x: 125.25, y: 154.25)
    static let second = CGPoint(x: 205.75, y: 165.75)

    static func main() throws {
        guard CommandLine.arguments.count == 2 else { throw Failure("Pass a directory for PNG evidence") }
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        _ = NSApplication.shared
        let window = NSWindow(contentRect: viewport, styleMask: .borderless, backing: .buffered, defer: false)
        let view = NSView(frame: viewport)
        view.wantsLayer = true
        window.contentView = view
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = true
        let pointer = PointerLayer()
        view.layer!.addSublayer(pointer.root)
        pointer.root.frame = viewport
        window.orderFrontRegardless()
        defer { window.close() }

        try captureComparisons(pointer, output: output)
        #if !BASELINE
        print("style,size,scale,mode,reference_x,reference_y,visible_tip_x,visible_tip_y,tip_to_click_pt,tip_placement_error_pt,primary_x,primary_y,primary_error_pt,secondary_x,secondary_y,secondary_error_pt")
        for style in PointerStyle.allCases {
            for size in [44.0, 76, 132] {
                for scale in [1.0, 2] {
                    for mode in ["Companion", "Replace", "Click-only"] {
                        try measure(pointer, style: style, size: size, scale: scale, mode: mode)
                    }
                }
            }
        }
        try measurePresenter(pointer, output: output)
        #endif
    }

    private static func settle(_ interval: TimeInterval = 0.052) {
        CATransaction.flush()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: interval))
    }

    private static func place(_ pointer: PointerLayer, _ point: CGPoint, companion: Bool) {
        #if BASELINE
        let position = companion ? CursorGeometry.companion(at: point, in: viewport, size: 132) : point
        pointer.place(position, visible: true, viewport: viewport)
        #else
        pointer.follow(point, in: viewport, visible: true, companion: companion)
        #endif
    }

    private static func frame(_ pointer: PointerLayer, scale: CGFloat, reference: CGPoint? = nil,
                              arrow: Bool = false) throws -> CGImage {
        let bitmap = CGContext(data: nil, width: Int(viewport.width * scale), height: Int(viewport.height * scale),
                               bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                               bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        bitmap.scaleBy(x: scale, y: scale)
        if let reference {
            bitmap.setFillColor(NSColor(srgbRed: 0.88, green: 0.9, blue: 0.94, alpha: 1).cgColor)
            bitmap.fill(viewport)
            bitmap.setStrokeColor(NSColor(srgbRed: 0.32, green: 0.43, blue: 0.59, alpha: 1).cgColor)
            bitmap.setLineWidth(0.5)
            for leg in [CGPoint(x: 0, y: 40), CGPoint(x: 40, y: 0)] {
                bitmap.move(to: CGPoint(x: reference.x - leg.x, y: reference.y - leg.y))
                bitmap.addLine(to: CGPoint(x: reference.x + leg.x, y: reference.y + leg.y))
            }
            bitmap.strokePath()
        }
        guard let presented = pointer.root.presentation() else { throw Failure("No composed layer frame") }
        presented.render(in: bitmap)
        if arrow, let reference {
            let cursor = NSCursor.arrow
            let size = cursor.image.size
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: bitmap, flipped: false)
            cursor.image.draw(at: CGPoint(x: reference.x - cursor.hotSpot.x,
                                          y: reference.y + cursor.hotSpot.y - size.height),
                              from: .zero, operation: .sourceOver, fraction: 1)
            NSGraphicsContext.restoreGraphicsState()
        }
        return bitmap.makeImage()!
    }

    private static func save(_ image: CGImage, to output: URL, named name: String) throws {
        let bitmap = NSBitmapImageRep(cgImage: image)
        try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name + ".png"))
    }

    private static func captureComparisons(_ pointer: PointerLayer, output: URL) throws {
        var prefs = Preferences()
        prefs.size = 132
        for mode in ["companion", "replace"] {
            pointer.reset()
            pointer.configure(image: PointerArt.image(prefs: prefs, scale: 2)!, prefs: prefs)
            let companion = mode == "companion"
            place(pointer, target, companion: companion)
            settle()
            try save(frame(pointer, scale: 2, reference: target, arrow: companion), to: output, named: mode + "-rest")
            #if BASELINE
            // The baseline local monitor only animated Presenter Arm clicks in Studio.
            if companion {
                pointer.poke(at: target, energy: 1, secondary: true, motion: true, effects: true,
                             celebration: false, reduced: false)
            }
            #else
            pointer.poke(at: target, energy: 1, secondary: true, motion: true, effects: true,
                         celebration: false, reduced: false)
            #endif
            settle(0.10)
            try save(frame(pointer, scale: 2, reference: target, arrow: companion), to: output, named: mode + "-click")
        }
    }

    #if !BASELINE
    private static func measure(_ pointer: PointerLayer, style: PointerStyle, size: CGFloat, scale: CGFloat,
                                mode: String) throws {
        var prefs = Preferences()
        prefs.style = style
        prefs.size = size
        prefs.palette = .custom
        prefs.customColour = 0x264DC5
        prefs.outline = false
        prefs.shadow = false
        pointer.reset()
        pointer.configure(image: PointerArt.image(prefs: prefs, scale: scale)!, prefs: prefs)
        let companion = mode == "Companion"
        let expectedTip = companion ? PointerArt.companionPlacement(for: prefs).position(at: target, in: viewport) : target
        if mode == "Click-only" {
            pointer.follow(target, in: viewport, visible: false, companion: false)
            settle()
            let hidden = try frame(pointer, scale: scale)
            guard samples(in: hidden, scale: scale, near: target, radius: 5, matching: { $0.alphaComponent > 0 }).isEmpty else {
                throw Failure("Click-only artwork is visible before the reveal")
            }
        }
        place(pointer, target, companion: companion)
        settle()
        let visible = try frame(pointer, scale: scale)
        let tip = try centre(in: visible, scale: scale, near: expectedTip, radius: 2.5) { colour in
            colour.alphaComponent >= 0.33 && colour.redComponent > 0.74 &&
                colour.greenComponent > 0.80 && colour.blueComponent > 0.77
        }
        // Two clicks within one animation, followed by moving the artwork clear.
        pointer.poke(at: target, energy: 1, secondary: false, motion: true, effects: true,
                     celebration: style == .comicArrow, reduced: false)
        pointer.poke(at: second, energy: 1, secondary: true, motion: true, effects: true,
                     celebration: false, reduced: false)
        pointer.place(CGPoint(x: 18, y: 80), visible: true, viewport: viewport)
        settle(0.10)
        let effects = try frame(pointer, scale: scale)
        let primary = try centre(in: effects, scale: scale, near: target, radius: 3.5) { $0.alphaComponent > 0.28 }
        let secondary = try centre(in: effects, scale: scale, near: second, radius: 22) { $0.alphaComponent > 0.28 }
        let errors = [distance(tip, expectedTip), distance(primary, target), distance(secondary, second)]
        guard errors.allSatisfy({ $0 <= 2 }) else {
            throw Failure("\(style) \(size) pt \(scale)× \(mode) exceeded 2 pt: \(errors); tip \(tip), expected \(expectedTip)")
        }
        print(([style.rawValue, String(Int(size)), String(Int(scale)), mode] +
              [target.x, target.y, tip.x, tip.y, distance(tip, target), errors[0], primary.x, primary.y, errors[1],
               secondary.x, secondary.y, errors[2]].map { String(format: "%.3f", Double($0)) }).joined(separator: ","))
        fflush(stdout)
    }

    private static func measurePresenter(_ pointer: PointerLayer, output: URL) throws {
        for size in [44.0, 76, 132] {
            var prefs = Preferences()
            prefs.size = size
            prefs.shadow = false
            pointer.reset()
            pointer.configure(image: PointerArt.image(prefs: prefs, scale: 2, presenterArm: true)!,
                              prefs: prefs, presenterArm: true)
            for x in [1.0, viewport.midX, viewport.maxX - 1] {
                for y in [1.0, viewport.midY, viewport.maxY - 1] {
                    let point = CGPoint(x: x, y: y)
                    place(pointer, point, companion: false)
                    settle()
                    let image = try frame(pointer, scale: 2)
                    let outline = samples(in: image, scale: 2, near: point, radius: 3) {
                        $0.alphaComponent >= 0.8 && $0.redComponent < 0.45 && $0.greenComponent < 0.45
                    }
                    guard let nearest = outline.map({ distance($0, point) }).min(), nearest <= 2 else {
                        throw Failure("Presenter Arm \(size) pt has no outline within 2 pt of \(point)")
                    }
                    print("Presenter Arm,\(Int(size)),2,outline,\(x),\(y),\(nearest)")
                }
            }
            try measurePresenterEffects(pointer, size: size)
        }
        let point = CGPoint(x: viewport.maxX - 5, y: 7)
        pointer.reset()
        place(pointer, point, companion: false)
        settle()
        try save(frame(pointer, scale: 2, reference: point, arrow: true), to: output, named: "presenter-arm-lower-right")
        place(pointer, target, companion: false)
        pointer.poke(at: target, energy: 1, secondary: true, motion: true, effects: true,
                     celebration: false, reduced: false)
        settle(0.10)
        try save(frame(pointer, scale: 2, reference: target, arrow: true), to: output, named: "presenter-arm-click")
    }

    private static func measurePresenterEffects(_ pointer: PointerLayer, size: CGFloat) throws {
        place(pointer, target, companion: false)
        pointer.poke(at: target, energy: 1, secondary: false, motion: true, effects: true,
                     celebration: true, reduced: false)
        pointer.poke(at: second, energy: 1, secondary: true, motion: false, effects: true,
                     celebration: false, reduced: true)
        pointer.place(CGPoint(x: 18, y: 80), visible: true, viewport: viewport)
        settle(0.062)
        let effects = try frame(pointer, scale: 2)
        let primary = try centre(in: effects, scale: 2, near: target, radius: 3.5) { $0.alphaComponent > 0.28 }
        let secondary = try centre(in: effects, scale: 2, near: second, radius: 15) { $0.alphaComponent > 0.28 }
        guard distance(primary, target) <= 2, distance(secondary, second) <= 2 else {
            throw Failure("Presenter Arm moved a click effect off its reference point")
        }
        print("Presenter Arm,\(Int(size)),2,impact,\(target.x),\(target.y),\(primary.x),\(primary.y),\(second.x),\(second.y),\(secondary.x),\(secondary.y)")
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }

    private static func centre(in image: CGImage, scale: CGFloat, near point: CGPoint, radius: CGFloat,
                               matching: (NSColor) -> Bool) throws -> CGPoint {
        let pixels = samples(in: image, scale: scale, near: point, radius: radius, matching: matching)
        guard let minX = pixels.map(\.x).min(), let maxX = pixels.map(\.x).max(),
              let minY = pixels.map(\.y).min(), let maxY = pixels.map(\.y).max() else {
            throw Failure("No matching rendered pixels near \(point)")
        }
        return CGPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
    }

    private static func samples(in image: CGImage, scale: CGFloat, near point: CGPoint, radius: CGFloat,
                                matching: (NSColor) -> Bool) -> [CGPoint] {
        let bitmap = NSBitmapImageRep(cgImage: image)
        let minX = max(0, Int((point.x - radius) * scale))
        let maxX = min(image.width - 1, Int((point.x + radius) * scale))
        let minY = max(0, Int((viewport.height - point.y - radius) * scale))
        let maxY = min(image.height - 1, Int((viewport.height - point.y + radius) * scale))
        var points: [CGPoint] = []
        for y in minY...maxY {
            for x in minX...maxX {
                guard let colour = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB), matching(colour) else { continue }
                points.append(CGPoint(x: (CGFloat(x) + 0.5) / scale, y: viewport.height - (CGFloat(y) + 0.5) / scale))
            }
        }
        return points
    }
    #endif

    private struct Failure: LocalizedError {
        let errorDescription: String?
        init(_ reason: String) { errorDescription = reason }
    }
}
