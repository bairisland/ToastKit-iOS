// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "ToastKit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ToastKit",
            targets: ["ToastKit"]
        )
    ],
    targets: [
        .target(
            name: "ToastKit",
            path: "Sources/ToastKit"
        ),
        .testTarget(
            name: "ToastKitTests",
            dependencies: ["ToastKit"],
            path: "Tests/ToastKitTests"
        )
    ]
)
