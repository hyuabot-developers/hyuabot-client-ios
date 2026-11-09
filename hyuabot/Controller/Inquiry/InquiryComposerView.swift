//
//  InquiryComposerView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class InquiryComposerView: UIView, UITextFieldDelegate {
    var onSend: ((String) -> Void)?
    var onSelectChip: ((InquiryQuickReply) -> Void)?
    var onBeginEditing: (() -> Void)?

    private let chipsScroll = UIScrollView()
    private let chipsStack = UIStackView()
    private var chipButtons: [InquiryQuickReply: UIButton] = [:]
    private let inputField = InquiryComposerTextField()
    private let sendButton = UIButton(type: .custom)

    init() {
        super.init(frame: .zero)
        backgroundColor = SettingsStyle.Color.card
        let separator = UIView()
        separator.backgroundColor = SettingsStyle.Color.separator
        addSubview(separator)
        separator.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.height.equalTo(1) }

        chipsScroll.showsHorizontalScrollIndicator = false
        chipsScroll.alwaysBounceHorizontal = true
        chipsStack.axis = .horizontal
        chipsStack.spacing = 8
        chipsScroll.addSubview(chipsStack)
        chipsStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 0, right: 16))
            $0.height.equalTo(44)
        }
        for reply in InquiryQuickReply.allCases {
            let button = UIButton(configuration: .plain())
            button.accessibilityIdentifier = "inquiry.chip.\(reply.rawValue)"
            button.addAction(UIAction { [weak self] _ in self?.onSelectChip?(reply) }, for: .touchUpInside)
            chipsStack.addArrangedSubview(button)
            chipButtons[reply] = button
        }
        chipsScroll.snp.makeConstraints { $0.height.equalTo(52) }

        inputField.font = SettingsStyle.font(15)
        inputField.textColor = SettingsStyle.Color.text
        inputField.tintColor = SettingsStyle.Color.accent
        inputField.backgroundColor = SettingsStyle.Color.segmentBackground
        inputField.layer.cornerRadius = 22
        inputField.returnKeyType = .send
        inputField.accessibilityIdentifier = "inquiry.input"
        inputField.accessibilityLabel = String(localized: "inquiry.input.placeholder")
        inputField.attributedPlaceholder = NSAttributedString(
            string: String(localized: "inquiry.input.placeholder"),
            attributes: [.foregroundColor: SettingsStyle.Color.inquiryPlaceholder]
        )
        inputField.delegate = self
        inputField.addTarget(self, action: #selector(draftChanged), for: .editingChanged)
        let arrow = UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .bold))
        sendButton.setImage(arrow, for: .normal)
        sendButton.layer.cornerRadius = 22
        sendButton.layer.cornerCurve = .continuous
        sendButton.clipsToBounds = true
        sendButton.accessibilityLabel = String(localized: "inquiry.send")
        sendButton.accessibilityIdentifier = "inquiry.send_button"
        sendButton.addTarget(self, action: #selector(sendDraft), for: .touchUpInside)

        let inputRow = UIStackView(arrangedSubviews: [inputField, sendButton])
        inputRow.axis = .horizontal
        inputRow.spacing = 8
        inputRow.alignment = .center
        inputRow.isLayoutMarginsRelativeArrangement = true
        inputRow.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 12)
        constrainInputRow(inputRow)
        let stack = UIStackView(arrangedSubviews: [chipsScroll, inputRow])
        stack.axis = .vertical
        stack.spacing = 0
        addSubview(stack)
        stack.snp.makeConstraints { $0.top.equalTo(separator.snp.bottom); $0.leading.trailing.bottom.equalToSuperview() }
        setChips(visible: true, selected: nil)
        updateSendButton()
        observeTraits()
    }

    private func constrainInputRow(_ inputRow: UIStackView) {
        inputRow.snp.makeConstraints { $0.height.equalTo(60) }
        inputField.snp.makeConstraints { $0.height.equalTo(44) }
        sendButton.snp.makeConstraints { $0.width.height.equalTo(44) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setChips(visible: Bool, selected: InquiryQuickReply?) {
        chipsScroll.isHidden = !visible
        for (reply, button) in chipButtons {
            var config = UIButton.Configuration.plain()
            config.cornerStyle = .capsule
            config.title = reply.chipTitle
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            let isSelected = reply == selected
            var attributes = AttributeContainer()
            attributes.font = SettingsStyle.font(14, bold: isSelected)
            config.attributedTitle = AttributedString(reply.chipTitle, attributes: attributes)
            config.baseForegroundColor = isSelected ? SettingsStyle.Color.accent : SettingsStyle.Color.text
            config.background.backgroundColor = isSelected ? SettingsStyle.Color.accentFill : SettingsStyle.Color.card
            button.configuration = config
            button.layer.cornerRadius = 22
            button.layer.borderWidth = 1
            let border = isSelected ? SettingsStyle.Color.accentFill : SettingsStyle.Color.separator
            button.layer.borderColor = border.resolvedColor(with: traitCollection).cgColor
            button.accessibilityTraits = isSelected ? [.button, .selected] : .button
            button.snp.remakeConstraints { $0.height.equalTo(44) }
        }
    }

    func clearDraft() {
        inputField.text = ""
        updateSendButton()
    }

    func textFieldDidBeginEditing(_ textField: UITextField) { onBeginEditing?() }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendDraft()
        return true
    }

    @objc
    private func draftChanged() { updateSendButton() }

    @objc
    private func sendDraft() {
        let text = (inputField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        onSend?(text)
    }

    private func updateSendButton() {
        let hasText = !(inputField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        sendButton.isEnabled = hasText
        sendButton.backgroundColor = hasText ? SettingsStyle.Color.accent : SettingsStyle.Color.switchOff
        sendButton.tintColor = hasText ? SettingsStyle.Color.onAccent : SettingsStyle.Color.card
    }

    private func refreshChipBorders() {
        for button in chipButtons.values {
            let selected = button.accessibilityTraits.contains(.selected)
            let border = selected ? SettingsStyle.Color.accentFill : SettingsStyle.Color.separator
            button.layer.borderColor = border.resolvedColor(with: traitCollection).cgColor
        }
    }

    private func observeTraits() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: InquiryComposerView, _: UITraitCollection) in
            view.refreshChipBorders()
        }
    }
}

private final class InquiryComposerTextField: UITextField {
    override func textRect(forBounds bounds: CGRect) -> CGRect { bounds.insetBy(dx: 16, dy: 0) }
    override func editingRect(forBounds bounds: CGRect) -> CGRect { bounds.insetBy(dx: 16, dy: 0) }
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect { bounds.insetBy(dx: 16, dy: 0) }
}
