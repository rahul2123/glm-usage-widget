// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GLMUsageWidget",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "GLMUsageWidget", targets: ["GLMUsageWidget"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "GLMUsageWidget",
            dependencies: [],
            path: "GLMUsageWidget",
            exclude: ["Info.plist", "Assets.xcassets"],
            sources: [
                "App.swift",
                "Models.swift",
                "UsageService.swift",
                "SettingsManager.swift",
                "MenuBarView.swift"
            ],
            resources: []
        )
    ]
)
