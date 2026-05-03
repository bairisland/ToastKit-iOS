import UIKit

/// The on-screen position of a toast.
public enum ToastPosition {
    case top
    case center
    case bottom
}

/// The visual style preset of a toast.
public enum ToastType {
    case success
    case error
    case warning
    case info
    case custom(backgroundColor: UIColor, textColor: UIColor)

    var backgroundColor: UIColor {
        switch self {
        case .success:
            return UIColor(red: 0.18, green: 0.64, blue: 0.33, alpha: 1)
        case .error:
            return UIColor(red: 0.87, green: 0.20, blue: 0.20, alpha: 1)
        case .warning:
            return UIColor(red: 0.98, green: 0.60, blue: 0.10, alpha: 1)
        case .info:
            return UIColor(red: 0.13, green: 0.53, blue: 0.90, alpha: 1)
        case .custom(let bg, _):
            return bg
        }
    }

    var textColor: UIColor {
        switch self {
        case .success, .error, .warning, .info:
            return .white
        case .custom(_, let text):
            return text
        }
    }
}

/// Configuration options for a toast notification.
public struct ToastStyle {
    /// Duration in seconds the toast is visible on screen.
    public var duration: TimeInterval

    /// The position on screen where the toast appears.
    public var position: ToastPosition

    /// The visual type/preset of the toast.
    public var type: ToastType

    /// Font used for the toast message.
    public var font: UIFont

    /// Corner radius of the toast container view.
    public var cornerRadius: CGFloat

    /// Horizontal inset from the screen edges.
    public var horizontalPadding: CGFloat

    /// Vertical offset from the screen edge (top/bottom) or center.
    public var edgeOffset: CGFloat

    /// Creates a `ToastStyle` with the given options.
    public init(
        duration: TimeInterval = 2.5,
        position: ToastPosition = .bottom,
        type: ToastType = .info,
        font: UIFont = .systemFont(ofSize: 14, weight: .medium),
        cornerRadius: CGFloat = 10,
        horizontalPadding: CGFloat = 24,
        edgeOffset: CGFloat = 48
    ) {
        self.duration = duration
        self.position = position
        self.type = type
        self.font = font
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.edgeOffset = edgeOffset
    }
}
