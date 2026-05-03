# ToastKit

Binary Swift Package distribution for the ToastKit iOS SDK.

## Requirements

- iOS 17.0+
- Xcode 16+

## Install

Add the package in Xcode with:

```text
https://github.com/bairisland/ToastKit-iOS.git
```

Or declare it in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/bairisland/ToastKit-iOS.git", from: "0.1.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["ToastKit"]
    )
]
```

## Distribution

This repository ships a `binaryTarget` that resolves to the release asset:

```text
https://github.com/bairisland/ToastKit-iOS/releases/download/0.1.0/ToastKit.xcframework.zip
```
