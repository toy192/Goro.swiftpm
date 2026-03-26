// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "Goro",
    platforms: [
        .iOS("16.0")
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
