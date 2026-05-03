# ToastKit-iOS

Enterprise Swift Package distribution for the ToastKit iOS client.

This repository publishes the public iOS SDK as a binary Swift Package. The package exposes the `ToastKit` product, which provides:

- Realtime foreground toast delivery over WebSocket
- Topic-based subscription and multi-tenant org-channel scoping
- SwiftUI overlay mounting with a single view modifier
- APNs fallback state management hooks
- Local preview and delivery-path simulation helpers for QA and integration testing

This repository is the distribution layer. The packaged XCFramework is released through GitHub Releases and consumed through Swift Package Manager.

## Contents

- [What This Package Is](#what-this-package-is)
- [Requirements](#requirements)
- [Package Identity and Product Naming](#package-identity-and-product-naming)
- [Installation](#installation)
- [Integration Checklist](#integration-checklist)
- [Quick Start](#quick-start)
- [Authentication Modes](#authentication-modes)
- [Topic Model](#topic-model)
- [APNs Integration](#apns-integration)
- [Runtime Behavior](#runtime-behavior)
- [Public API Reference](#public-api-reference)
- [Operational Guidance](#operational-guidance)
- [Troubleshooting](#troubleshooting)
- [Binary Distribution](#binary-distribution)
- [Versioning](#versioning)

## What This Package Is

`ToastKit-iOS` is a binary-only Swift Package that ships the `ToastKit` client library.

The intended runtime model is:

1. Your app configures `ToastKit` with an app key and an identity source.
2. Your app mounts the overlay once near the root of the SwiftUI view tree.
3. Your app subscribes to one or more delivery topics.
4. Toasts arriving while the app is foregrounded render in-app.
5. When the app is backgrounded or not connected, your broader integration may use APNs fallback.

This SDK focuses on client delivery and presentation. It does not expose a public server-side publish API from the app process.

## Requirements

- iOS 17.0+
- Xcode 16+
- Swift Package Manager support from Xcode / Swift 5.7 manifest tooling

## Package Identity and Product Naming

These names are easy to mix up, so use the exact values below:

- Repository URL: `https://github.com/bairisland/ToastKit-iOS.git`
- Package identity: `ToastKit-iOS`
- Product name: `ToastKit`
- Import name: `ToastKit`

In a consuming `Package.swift`, the correct declaration is:

```swift
dependencies: [
    .package(url: "https://github.com/bairisland/ToastKit-iOS.git", from: "0.1.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "ToastKit", package: "ToastKit-iOS")
        ]
    )
]
```

In source files:

```swift
import ToastKit
```

## Installation

### Xcode

1. Open your app project in Xcode.
2. Go to `File > Add Package Dependencies...`
3. Enter `https://github.com/bairisland/ToastKit-iOS.git`
4. Select a version rule such as `Up to Next Major` starting at `0.1.0`
5. Add the `ToastKit` product to your application target

### Swift Package Manager

```swift
// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(url: "https://github.com/bairisland/ToastKit-iOS.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: [
                .product(name: "ToastKit", package: "ToastKit-iOS")
            ]
        )
    ]
)
```

## Integration Checklist

For a production integration, treat the following as the minimum setup:

1. Add the Swift package and confirm `import ToastKit` resolves.
2. Configure `ToastKit` once during app startup.
3. Mount `.toastKitOverlay()` once on your root SwiftUI view tree.
4. Register the APNs device token if you want fallback-aware behavior.
5. Subscribe explicitly to the topics your user/session should receive.
6. Keep JWT issuance and topic authorization in your backend, not in the app bundle.
7. Register `ToastKit.onToast` once if you need analytics or side effects.

## Quick Start

The example below shows the recommended SwiftUI shape for a real integration.

```swift
import SwiftUI
import ToastKit

@main
struct ExampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        ToastKit.configure(
            appKey: "tk_live_your_app_key",
            userToken: {
                try await AuthManager.shared.fetchToastKitJWT()
            },
            options: ToastKitOptions(
                webSocketURL: URL(string: "wss://realtime.example.com/v1/realtime"),
                organizationID: "org_123",
                persistDedupe: true,
                fallbackEnabled: true
            )
        )

        ToastKit.subscribe([
            "user:user_123"
        ])

        ToastKit.subscribeOrgChannel("ops")

        ToastKit.onToast { toast in
            Analytics.shared.track(
                name: "toast_received",
                properties: [
                    "id": toast.id,
                    "topic": toast.topic,
                    "delivery_path": toast.deliveryPath.rawValue
                ]
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .toastKitOverlay()
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        ToastKit.registerAPNsDeviceToken(deviceToken)
    }
}
```

## Authentication Modes

The SDK exposes two configuration modes.

### 1. Authenticated mode

Use this in production when your backend issues a short-lived bearer token:

```swift
ToastKit.configure(
    appKey: "tk_live_your_app_key",
    userToken: {
        try await AuthManager.shared.fetchToastKitJWT()
    },
    options: ToastKitOptions(
        webSocketURL: URL(string: "wss://realtime.example.com/v1/realtime"),
        organizationID: "org_123"
    )
)
```

Use authenticated mode when:

- topic access is enforced by backend-issued claims
- users belong to one or more org scopes
- tokens rotate over time
- you do not want identity embedded in the client

### 2. Development mode

Use this only for local integration, preview environments, or controlled QA:

```swift
ToastKit.configure(
    appKey: "tk_dev_your_app_key",
    developmentUserID: "user_123",
    options: ToastKitOptions(
        webSocketURL: URL(string: "wss://realtime.example.com/v1/realtime")
    )
)
```

Development mode uses the supplied user ID as the local identity source. It is not a substitute for production auth.

## Topic Model

Topic subscription is explicit. The SDK does not infer your business routing rules.

Recommended topic patterns:

- `user:<userId>`
- `org:<orgId>:<channel>`

Examples:

```swift
ToastKit.subscribe([
    "user:user_123",
    "org:org_123:billing",
    "org:org_123:ops"
])
```

To unsubscribe:

```swift
ToastKit.unsubscribe([
    "org:org_123:billing"
])
```

To subscribe using the configured org scope:

```swift
ToastKit.subscribeOrgChannel("ops")
```

`subscribeOrgChannel(_:)` uses `ToastKitOptions.organizationID`. If no org ID was configured, the call is ignored.

## APNs Integration

ToastKit exposes client-side APNs state hooks. Register the token if your integration needs fallback-aware behavior or QA simulation.

### Register a token from Apple callbacks

```swift
func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
    ToastKit.registerAPNsDeviceToken(deviceToken)
}
```

### Register a token string directly

```swift
ToastKit.registerAPNsDeviceTokenString("0123abcd...")
```

### Configure the APNs environment

```swift
ToastKit.setAPNsEnvironment(.production)
```

### Temporarily disable fallback behavior

```swift
ToastKit.setFallbackEnabled(false)
```

### Clear the local token

```swift
ToastKit.clearAPNsDeviceToken()
```

Important constraint:

- This SDK stores APNs token state locally for client behavior.
- If your backend requires explicit APNs token registration, perform that registration in your own integration layer.
- Do not assume `registerAPNsDeviceToken` by itself publishes the token to your backend.

## Runtime Behavior

These semantics matter in production.

### Foreground rendering requires the overlay

Toasts only render into your app UI when the overlay is mounted:

```swift
RootView()
    .toastKitOverlay()
```

Mount the overlay once, as high in the SwiftUI tree as practical.

### `configure` starts the client lifecycle

`ToastKit.configure(...)` configures internal state and initiates connection flow. Use `ToastKit.connect()` if you explicitly disconnected earlier and want to reconnect under your own lifecycle control.

### Connection state is process-wide

The client is implemented as a singleton-style process-wide runtime. Treat configuration and handler registration as application-level setup, not per-screen setup.

### Handlers accumulate

`ToastKit.onToast(_:)` appends a callback and does not currently expose a removal token. Register it once during startup, not on every view appearance.

### Local helpers are local helpers

The following APIs are for testing, preview, or QA flows:

- `ToastKit.show(_:)`
- `ToastKit.previewPublish(_:)`

They do not replace your backend publish path.

## Public API Reference

### Configuration

```swift
ToastKit.configure(
    appKey:userToken:apnsDeviceTokenProvider:options:
)

ToastKit.configure(
    appKey:developmentUserID:apnsDeviceTokenProvider:options:
)
```

`ToastKitOptions` fields:

| Field | Type | Default | Notes |
| --- | --- | --- | --- |
| `baseURL` | `URL` | `https://api.toastbus.io` | Reserved for broader integration configuration |
| `webSocketURL` | `URL?` | `nil` | Required for realtime WebSocket transport |
| `organizationID` | `String?` | `nil` | Used by `subscribeOrgChannel(_:)` |
| `persistDedupe` | `Bool` | `false` | Persists seen IDs and dedupe keys across launches |
| `fallbackEnabled` | `Bool` | `true` | Enables fallback-aware behavior |
| `diagnosticsEnabled` | `Bool` | `true` | Enables internal diagnostics capture |
| `reconnectPolicy` | `ToastKitReconnectPolicy` | default | Exponential reconnect settings |

### Connection lifecycle

```swift
await ToastKit.connect()
await ToastKit.disconnect()
ToastKit.retryConnection()
```

Main-actor state accessors:

```swift
let state = await MainActor.run { ToastKit.connectionState }
let topics = await MainActor.run { ToastKit.subscribedTopics }
let latest = await MainActor.run { ToastKit.latestToast }
let apnsEnv = await MainActor.run { ToastKit.apnsEnvironment }
```

### Topic management

```swift
ToastKit.subscribe(["user:user_123"])
ToastKit.subscribeOrgChannel("ops")
ToastKit.unsubscribe(["user:user_123"])
```

### Toast callbacks

```swift
ToastKit.onToast { toast in
    print(toast.title)
}
```

### Local preview helpers

```swift
ToastKit.show(
    ToastKitToast(
        topic: "user:user_123",
        title: "Build finished",
        body: "The export completed successfully",
        style: .success,
        priority: .normal
    )
)
```

```swift
let path = await MainActor.run {
    ToastKit.previewPublish(
        ToastKitPublishRequest(
            topic: "user:user_123",
            toast: ToastKitPublishPayload(
                title: "Preview toast",
                body: "Testing local delivery behavior"
            )
        )
    )
}
```

### Core models

`ToastKitToast`

- `id`
- `topic`
- `title`
- `body`
- `style`
- `priority`
- `durationMilliseconds`
- `deepLink`
- `metadata`
- `dedupeKey`
- `collapseKey`
- `createdAt`
- `deliveryPath`

`ToastKitToastStyle`

- `.info`
- `.success`
- `.warning`
- `.error`

`ToastKitToastPriority`

- `.low`
- `.normal`
- `.high`

`ToastKitDeliveryPath`

- `.websocket`
- `.apnsFallback`
- `.apnsFallbackThenReconnect`
- `.localMock`
- `.dropped`

## Operational Guidance

### JWT handling

- Use short-lived JWTs.
- Mint tokens server-side.
- Keep topic claims least-privileged.
- Rotate tokens through your normal auth refresh path.
- Do not hardcode bearer tokens in the app bundle.

### Multi-tenant isolation

- Prefer org-scoped topics such as `org:<orgId>:<channel>`.
- Configure `organizationID` when your app is tenant-bound.
- Use `subscribeOrgChannel(_:)` to reduce accidental cross-tenant topic construction in client code.

### Dedupe and collapse behavior

If your publisher sends stable IDs, dedupe keys, or collapse keys, the client can suppress duplicate events and replace in-flight toasts with newer state.

If you want dedupe memory to survive process restarts, set:

```swift
ToastKitOptions(persistDedupe: true)
```

### Debug logging

The SDK exposes a debug flag:

```swift
ToastKit.debug = true
```

Use this only in debug builds or controlled troubleshooting sessions.

## Troubleshooting

### `import ToastKit` fails

Check the package product declaration in the consuming target:

```swift
.product(name: "ToastKit", package: "ToastKit-iOS")
```

### The package resolves but no toast appears

Check the common failure points:

1. `.toastKitOverlay()` is not mounted at the app root.
2. The app is not foregrounded.
3. No matching topic subscription was added.
4. Your callback was registered but UI overlay was never mounted.
5. Your topic was unauthorized by the token claims.

### APNs fallback does not occur

Check:

1. A device token was registered with `ToastKit`.
2. Fallback was not disabled with `setFallbackEnabled(false)`.
3. Your backend has whatever APNs registration flow it requires.

### You see duplicate side effects from `onToast`

Register `ToastKit.onToast` once. Re-registering the handler on every screen or every appearance will stack callbacks.

## Binary Distribution

This repository publishes a binary target backed by the release asset:

```text
https://github.com/bairisland/ToastKit-iOS/releases/download/0.1.0/ToastKit.xcframework.zip
```

Current `0.1.0` checksum:

```text
0764e1a4c59ed23a8dfb0fcaed786548d15e152804812a06875d5c52165ce4ed
```

The public [Package.swift](/Users/bairisland/Developer/ToastKit-iOS/Package.swift) is intentionally binary-only and points at that asset.

## Versioning

- Git tag: `0.1.0`
- Distribution model: binary Swift Package via GitHub Release asset
- Consumer dependency recommendation: `from: "0.1.0"`
