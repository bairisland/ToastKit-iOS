import UIKit

/// Manages the display and dismissal of toast notifications.
///
/// Use the shared singleton to show toasts anywhere in your app:
/// ```swift
/// ToastManager.shared.show("Saved!", style: ToastStyle(type: .success))
/// ```
public final class ToastManager {

    // MARK: - Singleton

    /// The shared toast manager instance.
    public static let shared = ToastManager()

    private init() {}

    // MARK: - State

    private var currentToast: ToastView?
    private var dismissWorkItem: DispatchWorkItem?

    // MARK: - Public API

    /// Displays a toast message using the default style.
    ///
    /// - Parameter message: The text to display inside the toast.
    public func show(_ message: String) {
        show(message, style: ToastStyle())
    }

    /// Displays a toast message with the provided style.
    ///
    /// - Parameters:
    ///   - message: The text to display inside the toast.
    ///   - style: A `ToastStyle` that controls appearance and behavior.
    public func show(_ message: String, style: ToastStyle) {
        DispatchQueue.main.async { [weak self] in
            self?.presentToast(message: message, style: style)
        }
    }

    /// Immediately hides any visible toast, optionally animated.
    ///
    /// - Parameter animated: When `true` the toast fades out before removal. Defaults to `true`.
    public func dismiss(animated: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            self?.removeCurrentToast(animated: animated)
        }
    }

    // MARK: - Private helpers

    private func presentToast(message: String, style: ToastStyle) {
        // Remove any previously displayed toast immediately.
        removeCurrentToast(animated: false)

        guard let window = keyWindow() else { return }

        let toast = ToastView(message: message, style: style)
        window.addSubview(toast)

        // Horizontal constraints.
        NSLayoutConstraint.activate([
            toast.leadingAnchor.constraint(
                greaterThanOrEqualTo: window.leadingAnchor,
                constant: style.horizontalPadding
            ),
            toast.trailingAnchor.constraint(
                lessThanOrEqualTo: window.trailingAnchor,
                constant: -style.horizontalPadding
            ),
            toast.centerXAnchor.constraint(equalTo: window.centerXAnchor)
        ])

        // Vertical constraints based on the desired position.
        switch style.position {
        case .top:
            toast.topAnchor.constraint(
                equalTo: window.safeAreaLayoutGuide.topAnchor,
                constant: style.edgeOffset
            ).isActive = true

        case .center:
            toast.centerYAnchor.constraint(equalTo: window.centerYAnchor).isActive = true

        case .bottom:
            toast.bottomAnchor.constraint(
                equalTo: window.safeAreaLayoutGuide.bottomAnchor,
                constant: -style.edgeOffset
            ).isActive = true
        }

        currentToast = toast

        // Animate in.
        toast.alpha = 0
        UIView.animate(withDuration: 0.25) { toast.alpha = 1 }

        // Schedule automatic dismissal.
        let workItem = DispatchWorkItem { [weak self] in
            self?.removeCurrentToast(animated: true)
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + style.duration, execute: workItem)
    }

    private func removeCurrentToast(animated: Bool) {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil

        guard let toast = currentToast else { return }
        currentToast = nil

        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                toast.alpha = 0
            }, completion: { _ in
                toast.removeFromSuperview()
            })
        } else {
            toast.removeFromSuperview()
        }
    }

    private func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
