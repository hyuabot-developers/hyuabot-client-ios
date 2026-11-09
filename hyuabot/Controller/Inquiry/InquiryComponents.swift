//
//  InquiryComponents.swift
//  hyuabot
//

import SnapKit
import UIKit

/// Message bubble geometry and reusable answer components for inquiry screens.
enum InquiryBubbleSide { case leading, trailing }

enum InquiryBubblePath {
    static func path(in rect: CGRect, side: InquiryBubbleSide, radius: CGFloat, tailRadius: CGFloat? = nil) -> UIBezierPath {
        let limit = min(rect.width, rect.height) / 2
        let corner = min(max(0, radius), limit)
        let tail = min(max(0, tailRadius ?? 6), limit)
        let tl = corner, tr = corner
        let bl = side == .leading ? tail : corner
        let br = side == .trailing ? tail : corner
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(
            withCenter: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
            radius: tr,
            startAngle: -.pi / 2,
            endAngle: 0,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(
            withCenter: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
            radius: br,
            startAngle: 0,
            endAngle: .pi / 2,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(
            withCenter: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
            radius: bl,
            startAngle: .pi / 2,
            endAngle: .pi,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(
            withCenter: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
            radius: tl,
            startAngle: .pi,
            endAngle: .pi * 1.5,
            clockwise: true
        )
        path.close()
        return path
    }
}

final class InquiryBubbleBackgroundView: UIView {
    private let shape = CAShapeLayer()
    let side: InquiryBubbleSide
    let fillColor: UIColor

    init(side: InquiryBubbleSide, fillColor: UIColor) {
        self.side = side
        self.fillColor = fillColor
        super.init(frame: .zero)
        backgroundColor = .clear
        layer.insertSublayer(shape, at: 0)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: InquiryBubbleBackgroundView, _: UITraitCollection) in
            view.setNeedsLayout()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        shape.frame = bounds
        shape.path = InquiryBubblePath.path(in: bounds, side: side, radius: 18).cgPath
        shape.fillColor = fillColor.resolvedColor(with: traitCollection).cgColor
    }
}

final class InquiryTextBubbleView: UIView {
    private let background: InquiryBubbleBackgroundView
    let label = UILabel()
    private let textColor: UIColor

    init(side: InquiryBubbleSide, fillColor: UIColor, textColor: UIColor, maxWidth: CGFloat) {
        background = InquiryBubbleBackgroundView(side: side, fillColor: fillColor)
        self.textColor = textColor
        super.init(frame: .zero)
        addSubview(background)
        addSubview(label)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        background.snp.makeConstraints { $0.edges.equalToSuperview() }
        label.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(10)
            $0.left.right.equalToSuperview().inset(14)
            $0.width.lessThanOrEqualTo(maxWidth - 28)
        }
        snp.makeConstraints { $0.width.lessThanOrEqualTo(maxWidth) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setText(_ text: String) {
        label.attributedText = SettingsStyle.attributedText(text, font: SettingsStyle.font(15), color: textColor, lineHeight: 22)
    }
}

final class InquiryAnswerCardView: UIView {
    private let stack = UIStackView()

    init(title: String, detail: String) {
        super.init(frame: .zero)
        let background = InquiryBubbleBackgroundView(side: .leading, fillColor: SettingsStyle.Color.card)
        addSubview(background)
        background.snp.makeConstraints { $0.edges.equalToSuperview() }
        stack.axis = .vertical
        stack.spacing = 12
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        let heading = UIStackView()
        heading.axis = .vertical
        heading.spacing = 4
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.attributedText = SettingsStyle.attributedText(
            title,
            font: SettingsStyle.font(16, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 22
        )
        let detailLabel = UILabel()
        detailLabel.numberOfLines = 0
        detailLabel.attributedText = SettingsStyle.attributedText(
            detail,
            font: SettingsStyle.font(14),
            color: SettingsStyle.Color.secondaryText,
            lineHeight: 21
        )
        heading.addArrangedSubview(titleLabel)
        heading.addArrangedSubview(detailLabel)
        stack.addArrangedSubview(heading)
        snp.makeConstraints {
            $0.width.equalTo(310).priority(UILayoutPriority(999))
            $0.width.lessThanOrEqualTo(310)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func addContent(_ view: UIView) { stack.addArrangedSubview(view) }
}

enum InquiryUI {
    static func captionRow(_ text: String, side: InquiryBubbleSide) -> UIView {
        let container = UIView()
        let label = UILabel()
        label.font = SettingsStyle.font(12)
        label.textColor = SettingsStyle.Color.secondaryText
        label.text = text
        container.addSubview(label)
        label.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            if side == .leading {
                $0.left.equalToSuperview().offset(4)
                $0.right.lessThanOrEqualToSuperview()
            } else {
                $0.right.equalToSuperview().offset(-4)
                $0.left.greaterThanOrEqualToSuperview()
            }
        }
        return container
    }

    static func column(side: InquiryBubbleSide, views: [UIView]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = side == .leading ? .leading : .trailing
        return stack
    }

    static func actionButton(title: String, systemImage: String, filled: Bool) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: systemImage)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold))
        config.imagePadding = 6
        config.imagePlacement = .leading
        config.baseForegroundColor = filled ? SettingsStyle.Color.onAccent : SettingsStyle.Color.accent
        config.background.cornerRadius = 12
        config.background.backgroundColor = filled ? SettingsStyle.Color.accent : SettingsStyle.Color.accentFill
        var attributes = AttributeContainer()
        attributes.font = SettingsStyle.font(15, bold: true)
        config.attributedTitle = AttributedString(title, attributes: attributes)
        let button = UIButton(configuration: config)
        button.snp.makeConstraints { $0.height.equalTo(44) }
        return button
    }

    static func actionRow(_ buttons: [UIButton]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        return stack
    }

    static func infoGrid(_ rows: [InquiryInfoRow]) -> UIStackView {
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 6
        for item in rows {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 12
            row.alignment = .firstBaseline
            let label = UILabel()
            label.attributedText = SettingsStyle.attributedText(
                item.label,
                font: SettingsStyle.font(14),
                color: SettingsStyle.Color.secondaryText,
                lineHeight: 20
            )
            label.snp.makeConstraints { $0.width.equalTo(40) }
            let value = UILabel()
            value.numberOfLines = 0
            value.attributedText = SettingsStyle.attributedText(
                item.value,
                font: SettingsStyle.monospacedDigitFont(14),
                color: SettingsStyle.Color.text,
                lineHeight: 20
            )
            row.addArrangedSubview(label)
            row.addArrangedSubview(value)
            grid.addArrangedSubview(row)
        }
        return grid
    }
}

struct InquiryInfoRow {
    let label: String
    let value: String
    init(_ label: String, _ value: String) { self.label = label; self.value = value }
}
