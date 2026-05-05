<h1 align="center">Official ToastKit iOS SDK</h1>

<p align="center">
  Binary Swift Package for realtime in-app toast delivery on iOS.
</p>

<p align="center">
  <a href="https://github.com/bairisland/ToastKit-iOS/releases/tag/0.1.0">
    <img src="https://img.shields.io/github/v/release/bairisland/ToastKit-iOS?label=release" alt="Release">
  </a>
  <a href="#installation">
    <img src="https://img.shields.io/badge/distribution-SwiftPM-orange" alt="SwiftPM">
  </a>
  <a href="#requirements">
    <img src="https://img.shields.io/badge/iOS-17%2B-blue" alt="iOS 17+">
  </a>
  <a href="#binary-distribution">
    <img src="https://img.shields.io/badge/package-binary%20target-black" alt="Binary Target">
  </a>
</p>

ToastKit gives iOS teams a single client surface for:

- Realtime foreground toast delivery over WebSocket
- Topic-based routing for user and org-scoped channels
- SwiftUI overlay mounting with one root-level modifier
- APNs-aware client state hooks for fallback-oriented integrations
- Local preview and delivery-path simulation helpers for QA

This repository is the public distribution layer for the iOS SDK. It ships `ToastKit` as a binary Swift Package backed by a GitHub Release XCFramework.

https://toast-kit.replit.app/

## Get Started

1. Obtain your ToastKit `appKey` and WebSocket endpoint from your deployment environment.
2. Add `https://github.com/bairisland/ToastKit-iOS.git` to your app with Swift Package Manager.
3. Configure `ToastKit` during app startup using a backend-issued JWT provider.
4. Mount `.toastKitOverlay()` once near the root of your SwiftUI app.
5. Subscribe to the user and org topics your session is authorized to receive.

## Requirements

| Component | Version |
| --- | --- |
| iOS | 17.0+ |
| Xcode | 16+ |
| Distribution | Swift Package Manager |

## Installation

### Xcode

1. Open your project in Xcode.
2. Go to `File > Add Package Dependencies...`
3. Search for `https://github.com/bairisland/ToastKit-iOS.git`
4. Select a version rule starting from `0.1.0`
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

### Package Identity

Use these exact names in consuming code:

- Repository URL: `https://github.com/bairisland/ToastKit-iOS.git`
- Package identity: `ToastKit-iOS`
- Product name: `ToastKit`
- Import name: `ToastKit`

```swift
import ToastKit
```

## Quick Start

The example below shows the intended SwiftUI integration shape for a production app.

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

## Production Integration

### Authenticated mode

Use authenticated mode in production. Your backend should mint a short-lived JWT for the current user session.

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

Recommended use cases:

- user-specific topic authorization
- org-scoped channel authorization
- short-lived token rotation
- production multi-tenant deployments

### Development mode

Use development mode only for local integration, QA, or controlled preview environments.

```swift
ToastKit.configure(
    appKey: "tk_dev_your_app_key",
    developmentUserID: "user_123",
    options: ToastKitOptions(
        webSocketURL: URL(string: "wss://realtime.example.com/v1/realtime")
    )
)
```

This mode is not a substitute for production auth.

### Topic model

Topic subscription is explicit. The SDK does not infer your routing model.

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

```swift
ToastKit.unsubscribe([
    "org:org_123:billing"
])
```

If your app is tenant-bound, configure `organizationID` and use:

```swift
ToastKit.subscribeOrgChannel("ops")
```

`subscribeOrgChannel(_:)` uses the configured `ToastKitOptions.organizationID`. If no org ID is configured, the call is ignored.

### APNs integration

ToastKit exposes client-side APNs state hooks. Register the device token if your integration needs fallback-aware behavior or client-side QA simulation.

Register from Apple callbacks:

```swift
func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
    ToastKit.registerAPNsDeviceToken(deviceToken)
}
```

Register a token string directly:

```swift
ToastKit.registerAPNsDeviceTokenString("0123abcd...")
```

Configure environment:

```swift
ToastKit.setAPNsEnvironment(.production)
```

Disable fallback-aware behavior:

```swift
ToastKit.setFallbackEnabled(false)
```

Clear local token state:

```swift
ToastKit.clearAPNsDeviceToken()
```

Important:

- The SDK stores APNs token state locally for client behavior.
- If your backend requires APNs token registration, perform that in your own application/backend integration.
- Do not assume `registerAPNsDeviceToken` by itself publishes token state upstream.

## Runtime Model

### Overlay required for foreground rendering

Toasts render in-app only when the overlay is mounted:

```swift
RootView()
    .toastKitOverlay()
```

Mount it once, as high in the SwiftUI hierarchy as practical.

### Configuration is application-level

`ToastKit.configure(...)` initializes process-wide client state and begins connection flow. Treat configuration as app startup work, not per-screen work.

### Handlers are additive

`ToastKit.onToast(_:)` appends a handler and does not currently expose a removal token. Register it once during startup or in a dedicated app-wide coordinator.

### Local preview helpers are not your publish path

The following APIs are intended for preview, QA, and local simulation:

- `ToastKit.show(_:)`
- `ToastKit.previewPublish(_:)`

They do not replace a real backend publish path.

## Public API Overview

### Core entry points

| Area | API |
| --- | --- |
| Configure | `configure(appKey:userToken:apnsDeviceTokenProvider:options:)` |
| Configure for development | `configure(appKey:developmentUserID:apnsDeviceTokenProvider:options:)` |
| Connection | `connect()`, `disconnect()`, `retryConnection()` |
| Topic management | `subscribe(_:)`, `subscribeOrgChannel(_:)`, `unsubscribe(_:)` |
| APNs state | `registerAPNsDeviceToken(_:)`, `registerAPNsDeviceTokenString(_:)`, `clearAPNsDeviceToken()` |
| APNs behavior | `setAPNsEnvironment(_:)`, `setFallbackEnabled(_:)` |
| Events | `onToast(_:)`, `latestToast` |
| Local QA helpers | `show(_:)`, `previewPublish(_:)` |
| SwiftUI | `View.toastKitOverlay()` |

### `ToastKitOptions`

| Field | Type | Default | Notes |
| --- | --- | --- | --- |
| `baseURL` | `URL` | `https://api.toastbus.io` | Reserved for broader integration configuration |
| `webSocketURL` | `URL?` | `nil` | Required for realtime WebSocket transport |
| `organizationID` | `String?` | `nil` | Used by `subscribeOrgChannel(_:)` |
| `persistDedupe` | `Bool` | `false` | Persists seen IDs and dedupe keys across launches |
| `fallbackEnabled` | `Bool` | `true` | Enables fallback-aware behavior |
| `diagnosticsEnabled` | `Bool` | `true` | Enables internal diagnostics capture |
| `reconnectPolicy` | `ToastKitReconnectPolicy` | default | Exponential reconnect settings |

### `ToastKitReconnectPolicy`

| Field | Type | Default |
| --- | --- | --- |
| `initialDelay` | `TimeInterval` | `0.5` |
| `multiplier` | `Double` | `2.0` |
| `jitter` | `Double` | `0.2` |
| `maxDelay` | `TimeInterval` | `30` |
| `maxAttempts` | `Int` | `5` |

### State accessors

These accessors are `@MainActor`:

```swift
let state = await MainActor.run { ToastKit.connectionState }
let topics = await MainActor.run { ToastKit.subscribedTopics }
let latest = await MainActor.run { ToastKit.latestToast }
let apnsEnv = await MainActor.run { ToastKit.apnsEnvironment }
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

`ToastKitConnectionState`

- `.idle`
- `.requestingSession`
- `.connecting`
- `.connected`
- `.disconnected`
- `.reconnecting`
- `.failed(String)`

`ToastKitDeliveryPath`

- `.websocket`
- `.apnsFallback`
- `.apnsFallbackThenReconnect`
- `.localMock`
- `.dropped`

### Local preview examples

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

## Operational Notes

### JWT handling

- Mint tokens server-side.
- Keep tokens short-lived.
- Scope topic claims narrowly.
- Rotate tokens through your existing auth refresh flow.
- Do not embed production bearer tokens in the application bundle.

### Multi-tenant isolation

- Prefer org-scoped topics such as `org:<orgId>:<channel>`.
- Configure `organizationID` when the app session is tenant-bound.
- Use `subscribeOrgChannel(_:)` to reduce client-side topic construction errors.

### Dedupe and collapse behavior

If your publisher sends stable IDs, dedupe keys, or collapse keys, the client can suppress duplicate toasts and replace in-flight toasts with newer state.

If dedupe memory should survive app restarts:

```swift
let options = ToastKitOptions(
    persistDedupe: true
)
```

### Debug logging

```swift
ToastKit.debug = true
```

Use this only in debug builds or controlled troubleshooting sessions.

## Troubleshooting

### `import ToastKit` fails

Check that your target dependency references the correct package identity and product:

```swift
.product(name: "ToastKit", package: "ToastKit-iOS")
```

### The package resolves but no toast appears

Check the common failure points:

1. `.toastKitOverlay()` is not mounted at the app root.
2. The app is not foregrounded.
3. No matching topic subscription exists.
4. Your `onToast` side effects are registered, but the overlay is missing.
5. Your token claims do not authorize the requested topics.

### APNs fallback does not occur

Check:

1. A device token was registered with `ToastKit`.
2. Fallback was not disabled with `setFallbackEnabled(false)`.
3. Your wider integration registered the APNs token wherever your backend expects it.

### Duplicate event side effects

Register `ToastKit.onToast` once. Re-registering it on repeated view appearances will stack handlers.

## Binary Distribution

This repository publishes a binary target backed by the GitHub Release asset:

```text
https://github.com/bairisland/ToastKit-iOS/releases/download/0.1.0/ToastKit.xcframework.zip
```

Current `0.1.0` checksum:

```text
0764e1a4c59ed23a8dfb0fcaed786548d15e152804812a06875d5c52165ce4ed
```

The public [Package.swift](/Users/bairisland/Developer/ToastKit-iOS/Package.swift) is intentionally binary-only and points at that asset.

## Versioning

- Current tag: `0.1.0`
- Distribution model: binary Swift Package via GitHub Release asset
- Recommended consumer dependency rule: `from: "0.1.0"`
