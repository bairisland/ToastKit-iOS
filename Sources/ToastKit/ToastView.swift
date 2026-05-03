import UIKit

/// The visual toast notification view.
final class ToastView: UIView {

    // MARK: - Subviews

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Init

    init(message: String, style: ToastStyle) {
        super.init(frame: .zero)
        configure(message: message, style: style)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Configuration

    private func configure(message: String, style: ToastStyle) {
        backgroundColor = style.type.backgroundColor
        layer.cornerRadius = style.cornerRadius
        layer.masksToBounds = true
        translatesAutoresizingMaskIntoConstraints = false

        messageLabel.text = message
        messageLabel.font = style.font
        messageLabel.textColor = style.type.textColor

        addSubview(messageLabel)

        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }
}
