//
//  BirthdayVC.swift
//  hyuabot
//

import SnapKit
import UIKit

final class BirthdayVC: UIViewController, UIGestureRecognizerDelegate {
    private enum Metric {
        static let cardSideMargin: CGFloat = 24
        static let iconSize: CGFloat = 56
        static let iconGlyph: CGFloat = 28
        static let bodyMaxHeight: CGFloat = 360
        static let buttonHeight: CGFloat = 50
        static let buttonRadius: CGFloat = 12
        static let checkboxSize: CGFloat = 20
        static let checkboxRadius: CGFloat = 6
        static let checkboxRowHeight: CGFloat = 44
    }

    let currentYear = Calendar.current.component(.year, from: Date())
    var backgroundClicked: (() -> Void)?

    private let card = UIView()
    private let bodyScrollView = UIScrollView()
    private let checkboxBox = UIView()
    private let checkmark = UIImageView()
    private let checkboxButton = UIButton(type: .custom)
    private var hideKey: String { "hideBirthdayPopup\(currentYear)" }
    private var isChecked = false

    /// Presents the birthday dialog full screen so the scrim also covers the tab bar.
    /// - Parameter ignoreHideFlag: `true` skips the "do not show this year" check (debug entry point).
    static func present(from presenter: UIViewController, ignoreHideFlag: Bool = false) {
        let year = Calendar.current.component(.year, from: Date())
        if !ignoreHideFlag, UserDefaults.standard.bool(forKey: "hideBirthdayPopup\(year)") { return }
        let birthdayVC = BirthdayVC()
        birthdayVC.modalPresentationStyle = .overFullScreen
        birthdayVC.modalTransitionStyle = .crossDissolve
        presenter.present(birthdayVC, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SettingsStyle.Color.dialogScrim
        isChecked = UserDefaults.standard.bool(forKey: hideKey)
        let tap = UITapGestureRecognizer(target: self, action: #selector(onBackgroundClicked))
        tap.delegate = self
        view.addGestureRecognizer(tap)
        buildCard()
        updateCheckbox()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.birthday)
    }

    private func buildCard() {
        card.backgroundColor = SettingsStyle.Color.sheet
        card.layer.cornerRadius = HYUMetrics.Radius.card
        card.layer.cornerCurve = HYUMetrics.cornerCurve
        card.layer.shadowColor = UIColor(red: 17 / 255, green: 24 / 255, blue: 39 / 255, alpha: 1).cgColor
        card.layer.shadowOpacity = 0.18
        card.layer.shadowRadius = 16
        card.layer.shadowOffset = CGSize(width: 0, height: 12)
        card.accessibilityViewIsModal = true
        card.accessibilityIdentifier = "birthday.dialog"
        view.addSubview(card)
        card.snp.makeConstraints {
            $0.centerY.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview().inset(Metric.cardSideMargin)
            $0.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide).offset(HYUMetrics.Space.large)
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-HYUMetrics.Space.large)
        }

        let icon = SettingsIconTileView(
            symbolName: "birthday.cake.fill",
            color: SettingsStyle.Color.accentFill,
            size: Metric.iconSize,
            radius: Metric.iconSize / 2,
            glyphPointSize: Metric.iconGlyph,
            glyphColor: SettingsStyle.Color.accent
        )
        let title = UILabel()
        title.numberOfLines = 0
        title.attributedText = SettingsStyle.attributedText(
            String(localized: "birthday.title"),
            font: SettingsStyle.font(20, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 26,
            alignment: .center
        )
        title.accessibilityTraits = .header
        let actions = makeActions()
        buildBody()

        let stack = UIStackView(arrangedSubviews: [icon, title, bodyScrollView, actions])
        stack.axis = .vertical
        stack.alignment = .center
        stack.setCustomSpacing(HYUMetrics.Space.large, after: icon)
        stack.setCustomSpacing(HYUMetrics.Space.large, after: title)
        stack.setCustomSpacing(HYUMetrics.Space.xl + HYUMetrics.Space.xs, after: bodyScrollView)
        card.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalToSuperview().inset(HYUMetrics.Space.xxl)
            $0.leading.trailing.equalToSuperview().inset(HYUMetrics.Space.xl + HYUMetrics.Space.xs)
            $0.bottom.equalToSuperview().inset(HYUMetrics.Space.xl)
        }
        for view in [title, bodyScrollView, actions] {
            view.snp.makeConstraints { $0.leading.trailing.equalToSuperview() }
        }
    }

    private func buildBody() {
        let paragraphs: [(String, UIColor)] = [
            (String(localized: "birthday.body.today"), SettingsStyle.Color.text),
            (String(localized: "birthday.body.thanks"), SettingsStyle.Color.secondaryText),
            (String(format: String(localized: "birthday.body.wish.%@"), String(currentYear)), SettingsStyle.Color.secondaryText)
        ]
        let body = UIStackView(arrangedSubviews: paragraphs.map { text, color in
            let label = UILabel()
            label.numberOfLines = 0
            label.lineBreakStrategy = .hangulWordPriority
            label.attributedText = SettingsStyle.attributedText(
                text,
                font: SettingsStyle.font(15),
                color: color,
                lineHeight: 24,
                alignment: .center
            )
            return label
        })
        body.axis = .vertical
        body.spacing = HYUMetrics.Space.medium
        bodyScrollView.addSubview(body)
        bodyScrollView.showsVerticalScrollIndicator = false
        body.snp.makeConstraints {
            $0.edges.equalTo(bodyScrollView.contentLayoutGuide)
            $0.width.equalTo(bodyScrollView.frameLayoutGuide)
        }
        bodyScrollView.snp.makeConstraints {
            $0.height.equalTo(body).priority(.high)
            $0.height.lessThanOrEqualTo(Metric.bodyMaxHeight)
        }
    }

    private func makeActions() -> UIView {
        var closeConfig = UIButton.Configuration.filled()
        closeConfig.baseBackgroundColor = SettingsStyle.Color.accent
        closeConfig.baseForegroundColor = SettingsStyle.Color.onAccent
        closeConfig.cornerStyle = .fixed
        closeConfig.background.cornerRadius = Metric.buttonRadius
        closeConfig.attributedTitle = AttributedString(
            String(localized: "close"),
            attributes: AttributeContainer([.font: SettingsStyle.font(16, bold: true)])
        )
        let close = UIButton(configuration: closeConfig)
        close.accessibilityIdentifier = "birthday.close"
        close.addTarget(self, action: #selector(onBackgroundClicked), for: .touchUpInside)
        close.snp.makeConstraints { $0.height.equalTo(Metric.buttonHeight) }

        let actions = UIStackView(arrangedSubviews: [close, makeCheckboxRow()])
        actions.axis = .vertical
        actions.spacing = HYUMetrics.Space.small
        return actions
    }

    private func makeCheckboxRow() -> UIView {
        checkboxBox.layer.cornerRadius = Metric.checkboxRadius
        checkboxBox.layer.cornerCurve = HYUMetrics.cornerCurve
        checkboxBox.isUserInteractionEnabled = false
        checkmark.image = UIImage(
            systemName: "checkmark",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .heavy)
        )
        checkmark.tintColor = SettingsStyle.Color.onAccent
        checkmark.contentMode = .center
        checkboxBox.addSubview(checkmark)
        checkmark.snp.makeConstraints { $0.edges.equalToSuperview() }
        checkboxBox.snp.makeConstraints { $0.size.equalTo(Metric.checkboxSize) }

        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = SettingsStyle.attributedText(
            String(localized: "birthday.dont.show.again"),
            font: SettingsStyle.font(14),
            color: SettingsStyle.Color.secondaryText,
            lineHeight: 20
        )
        let content = UIStackView(arrangedSubviews: [checkboxBox, label])
        content.spacing = HYUMetrics.Space.small
        content.alignment = .center
        content.isUserInteractionEnabled = false

        let row = UIView()
        row.addSubview(checkboxButton)
        row.addSubview(content)
        checkboxButton.accessibilityLabel = String(localized: "birthday.dont.show.again")
        checkboxButton.accessibilityIdentifier = "birthday.do_not_show"
        checkboxButton.addTarget(self, action: #selector(onDoNotShowCheckboxTapped), for: .touchUpInside)
        checkboxButton.snp.makeConstraints { $0.edges.equalToSuperview() }
        content.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
            $0.top.bottom.equalToSuperview().inset(HYUMetrics.Space.small)
        }
        row.snp.makeConstraints { $0.height.greaterThanOrEqualTo(Metric.checkboxRowHeight) }
        return row
    }

    private func updateCheckbox() {
        checkmark.isHidden = !isChecked
        checkboxBox.backgroundColor = isChecked ? SettingsStyle.Color.accent : .clear
        checkboxBox.layer.borderWidth = isChecked ? 0 : 1.5
        checkboxBox.layer.borderColor = SettingsStyle.Color.checkboxBorder.resolvedColor(with: traitCollection).cgColor
        checkboxButton.accessibilityTraits = isChecked ? [.button, .selected] : .button
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateCheckbox()
    }

    @objc
    private func onBackgroundClicked() {
        AnalyticsManager.logSelect(.birthdayDismiss)
        dismiss(animated: true)
        backgroundClicked?()
    }

    @objc
    private func onDoNotShowCheckboxTapped() {
        AnalyticsManager.logSelect(.birthdayDoNotShow)
        isChecked.toggle()
        UserDefaults.standard.set(isChecked, forKey: hideKey)
        updateCheckbox()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !card.bounds.contains(touch.location(in: card))
    }
}
