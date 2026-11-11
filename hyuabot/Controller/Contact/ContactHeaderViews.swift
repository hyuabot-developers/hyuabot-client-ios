//
//  ContactHeaderViews.swift
//  hyuabot
//

import SnapKit
import UIKit

final class ContactCampusPillView: HYUHeaderButton {
    init() {
        super.init(style: .capsule, symbolName: "graduationcap", title: nil)
        accessibilityIdentifier = "contact.campus_pill"
    }

    func setCampusName(_ name: String) {
        setTitle(name)
        accessibilityLabel = String(format: String(localized: "contact.campus.accessibility.%@"), name)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ContactSearchFieldView: UIView, UITextFieldDelegate {
    let textField = UITextField()
    var onTextChange: ((String) -> Void)?
    private let clearButton = UIButton(type: .system)

    var text: String { textField.text ?? "" }

    override init(frame: CGRect) {
        super.init(frame: frame)
        snp.makeConstraints { $0.height.equalTo(44) }
        backgroundColor = SettingsStyle.Color.card
        layer.cornerRadius = 12
        layer.borderWidth = 1
        let searchIcon = UIImageView(image: UIImage(
            systemName: "magnifyingglass",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 18)
        ))
        searchIcon.tintColor = SettingsStyle.Color.secondaryText
        addSubview(searchIcon)
        searchIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        addSubview(textField)
        textField.font = SettingsStyle.font(16)
        textField.textColor = SettingsStyle.Color.text
        textField.attributedPlaceholder = NSAttributedString(
            string: String(localized: "contact.search.placeholder"),
            attributes: [.foregroundColor: SettingsStyle.Color.secondaryText]
        )
        textField.clearButtonMode = .never
        textField.returnKeyType = .search
        textField.autocorrectionType = .no
        textField.adjustsFontForContentSizeCategory = true
        textField.accessibilityLabel = String(localized: "contact.search.accessibility")
        textField.accessibilityIdentifier = "contact.search_text_field"
        textField.delegate = self
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        addSubview(clearButton)
        textField.snp.makeConstraints { make in
            make.leading.equalTo(searchIcon.snp.trailing).offset(8)
            make.trailing.equalTo(clearButton.snp.leading)
            make.centerY.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(8)
        }
        let clearImage = UIImage(
            systemName: "xmark.circle.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 18)
        )
        clearButton.setImage(clearImage, for: .normal)
        clearButton.tintColor = SettingsStyle.Color.secondaryText
        clearButton.accessibilityLabel = String(localized: "contact.search.clear")
        clearButton.addTarget(self, action: #selector(clearText), for: .touchUpInside)
        clearButton.snp.makeConstraints { make in
            make.leading.equalTo(textField.snp.trailing)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        updateColors()
        updateSearchVisuals()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _) in view.updateColors() }
    }

    func setText(_ text: String) {
        textField.text = text
        updateSearchVisuals()
    }

    @objc
    private func textChanged() {
        updateSearchVisuals()
        onTextChange?(textField.text ?? "")
    }

    @objc
    private func clearText() {
        setText("")
        onTextChange?("")
    }

    private func updateSearchVisuals() {
        let hasText = !(textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        updateColors()
        clearButton.isHidden = !hasText
    }

    private func updateColors() {
        backgroundColor = SettingsStyle.Color.card
        let hasText = !(textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        layer.borderWidth = hasText ? 2 : 1
        let borderColor = hasText ? SettingsStyle.Color.accent : SettingsStyle.Color.separator
        layer.borderColor = borderColor.resolvedColor(with: traitCollection).cgColor
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class ContactFilterChip: UIControl {
    let department: String?
    private let capsule = UIView()
    private let titleLabel = UILabel()

    init(title: String, department: String?, identifier: String) {
        self.department = department
        super.init(frame: .zero)
        accessibilityLabel = title
        accessibilityIdentifier = identifier
        isAccessibilityElement = true
        snp.makeConstraints { $0.height.equalTo(44) }
        capsule.isUserInteractionEnabled = false
        capsule.layer.cornerRadius = 18
        capsule.layer.borderWidth = 1
        addSubview(capsule)
        capsule.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
        }
        titleLabel.text = title
        titleLabel.textAlignment = .center
        capsule.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
        setSelected(false)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _) in view.updateColors() }
    }

    func setSelected(_ selected: Bool) {
        isSelected = selected
        accessibilityTraits = selected ? [.button, .selected] : .button
        updateColors()
    }

    private func updateColors() {
        let selected = isSelected
        capsule.backgroundColor = selected ? SettingsStyle.Color.accent : SettingsStyle.Color.card
        let border = selected ? SettingsStyle.Color.accent : SettingsStyle.Color.separator
        capsule.layer.borderColor = border.resolvedColor(with: traitCollection).cgColor
        titleLabel.textColor = selected ? SettingsStyle.Color.onAccent : SettingsStyle.Color.text
        titleLabel.font = SettingsStyle.font(14, bold: selected)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ContactFilterChipBarView: UIView {
    var onSelect: ((String?) -> Void)?
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private var departments: [String] = []
    private var selectedDepartment: String?
    private var hasSelection = false
    private var chips: [ContactFilterChip] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        accessibilityContainerType = .semanticGroup
        accessibilityLabel = String(localized: "contact.filter.accessibility")
        addSubview(scrollView)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.addSubview(stack)
        stack.axis = .horizontal
        stack.spacing = 8
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(44)
        }
        stack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
            make.height.equalTo(scrollView.frameLayoutGuide)
        }
    }

    func setDepartments(_ departments: [String], selected: String?) {
        let changed = self.departments != departments
        self.departments = departments
        selectedDepartment = selected
        hasSelection = true
        if changed || chips.isEmpty {
            chips.forEach { $0.removeFromSuperview() }
            chips.removeAll()
            let items: [(String?, String)] = [(nil, String(localized: "contact.filter.all"))] + departments.map { ($0, $0) }
            for (index, item) in items.enumerated() {
                let identifier = index == 0 ? "contact.filter.all" : "contact.filter.\(index - 1)"
                let chip = ContactFilterChip(title: item.1, department: item.0, identifier: identifier)
                chip.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
                stack.addArrangedSubview(chip)
                chips.append(chip)
            }
        }
        updateSelection()
    }

    private func updateSelection() {
        for chip in chips {
            chip.setSelected(hasSelection ? chip.department == selectedDepartment : chip.department == nil)
        }
    }

    @objc
    private func chipTapped(_ sender: ContactFilterChip) {
        selectedDepartment = sender.department
        hasSelection = true
        updateSelection()
        scrollView.scrollRectToVisible(sender.convert(sender.bounds, to: scrollView), animated: true)
        onSelect?(sender.department)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
