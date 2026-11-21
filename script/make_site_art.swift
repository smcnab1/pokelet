// Export transparent web artwork and cursor-sized PNGs from the native renderer.
import Foundation
import ImageIO
import UniformTypeIdentifiers

@main
enum MakeSiteArt {
    static func main() throws {
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        for style in PointerStyle.allCases {
            for palette: Palette in [.original, .white, .black] {
                let name = "\(style.rawValue)-\(palette.rawValue)"
                try render(style, palette: palette, pixels: 312, to: output.appendingPathComponent("\(name).png"))
                try render(style, palette: palette, pixels: 52, to: output.appendingPathComponent("\(name)-cursor.png"))
            }
        }
    }

    private static func render(_ style: PointerStyle, palette: Palette, pixels: Int, to url: URL) throws {
        var prefs = Preferences()
        prefs.style = style
        prefs.palette = palette
        prefs.size = CGFloat(pixels)
        prefs.shadow = false

        guard let image = PointerArt.image(prefs: prefs, scale: 1),
              let png = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { throw CocoaError(.fileWriteUnknown) }
        CGImageDestinationAddImage(png, image, nil)
        guard CGImageDestinationFinalize(png) else { throw CocoaError(.fileWriteUnknown) }
    }
}
