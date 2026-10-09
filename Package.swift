// swift-tools-version:5.9
import PackageDescription

var products: [Product] = [
    .library(name: "ToiletCore", targets: ["ToiletCore"]),
]

var targets: [Target] = [
    .target(
        name: "ToiletCore",
        path: "Sources/ToiletCore"
    ),
    .testTarget(
        name: "ToiletCoreTests",
        dependencies: ["ToiletCore"],
        path: "Tests/ToiletCoreTests"
    ),
]

#if os(macOS)
products.append(
    .executable(name: "DesktopToilet", targets: ["DesktopToilet"])
)
targets.append(
    .executableTarget(
        name: "DesktopToilet",
        dependencies: ["ToiletCore"],
        path: "Sources/DesktopToilet",
        linkerSettings: [
            .linkedFramework("SceneKit"),
            .linkedFramework("QuartzCore"),
        ]
    )
)
#endif

let package = Package(
    name: "DesktopToilet",
    platforms: [
        .macOS(.v13),
    ],
    products: products,
    targets: targets,
    swiftLanguageVersions: [.v5]
)
