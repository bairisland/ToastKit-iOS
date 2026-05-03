// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "ToastKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ToastKit",
            targets: ["ToastKit"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "ToastKit",
            url: "https://github.com/bairisland/ToastKit-iOS/releases/download/0.1.0/ToastKit.xcframework.zip",
            checksum: "0764e1a4c59ed23a8dfb0fcaed786548d15e152804812a06875d5c52165ce4ed"
        )
    ]
)
