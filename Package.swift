// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PokeletCore",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "PokeletCore", path: "Pokelet/Models"),
        .testTarget(name: "PokeletCoreTests", dependencies: ["PokeletCore"])
    ]
)
