# ToastKit-iOS

A lightweight, fully-customisable Toast notification library for iOS, distributed as a Swift Package.

---

## Requirements

| Platform | Minimum version |
|----------|-----------------|
| iOS      | 13.0            |
| Swift    | 5.7             |

---

## Installation

### Swift Package Manager (recommended)

#### Xcode

1. Open your project in Xcode.
2. Go to **File → Add Package Dependencies…**
3. Enter the repository URL:
   ```
   https://github.com/bairisland/ToastKit-iOS
   ```
4. Choose the version rule that suits you (e.g. **Up to Next Major**) and click **Add Package**.
5. Add **ToastKit** to the target you want to use it in.

#### Package.swift

Add the following dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/bairisland/ToastKit-iOS", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["ToastKit"]
    )
]
```

---

## Usage

Import the library in any Swift file:

```swift
import ToastKit
```

### Show a toast with the default style

```swift
ToastManager.shared.show("Hello, World!")
```

### Show a success toast at the top of the screen

```swift
let style = ToastStyle(
    duration: 3,
    position: .top,
    type: .success
)
ToastManager.shared.show("Saved successfully!", style: style)
```

### Show an error toast

```swift
let style = ToastStyle(type: .error)
ToastManager.shared.show("Something went wrong.", style: style)
```

### Show a fully custom toast

```swift
let style = ToastStyle(
    duration: 4,
    position: .center,
    type: .custom(backgroundColor: .systemPurple, textColor: .white),
    font: .boldSystemFont(ofSize: 16),
    cornerRadius: 16,
    horizontalPadding: 32,
    edgeOffset: 60
)
ToastManager.shared.show("Custom toast 🎉", style: style)
```

### Dismiss programmatically

```swift
ToastManager.shared.dismiss()          // animated (default)
ToastManager.shared.dismiss(animated: false)  // instant
```

---

## API Reference

### `ToastManager`

| Method | Description |
|--------|-------------|
| `show(_ message:)` | Shows a toast with the default style. |
| `show(_ message:style:)` | Shows a toast with a custom `ToastStyle`. |
| `dismiss(animated:)` | Dismisses the current toast immediately. |

### `ToastStyle`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `duration` | `TimeInterval` | `2.5` | How long the toast is visible. |
| `position` | `ToastPosition` | `.bottom` | Where on screen the toast appears. |
| `type` | `ToastType` | `.info` | Visual style preset. |
| `font` | `UIFont` | System 14pt medium | Label font. |
| `cornerRadius` | `CGFloat` | `10` | Corner radius of the toast view. |
| `horizontalPadding` | `CGFloat` | `24` | Minimum horizontal margin. |
| `edgeOffset` | `CGFloat` | `48` | Offset from the safe area edge. |

### `ToastPosition`

- `.top` – Near the top of the safe area.
- `.center` – Vertically centred.
- `.bottom` – Near the bottom of the safe area *(default)*.

### `ToastType`

- `.success` – Green background, white text.
- `.error` – Red background, white text.
- `.warning` – Orange background, white text.
- `.info` – Blue background, white text *(default)*.
- `.custom(backgroundColor:textColor:)` – Fully custom colours.

---

## License

ToastKit-iOS is available under the MIT license.
