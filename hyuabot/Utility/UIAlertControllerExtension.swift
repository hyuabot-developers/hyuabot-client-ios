import UIKit

extension UIAlertController {
    func applyGodoTypography(title: String?, message: String?) {
        if let title {
            setValue(
                NSAttributedString(
                    string: title,
                    attributes: [
                        .font: UIFont.godo(size: 17, weight: .bold),
                        .foregroundColor: UIColor.label
                    ]
                ),
                forKey: "attributedTitle"
            )
        }

        if let message {
            setValue(
                NSAttributedString(
                    string: message,
                    attributes: [
                        .font: UIFont.godo(size: 14, weight: .regular),
                        .foregroundColor: UIColor.secondaryLabel
                    ]
                ),
                forKey: "attributedMessage"
            )
        }
    }
}
