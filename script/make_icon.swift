// Compile together with PointerArt.swift and the model sources.
import AppKit
import UniformTypeIdentifiers

@main
enum MakeIcon {
    static func main() {
        let width = 1024
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let ctx = CGContext(data: nil, width: width, height: width, bitsPerComponent: 8,
                            bytesPerRow: 0, space: colorSpace,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.translateBy(x: 0, y: CGFloat(width))
        ctx.scaleBy(x: 1, y: -1)
        let plate = CGPath(roundedRect: CGRect(x: 85, y: 85, width: 854, height: 854),
                           cornerWidth: 193, cornerHeight: 193, transform: nil)
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -17), blur: 33,
                      color: PointerArt.ink.color(0.46))
        ctx.addPath(plate)
        ctx.setFillColor(PointerArt.ink.color())
        ctx.fillPath()
        ctx.restoreGState()

        ctx.addPath(plate)
        ctx.clip()
        let purple = CGGradient(colorsSpace: colorSpace, colors: [
            PointerArt.RGB(0x6C50AE).color(), PointerArt.RGB(0x302146).color()
        ] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(purple, start: CGPoint(x: 120, y: 145), end: CGPoint(x: 865, y: 927),
                               options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.addPath(plate)
        ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.17))
        ctx.setLineWidth(8)
        ctx.strokePath()

        ctx.setStrokeColor(PointerArt.RGB(0xF8DCA8).color())
        ctx.setLineCap(.round)
        ctx.setLineWidth(19)
        for (start, end) in [(CGPoint(x: 282, y: 329), CGPoint(x: 210, y: 310)),
                             (CGPoint(x: 310, y: 276), CGPoint(x: 268, y: 221)),
                             (CGPoint(x: 366, y: 251), CGPoint(x: 363, y: 186))] {
            ctx.move(to: start)
            ctx.addLine(to: end)
            ctx.strokePath()
        }
        ctx.translateBy(x: 90, y: 203)
        ctx.scaleBy(x: 7.55, y: 7.55)
        PointerArt.draw(in: ctx, style: .finger, palette: .original, outline: true, shadow: true)
        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        let output = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(output, ctx.makeImage()!, nil)
        precondition(CGImageDestinationFinalize(output))
    }
}
