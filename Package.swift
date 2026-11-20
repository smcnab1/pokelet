// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PokeletCore",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "PokeletCore",
            path: "Pokelet",
            exclude: ["App", "Assets.xcassets", "Info.plist", "Resources", "Views",
                      "Cursor/CursorOverlayWindow.swift", "Services/CursorController.swift",
                      "Services/HotKeys.swift", "Services/PresentationTap.swift"],
            sources: ["Models", "Cursor/PointerArt.swift", "Cursor/PointerLayer.swift", "Services/SoundPlayer.swift"]
        ),
        .testTarget(name: "PokeletCoreTests", dependencies: ["PokeletCore"])
    ]
)
