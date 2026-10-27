// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FloatingTodo",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "FloatingTodo", path: "Sources/FloatingTodo")
    ]
)
