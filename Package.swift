// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CompanionKit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CompanionKit", targets: ["CompanionKit"])
    ],
    targets: [
        .executableTarget(
            name: "CompanionKit",
            path: "CompanionKit",
            exclude: ["Resources/Assets.xcassets"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "CompanionKitTests",
            dependencies: ["CompanionKit"],
            path: "CompanionKitTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
