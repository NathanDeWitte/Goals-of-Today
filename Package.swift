// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GoalsOfToday",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "GoalsOfToday",
            path: "Sources/GoalsOfToday",
            resources: [.copy("Resources/fonts")]
        )
    ]
)
