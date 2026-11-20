// Render documentation art directly from the app's vector paths.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

@main
enum MakeGallery {
    static func main() throws {
        let width = 960
        let height = 456
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        for row in 0..<2 {
            for (column, style) in PointerStyle.allCases.enumerated() {
                let x = CGFloat(column * 240 + 8)
                let y = CGFloat(row * 228 + 8)
                let tile = CGRect(x: x, y: y, width: 224, height: 212)
                context.setFillColor(PointerArt.RGB(row == 0 ? 0xF1EBE1 : 0x292532).color())
                context.addPath(CGPath(roundedRect: tile, cornerWidth: 19, cornerHeight: 19, transform: nil))
                context.fillPath()
                context.saveGState()
                context.translateBy(x: x + 19, y: y + 9)
                context.scaleBy(x: 1.8, y: 1.8)
                var prefs = Preferences()
                prefs.style = style
                prefs.palette = row == 0 ? .original : .black
                PointerArt.draw(in: context, prefs: prefs)
                context.restoreGState()
            }
        }
        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        let output = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(output, context.makeImage()!, nil)
        precondition(CGImageDestinationFinalize(output))
    }
}
