// swift-tools-version: 6.0
import PackageDescription

// Separate demo package, so the graded root Package.swift stays unchanged.
// Run from this folder with: swift run
let package = Package(
    name: "StudyPlannerDemo",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "..")
    ],
    targets: [
        .executableTarget(
            name: "StudyPlannerDemo",
            dependencies: [
                .product(name: "StudyPlanner", package: "apd-hw-1")
            ]
        )
    ]
)
