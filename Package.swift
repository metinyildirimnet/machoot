// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Machoot",
    platforms: [.macOS("15.2")],
    targets: [
        .executableTarget(
            name: "Machoot",
            path: "Sources/Machoot",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
