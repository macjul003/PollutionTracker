// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PollutionTracker",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PollutionTracker", targets: ["PollutionTracker"])
    ],
    targets: [
        .target(
            name: "PollutionCore",
            dependencies: []
        ),
        .executableTarget(
            name: "PollutionTracker",
            dependencies: ["PollutionCore"],
            path: "Sources/PollutionTracker"
        ),
        .executableTarget(
            name: "PollutionWidget",
            dependencies: ["PollutionCore"],
            path: "Sources/PollutionWidget"
        ),
        .testTarget(
            name: "PollutionCoreTests",
            dependencies: ["PollutionCore"]
        ),
        .executableTarget(
            name: "PollutionVerifier",
            dependencies: ["PollutionCore"],
            path: "Sources/PollutionVerifier"
        )
    ]
)
