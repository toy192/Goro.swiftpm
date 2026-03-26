// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Goro",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "Goro",
            targets: ["AppModule"],
            bundleIdentifier: "com.toy192.goro",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .person),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "Sources"
        )
    ]
)
