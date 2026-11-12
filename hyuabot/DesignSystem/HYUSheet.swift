//
//  HYUSheet.swift
//  hyuabot
//

import UIKit

/// Shared presentation and title styling for bottom sheets.
enum HYUSheet {
    static func configure(
        _ controller: UIViewController,
        detents: [UISheetPresentationController.Detent],
        selected: UISheetPresentationController.Detent.Identifier? = nil
    ) {
        guard let sheet = controller.sheetPresentationController else { return }
        sheet.detents = detents
        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = HYUMetrics.Radius.sheet
        if let selected {
            sheet.selectedDetentIdentifier = selected
        }
    }

    static func applyBackground(to view: UIView) {
        view.backgroundColor = HYUColor.Sheet.background
    }

    static func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = SettingsStyle.Color.text
        label.accessibilityTraits = .header
        return label
    }

    static func setTitle(_ text: String, on label: UILabel) {
        label.attributedText = SettingsStyle.attributedText(
            text,
            font: SettingsStyle.font(20, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 26
        )
    }
}

final class HYUSheetCloseButton: UIControl {
    let circleView = UIView()
    private let iconView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = String(localized: "close")

        circleView.backgroundColor = SettingsStyle.Color.segmentBackground
        circleView.layer.cornerRadius = 15
        circleView.isUserInteractionEnabled = false
        addSubview(circleView)

        iconView.image = UIImage(
            systemName: "xmark",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        )
        iconView.tintColor = SettingsStyle.Color.secondaryText
        iconView.contentMode = .scaleAspectFit
        circleView.addSubview(iconView)

        circleView.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            circleView.widthAnchor.constraint(equalToConstant: 30),
            circleView.heightAnchor.constraint(equalToConstant: 30),
            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor)
        ])
    }

    convenience init() {
        self.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 44, height: 44)
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1 }
    }
}
