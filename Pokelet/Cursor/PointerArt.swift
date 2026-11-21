import AppKit

/// Original artwork in a 104-point, top-down coordinate space.
enum PointerArt {
    static let canvas = CursorGeometry.canvas
    static let ink = RGB(0x27213A)

    struct RGB {
        let hex: UInt32
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat

        init(_ hex: UInt32) {
            self.hex = hex
            r = CGFloat((hex >> 16) & 255) / 255
            g = CGFloat((hex >> 8) & 255) / 255
            b = CGFloat(hex & 255) / 255
        }

        var luminance: CGFloat {
            func linear(_ value: CGFloat) -> CGFloat {
                value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
        }

        func shaded(by factor: CGFloat) -> RGB {
            let red = UInt32(r * factor * 255)
            let green = UInt32(g * factor * 255)
            let blue = UInt32(b * factor * 255)
            return RGB(red << 16 | green << 8 | blue)
        }

        func color(_ alpha: CGFloat = 1) -> CGColor {
            CGColor(red: r, green: g, blue: b, alpha: alpha)
        }
    }

    struct Inks {
        let primary: RGB
        let secondary: RGB
        let outline: RGB
        let halo: RGB
        let highlight: RGB
        let shadow: RGB
        let accent: RGB
        let marks: RGB
        let effect: RGB
    }

    static func inks(for prefs: Preferences) -> Inks {
        let (primary, secondary) = fills(for: prefs)
        let darkFill = (primary.luminance + secondary.luminance) / 2 < 0.18
        let lightInk = RGB(0xFFF8EE)
        let accent = drawings[prefs.style]?.accentColor ?? lightInk
        let lightFill = prefs.palette == .white || prefs.palette == .custom
        let marks = darkFill ? lightInk : lightFill || prefs.style == .finger || prefs.style == .catPaw ? ink : accent
        let effect = prefs.palette == .black ? lightInk : prefs.palette == .white ? ink : secondary
        return Inks(primary: primary, secondary: secondary, outline: darkFill ? lightInk : ink,
                    halo: darkFill ? ink : lightInk, highlight: lightInk, shadow: ink,
                    accent: accent, marks: marks, effect: effect)
    }

    private static func fills(for prefs: Preferences) -> (RGB, RGB) {
        switch prefs.palette {
        case .black: (RGB(0x000000), RGB(0x000000))
        case .white: (RGB(0xFFFFFF), RGB(0xF3F2F1))
        case .custom: customFills(prefs.customColour ?? Preferences.defaultCustomColour)
        case .peach: (RGB(0xFFE3BA), RGB(0xF38D68))
        case .mint: (RGB(0xD9F9C0), RGB(0x6BD0AD))
        case .lilac: (RGB(0xF7DFFF), RGB(0xA78CE8))
        case .ice: (RGB(0xE4FFFF), RGB(0x7AC1F0))
        case .original:
            switch prefs.style {
            case .finger: (RGB(0xFFEEB3), RGB(0xF4A36F))
            case .catPaw: (RGB(0xF8EFFF), RGB(0xBAA6EC))
            case .foamFinger: (RGB(0xFFB396), RGB(0xF26871))
            case .comicArrow: (RGB(0xD5FFF0), RGB(0x6DD8C2))
            }
        }
    }

    private static func customFills(_ hex: UInt32) -> (RGB, RGB) {
        let colour = RGB(hex)
        return (colour, colour.shaded(by: 0.75))
    }

    private struct Art {
        let tip: CGPoint
        let silhouette: CGPath
        let marks: CGPath
        let accent: CGPath?
        let accentColor: RGB
    }

    private static let drawings: [PointerStyle: Art] = [
        .finger: Art(tip: CGPoint(x: 29.2, y: 16), silhouette: makePath { p in
            p.m(32, 15); p.c(38, 12, 44, 18, 47, 25)
            p.l(56, 43); p.c(63, 39, 68, 42, 70, 48)
            p.c(76, 44, 83, 47, 84, 54)
            p.c(92, 52, 97, 58, 95, 67)
            p.l(92, 78); p.c(90, 87, 84, 93, 79, 96)
            p.l(58, 96); p.c(56, 88, 48, 84, 43, 78)
            p.l(32, 65); p.c(27, 58, 33, 51, 40, 54)
            p.l(45, 57); p.l(28, 29); p.c(24, 22, 27, 17, 32, 15); p.z()
        }, marks: makePath { p in
            p.m(56, 43); p.l(60, 51)
            p.m(70, 48); p.l(73, 56)
            p.m(84, 54); p.l(85, 61)
            p.m(45, 57); p.l(52, 65)
            p.m(60, 77); p.c(64, 70, 70, 68, 77, 70)
        }, accent: makePath { p in
            p.m(34, 23); p.c(37, 22, 41, 26, 43, 31)
            p.l(47, 39); p.c(41, 44, 39, 42, 36, 36)
            p.c(32, 29, 31, 25, 34, 23); p.z()
        }, accentColor: RGB(0xFFF6D5)),
        .catPaw: Art(tip: CGPoint(x: 28.3, y: 16.5), silhouette: makePath { p in
            p.m(32, 15); p.c(40, 12, 46, 19, 49, 26)
            p.c(50, 16, 62, 15, 68, 23)
            p.c(71, 27, 72, 31, 72, 35)
            p.c(81, 28, 91, 35, 92, 44)
            p.c(92, 47, 91, 50, 90, 52)
            p.c(101, 50, 104, 63, 96, 71)
            p.c(91, 77, 83, 81, 80, 95)
            p.l(56, 95); p.c(54, 84, 46, 79, 38, 68)
            p.c(33, 61, 29, 55, 24, 44)
            p.c(18, 30, 22, 20, 32, 15); p.z()
        }, marks: makePath { p in
            p.m(29, 23); p.c(33, 14.5, 37, 15, 39, 18)
            p.m(57, 89); p.c(63, 87, 72, 87, 80, 90)
        }, accent: makePath { p in
            p.ellipse(29, 26, 12, 17); p.ellipse(54, 27, 12, 17)
            p.ellipse(75, 40, 12, 15); p.ellipse(86, 56, 11, 12)
            p.m(46, 63); p.c(44, 58, 48, 52, 54, 51)
            p.c(59, 49, 65, 52, 67, 57)
            p.c(75, 57, 81, 63, 78, 70)
            p.c(76, 77, 69, 80, 64, 76)
            p.c(57, 77, 47, 72, 46, 63); p.z()
        }, accentColor: RGB(0xEF8AB8)),
        .foamFinger: Art(tip: CGPoint(x: 27.9, y: 16.1), silhouette: makePath { p in
            p.m(32, 15); p.c(38, 12, 43, 17, 46, 22)
            p.l(64, 50); p.l(70, 45); p.c(75, 40, 84, 43, 86, 49)
            p.l(97, 76); p.c(100, 83, 97, 91, 89, 95)
            p.l(57, 98); p.l(30, 77); p.c(24, 72, 24, 62, 31, 58)
            p.l(44, 53); p.l(25, 30); p.c(20, 23, 24, 18, 32, 15); p.z()
        }, marks: makePath { p in
            p.m(34, 23); p.l(57, 59); p.l(75, 51); p.l(89, 83); p.l(59, 89)
            p.l(34, 69); p.l(45, 64)
            p.m(65, 82); p.l(58, 68); p.l(55, 72)
            p.m(60, 83); p.l(70, 81)
            p.m(78, 64); p.l(82, 73)
        }, accent: nil, accentColor: RGB(0xFFF3D9)),
        .comicArrow: Art(tip: CGPoint(x: 30, y: 15.1), silhouette: makePath { p in
            p.m(32, 15); p.l(91, 54); p.c(94, 56, 93, 59, 90, 60)
            p.l(69, 65); p.l(81, 85); p.c(82, 88, 82, 90, 79, 91)
            p.l(68, 97); p.c(66, 98, 64, 97, 63, 95)
            p.l(51, 74); p.l(36, 88); p.c(33, 90, 30, 89, 30, 86)
            p.l(29, 20); p.c(29, 17, 30, 15, 32, 15); p.z()
        }, marks: makePath { p in
            p.m(38, 30); p.l(71, 51)
            p.m(38, 39); p.l(39, 72)
            p.m(59, 74); p.l(70, 90)
        }, accent: nil, accentColor: RGB(0xF4FFF9))
    ]

    static func tip(for style: PointerStyle) -> CGPoint { drawings[style]!.tip }

    static func companionPlacement(for prefs: Preferences) -> CompanionPlacement {
        let art = drawings[prefs.style]!
        let scale = prefs.size / canvas
        let outline: CGFloat = prefs.outline ? 2.75 : 0
        let path = art.silhouette.boundingBoxOfPath.insetBy(dx: -outline, dy: -outline)
        let ink = CGRect(x: (path.minX - art.tip.x) * scale, y: (art.tip.y - path.maxY) * scale,
                         width: path.width * scale, height: path.height * scale)
        let arrow = NSCursor.arrow
        let size = arrow.image.size
        return CompanionPlacement(ink: ink,
                                  arrow: CGRect(x: -arrow.hotSpot.x, y: arrow.hotSpot.y - size.height,
                                                width: size.width, height: size.height),
                                  gap: max(3, prefs.size * 0.045))
    }

    static func image(prefs: Preferences, scale: CGFloat, presenterArm: Bool = false) -> CGImage? {
        let pixels = Int(ceil(prefs.size * scale))
        guard let context = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        let factor = CGFloat(pixels) / canvas
        context.translateBy(x: 0, y: CGFloat(pixels))
        context.scaleBy(x: factor, y: -factor)
        if presenterArm { drawPresenterGlove(in: context, shadow: prefs.shadow) }
        else { draw(in: context, prefs: prefs) }
        return context.makeImage()
    }

    static func draw(in context: CGContext, prefs: Preferences) {
        let style = prefs.style
        guard let art = drawings[style] else { return }
        let inks = inks(for: prefs)

        if prefs.shadow {
            context.saveGState()
            context.setShadow(offset: CGSize(width: 0, height: -2), blur: 4, color: inks.shadow.color(0.48))
            context.setFillColor(inks.secondary.color())
            context.addPath(art.silhouette)
            context.fillPath()
            context.restoreGState()
        }
        context.saveGState()
        context.addPath(art.silhouette)
        context.clip()
        if let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                     colors: [inks.primary.color(), inks.secondary.color()] as CFArray, locations: [0, 1]) {
            context.drawLinearGradient(gradient, start: CGPoint(x: 16, y: 20), end: CGPoint(x: 91, y: 99),
                                       options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        }
        context.restoreGState()

        context.setLineJoin(.round)
        context.setLineCap(.round)
        if prefs.outline {
            context.addPath(art.silhouette)
            context.setStrokeColor(inks.halo.color(0.72))
            context.setLineWidth(5.5)
            context.strokePath()
            context.addPath(art.silhouette)
            context.setStrokeColor(inks.outline.color())
            context.setLineWidth(3.4)
            context.strokePath()
        }
        if let accent = art.accent {
            context.addPath(accent)
            context.setFillColor(inks.accent.color(style == .finger ? 0.72 : 0.95))
            context.fillPath()
        }
        context.addPath(art.marks)
        context.setStrokeColor(inks.marks.color(0.9))
        context.setLineWidth(style == .foamFinger ? 2.9 : 2.05)
        context.strokePath()

        // A tiny keyed highlight identifies the contact point on the painted tip.
        let hotspot = art.tip
        let radius: CGFloat = 1.8
        context.setFillColor(inks.highlight.color(0.96))
        context.fillEllipse(in: CGRect(x: hotspot.x - radius, y: hotspot.y - radius,
                                       width: 2 * radius, height: 2 * radius))
    }

    static func makePath(_ draw: (Pen) -> Void) -> CGPath {
        let path = CGMutablePath()
        draw(Pen(path: path))
        return path.copy()!
    }

    struct Pen {
        let path: CGMutablePath
        func m(_ x: CGFloat, _ y: CGFloat) { path.move(to: CGPoint(x: x, y: y)) }
        func l(_ x: CGFloat, _ y: CGFloat) { path.addLine(to: CGPoint(x: x, y: y)) }
        func c(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ x: CGFloat, _ y: CGFloat) {
            path.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: x1, y: y1),
                          control2: CGPoint(x: x2, y: y2))
        }
        func ellipse(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
            path.addEllipse(in: CGRect(x: x, y: y, width: width, height: height))
        }
        func z() { path.closeSubpath() }
    }
}
