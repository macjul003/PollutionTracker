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
        .executableTarget(
            name: "PollutionTracker",
            path: "Sources/PollutionTracker"
        )
    ]
)
