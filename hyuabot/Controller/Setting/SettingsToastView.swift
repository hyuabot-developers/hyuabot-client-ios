//
//  SettingsToastView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class SettingsToastView: UIView {
    static let displayDuration: TimeInterval = 2.4
    private var dismissal: DispatchWorkItem?
    private let iconLayer = CAShapeLayer()
    private let messageLabel = UILabel()
    private var message: String {
        didSet {
            messageLabel.text = message
            accessibilityLabel = message
        }
    }

    private init(message: String) {
        self.message = message
        super.init(frame: .zero)
        backgroundColor = SettingsStyle.Color.toastBackground
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowRadius = 12
        isUserInteractionEnabled = false
        isAccessibilityElement = true
        accessibilityLabel = message
        accessibilityTraits = .staticText
        accessibilityIdentifier = "setting.toast"
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 10
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        }
        let icon = UIView()
        stack.addArrangedSubview(icon)
        icon.snp.makeConstraints { $0.size.equalTo(18) }
        icon.layer.addSublayer(iconLayer)
        messageLabel.font = SettingsStyle.font(14)
        messageLabel.textColor = SettingsStyle.Color.toastText
        messageLabel.numberOfLines = 0
        messageLabel.adjustsFontForContentSizeCategory = true
        let paragraph = NSMutableParagraphStyle()
        let lineHeight = UIFontMetrics(forTextStyle: .body).scaledValue(for: 20)
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        messageLabel.attributedText = NSAttributedString(string: message, attributes: [
            .font: messageLabel.font as Any,
            .foregroundColor: SettingsStyle.Color.toastText,
            .paragraphStyle: paragraph
        ])
        stack.addArrangedSubview(messageLabel)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.updateIconColor()
        }
        updateIconColor()
    }

    static func show(message: String, in container: UIView) {
        let toast = container.subviews.compactMap { $0 as? SettingsToastView }.first ?? SettingsToastView(message: message)
        toast.message = message
        toast.messageLabel.attributedText = NSAttributedString(string: message, attributes: [
            .font: toast.messageLabel.font as Any,
            .foregroundColor: SettingsStyle.Color.toastText,
            .paragraphStyle: toast.messageLabel.attributedText?.attribute(.paragraphStyle, at: 0, effectiveRange: nil) ?? NSParagraphStyle()
        ])
        if toast.superview == nil {
            container.addSubview(toast)
            toast.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                make.top.equalTo(container.safeAreaLayoutGuide.snp.top).offset(4)
            }
        }
        UIAccessibility.post(notification: .announcement, argument: message)
        toast.dismissal?.cancel()
        let work = DispatchWorkItem { [weak toast] in toast?.removeFromSuperview() }
        toast.dismissal = work
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration, execute: work)
    }

    static func dismiss(in container: UIView) {
        container.subviews.compactMap { $0 as? SettingsToastView }.forEach {
            $0.dismissal?.cancel()
            $0.removeFromSuperview()
        }
    }

    private func updateIconColor() {
        let scale = 18.0 / 24.0
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 5 * scale, y: 12 * scale))
        path.addLine(to: CGPoint(x: 10 * scale, y: 17 * scale))
        path.addLine(to: CGPoint(x: 19 * scale, y: 7 * scale))
        iconLayer.frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        iconLayer.path = path.cgPath
        iconLayer.fillColor = nil
        iconLayer.strokeColor = SettingsStyle.Color.toastText.resolvedColor(with: traitCollection).cgColor
        iconLayer.lineWidth = 2.2 * scale
        iconLayer.lineCap = .round
        iconLayer.lineJoin = .round
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
