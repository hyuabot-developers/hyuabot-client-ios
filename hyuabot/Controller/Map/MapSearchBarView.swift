//
//  MapSearchBarView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class MapSearchBarView: UIView, UITextFieldDelegate {
    let textField = UITextField()
    var onTextChange: ((String) -> Void)?
    var onBeginEditing: (() -> Void)?
    var onBack: (() -> Void)?
    var onClear: (() -> Void)?

    private let contentStack = UIStackView()
    private let backButton = UIButton(type: .system)
    private let glassView = UIImageView()
    private let clearButton = UIButton(type: .system)
    private let clearCircle = UIView()
    private let clearIcon = UIImageView()
    private let trailingSpacer = UIView()
    private var leadingConstraint: Constraint?
    private var searching = false

    var text: String {
        get { textField.text ?? "" }
        set {
            textField.text = newValue
            updateTextVisibility()
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 48)
    }

    init() {
        super.init(frame: .zero)
        configureView()
        configureContent()
        configureActions()
        updateTextVisibility()
        updateLayerColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _: UITraitCollection) in
            view.updateLayerColors()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSearching(_ searching: Bool) {
        self.searching = searching
        backButton.isHidden = !searching
        glassView.isHidden = searching
        leadingConstraint?.update(inset: searching ? 2 : 14)
        layer.shadowOpacity = searching ? 0 : 0.12
        layer.borderWidth = searching ? 2 : 0
        updateLayerColors()
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        onBeginEditing?()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private func configureView() {
        backgroundColor = SettingsStyle.Color.card
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 5
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.borderWidth = 0
    }

    private func configureContent() {
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 8
        addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            leadingConstraint = make.leading.equalToSuperview().inset(14).constraint
            make.trailing.equalToSuperview().inset(2)
        }

        configureBackButton()
        configureGlassView()
        configureTextField()
        configureClearButton()
        trailingSpacer.snp.makeConstraints { $0.width.equalTo(4) }
        [backButton, glassView, textField, clearButton, trailingSpacer].forEach(contentStack.addArrangedSubview)
        contentStack.setCustomSpacing(0, after: backButton)
    }

    private func configureBackButton() {
        let image = UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold))
        backButton.setImage(image, for: .normal)
        backButton.tintColor = SettingsStyle.Color.text
        backButton.accessibilityLabel = String(localized: "map.search.close")
        backButton.isHidden = true
        backButton.snp.makeConstraints { $0.size.equalTo(44) }
    }

    private func configureGlassView() {
        let configuration = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        glassView.image = UIImage(systemName: "magnifyingglass", withConfiguration: configuration)
        glassView.tintColor = SettingsStyle.Color.secondaryText
        glassView.contentMode = .scaleAspectFit
        glassView.snp.makeConstraints { $0.size.equalTo(18) }
    }

    private func configureTextField() {
        textField.font = SettingsStyle.font(16)
        textField.adjustsFontForContentSizeCategory = true
        textField.textColor = SettingsStyle.Color.text
        textField.tintColor = SettingsStyle.Color.accent
        textField.attributedPlaceholder = NSAttributedString(
            string: String(localized: "map.building.search.placeholder"),
            attributes: [.foregroundColor: SettingsStyle.Color.secondaryText]
        )
        textField.returnKeyType = .search
        textField.autocorrectionType = .no
        textField.clearButtonMode = .never
        textField.accessibilityIdentifier = "map.search_text_field"
        textField.delegate = self
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }

    private func configureClearButton() {
        clearButton.accessibilityLabel = String(localized: "map.search.clear")
        clearButton.addSubview(clearCircle)
        clearCircle.backgroundColor = SettingsStyle.Color.segmentBackground
        clearCircle.layer.cornerRadius = 10
        clearCircle.layer.cornerCurve = .continuous
        clearCircle.addSubview(clearIcon)
        clearIcon.image = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .bold))
        clearIcon.tintColor = SettingsStyle.Color.secondaryText
        clearIcon.contentMode = .scaleAspectFit
        clearCircle.snp.makeConstraints { $0.size.equalTo(20); $0.center.equalToSuperview() }
        clearIcon.snp.makeConstraints { $0.size.equalTo(9); $0.center.equalToSuperview() }
        clearButton.snp.makeConstraints { $0.size.equalTo(44) }
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
    }

    private func configureActions() {
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    @objc
    private func textDidChange() {
        updateTextVisibility()
        onTextChange?(textField.text ?? "")
    }

    @objc
    private func backTapped() {
        onBack?()
    }

    @objc
    private func clearTapped() {
        textField.text = ""
        updateTextVisibility()
        onClear?()
    }

    private func updateTextVisibility() {
        let isEmpty = textField.text?.isEmpty ?? true
        clearButton.isHidden = isEmpty
        trailingSpacer.isHidden = !isEmpty
    }

    private func updateLayerColors() {
        layer.borderColor = SettingsStyle.Color.accent.resolvedColor(with: traitCollection).cgColor
    }
}
