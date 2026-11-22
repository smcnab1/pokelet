// Generate the Finder background from Pokelet's original pointer artwork.
import AppKit
import CoreText
import ImageIO
import UniformTypeIdentifiers

@main
enum InstallerBackground {
    static let size = CGSize(width: 720, height: 432)
    static let space = CGColorSpace(name: CGColorSpace.sRGB)!

    static func main() {
        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        let output = CGImageDestinationCreateWithURL(url as CFURL, UTType.tiff.identifier as CFString, 2, nil)!
        for scale in [1, 2] {
            let context = CGContext(data: nil, width: Int(size.width) * scale, height: Int(size.height) * scale,
                                    bitsPerComponent: 8, bytesPerRow: 0, space: space,
                                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
            context.translateBy(x: 0, y: size.height * CGFloat(scale))
            context.scaleBy(x: CGFloat(scale), y: -CGFloat(scale))
            draw(in: context)

            CGImageDestinationAddImage(output, context.makeImage()!, [
                kCGImagePropertyDPIWidth: 72 * scale,
                kCGImagePropertyDPIHeight: 72 * scale,
                kCGImagePropertyTIFFDictionary: [
                    kCGImagePropertyTIFFCompression: NSBitmapImageRep.TIFFCompression.lzw.rawValue
                ]
            ] as CFDictionary)
        }
        precondition(CGImageDestinationFinalize(output))
    }

    static func draw(in context: CGContext) {
        let field = CGGradient(colorsSpace: space, colors: [
            colour(0x25172F), colour(0x1E1529), colour(0x15111E)
        ] as CFArray, locations: [0, 0.59, 1])!
        context.drawLinearGradient(field, start: CGPoint(x: 540, y: 0),
                                   end: CGPoint(x: 460, y: size.height),
                                   options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        glow(context, at: CGPoint(x: 616, y: 45), radius: 270, hex: 0x834DBB, alpha: 0.42)

        // A partial orbit echoes the click effects in Studio and frames the glove.
        context.saveGState()
        context.translateBy(x: 613, y: 82)
        context.rotate(by: -.pi / 6)
        context.setLineWidth(0.75)
        for (radius, opacity) in [(1.0, 0.26), (1.21, 0.12)] {
            context.setStrokeColor(colour(0xDCC0FF, opacity))
            context.strokeEllipse(in: CGRect(x: -113 * radius, y: -49 * radius,
                                             width: 226 * radius, height: 98 * radius))
        }
        context.restoreGState()
        sparkle(context, x: 686, y: 43, radius: 8, hex: 0xE4C9FF, alpha: 0.86)
        sparkle(context, x: 540, y: 127, radius: 5, hex: 0xE4C9FF, alpha: 0.54)

        context.saveGState()
        context.translateBy(x: 611, y: 77)
        context.rotate(by: -.pi / 12)
        context.scaleBy(x: 1.48, y: 1.48)
        context.translateBy(x: -61, y: -54)
        var palette = Preferences()
        palette.style = .finger
        palette.palette = .lilac
        palette.shadow = true
        PointerArt.draw(in: context, prefs: palette)
        context.restoreGState()

        sparkle(context, x: 60, y: 48, radius: 7, hex: 0xE6C7FF, alpha: 1)
        text(context, "Pokelet", x: 75, baseline: 54, size: 16, weight: .semibold, hex: 0xF2DFFF)
        text(context, "Bring your pointer", x: 51, baseline: 108, size: 43, weight: .bold,
             hex: 0xFCF3FB, tracking: -1)
        text(context, "to life.", x: 51, baseline: 152, size: 43, weight: .bold,
             hex: 0xE3BFFF, tracking: -1)

        // Finder uses dark item labels on a picture background, including in Dark Mode.
        // Keep the drop area pale enough for the native labels in both appearances.
        let tray = CGPath(roundedRect: CGRect(x: 51, y: 191, width: 618, height: 200),
                          cornerWidth: 23, cornerHeight: 23, transform: nil)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -8), blur: 26, color: colour(0x10091B, 0.34))
        context.setFillColor(colour(0xE8DAF4))
        context.addPath(tray)
        context.fillPath()
        context.restoreGState()

        context.saveGState()
        context.addPath(tray)
        context.clip()
        let trayFill = CGGradient(colorsSpace: space, colors: [
            colour(0xF2E8FA), colour(0xD9C6E8)
        ] as CFArray, locations: [0, 1])!
        context.drawLinearGradient(trayFill, start: CGPoint(x: 356, y: 190), end: CGPoint(x: 286, y: 391),
                                   options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        context.restoreGState()

        let arrow = PointerArt.makePath { pen in
            pen.m(326, 249)
            pen.l(392, 249)
            pen.m(381, 238)
            pen.l(392, 249)
            pen.l(381, 260)
        }
        context.setLineWidth(1.8)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        context.setStrokeColor(colour(0x644678))
        context.addPath(arrow)
        context.strokePath()

        text(context, "Drag to Applications", x: size.width / 2, baseline: 368, size: 16,
             weight: .semibold, hex: 0x442F57, centred: true)
    }

    static func colour(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
        PointerArt.RGB(hex).color(alpha)
    }

    static func glow(_ context: CGContext, at centre: CGPoint, radius: CGFloat, hex: UInt32, alpha: CGFloat) {
        let gradient = CGGradient(colorsSpace: space, colors: [
            colour(hex, alpha), colour(hex, alpha * 0.34), colour(hex, 0)
        ] as CFArray, locations: [0, 0.5, 1])!
        context.drawRadialGradient(gradient, startCenter: centre, startRadius: 0,
                                   endCenter: centre, endRadius: radius, options: [])
    }

    static func sparkle(_ context: CGContext, x: CGFloat, y: CGFloat, radius: CGFloat, hex: UInt32, alpha: CGFloat) {
        context.saveGState()
        context.translateBy(x: x, y: y)
        context.scaleBy(x: radius, y: radius)
        let path = PointerArt.makePath { pen in
            pen.m(0, -1)
            pen.c(0.14, -0.30, 0.30, -0.14, 1, 0)
            pen.c(0.30, 0.14, 0.14, 0.30, 0, 1)
            pen.c(-0.14, 0.30, -0.30, 0.14, -1, 0)
            pen.c(-0.30, -0.14, -0.14, -0.30, 0, -1)
            pen.z()
        }
        context.setFillColor(colour(hex, alpha))
        context.addPath(path)
        context.fillPath()
        context.restoreGState()
    }

    static func text(_ context: CGContext, _ string: String, x: CGFloat, baseline: CGFloat, size: CGFloat,
                     weight: NSFont.Weight, hex: UInt32, tracking: CGFloat = 0, centred: Bool = false) {
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: string, attributes: [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .kern: tracking,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): colour(hex)
        ]))
        let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
        context.saveGState()
        context.translateBy(x: centred ? x - width / 2 : x, y: baseline)
        context.scaleBy(x: 1, y: -1)
        context.textPosition = .zero
        CTLineDraw(line, context)
        context.restoreGState()
    }
}
