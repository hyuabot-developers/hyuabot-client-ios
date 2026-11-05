//
//  OpenSourceLicenseDetailVC.swift
//  hyuabot
//

import SafariServices
import SnapKit
import UIKit

final class OpenSourceLicenseDetailVC: UIViewController, SettingsStyledScreen {
    private let license: OpenSourceLicenseEntry
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    init(license: OpenSourceLicenseEntry) {
        self.license = license
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = license.name
        navigationItem.backButtonTitle = String(localized: "licenses.back")
        SettingsNavigationStyle.apply(to: self)
        view.backgroundColor = SettingsStyle.Color.background
        configureLayout()
        contentStack.addArrangedSubview(makeHeaderSection())
        contentStack.addArrangedSubview(makeLicenseSection())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SettingsNavigationStyle.screenWillAppear(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SettingsNavigationStyle.screenWillDisappear(self)
    }

    private func configureLayout() {
        scrollView.accessibilityIdentifier = "setting.open_source_licenses.detail"
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        contentStack.axis = .vertical
        contentStack.spacing = 8
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(12)
            make.leading.trailing.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
            make.bottom.equalTo(scrollView.contentLayoutGuide).inset(48)
        }
    }

    private func makeHeaderSection() -> UIView {
        let card = UIView()
        card.backgroundColor = SettingsStyle.Color.card
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 6
        titleStack.alignment = .leading
        stack.addArrangedSubview(titleStack)
        let name = UILabel()
        name.text = license.name
        name.font = SettingsStyle.font(22, bold: true)
        name.textColor = SettingsStyle.Color.text
        name.numberOfLines = 0
        titleStack.addArrangedSubview(name)
        name.snp.makeConstraints { $0.width.equalToSuperview() }
        titleStack.addArrangedSubview(makeChips())
        if let sourceURL = URL(string: license.source) {
            stack.addArrangedSubview(makeRepositoryButton(sourceURL: sourceURL))
        }
        return padded(card, horizontal: 16)
    }

    private func makeChips() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6
        row.alignment = .leading
        let kind = OpenSourceLicenseKind.classify(license.licenseText)
        row.addArrangedSubview(makeChip(
            kind.badgeTitle,
            background: SettingsStyle.Color.accentFill,
            foreground: SettingsStyle.Color.link,
            bold: true
        ))
        row.addArrangedSubview(makeChip(
            "v\(license.version)",
            background: SettingsStyle.Color.segmentBackground,
            foreground: SettingsStyle.Color.text
        ))
        return row
    }

    private func makeChip(_ text: String, background: UIColor, foreground: UIColor,
                          bold: Bool = false) -> UIView {
        let container = UIView()
        container.backgroundColor = background
        container.layer.cornerRadius = 8
        container.layer.cornerCurve = .continuous
        let label = UILabel()
        label.text = text
        label.font = SettingsStyle.font(13, bold: bold)
        label.textColor = foreground
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
            make.top.bottom.equalToSuperview().inset(4)
            make.height.greaterThanOrEqualTo(18)
        }
        container.snp.makeConstraints { $0.height.greaterThanOrEqualTo(26) }
        return container
    }

    private func makeRepositoryButton(sourceURL: URL) -> UIControl {
        let control = UIControl()
        control.backgroundColor = SettingsStyle.Color.segmentBackground
        control.layer.cornerRadius = 12
        control.layer.cornerCurve = .continuous
        control.accessibilityTraits = .link
        let label = UILabel()
        label.text = OpenSourceLicenseCatalog.displaySource(license.source)
        label.font = SettingsStyle.font(14)
        label.textColor = SettingsStyle.Color.text
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let icon = UIImageView(image: UIImage(systemName: "arrow.up.right"))
        icon.tintColor = SettingsStyle.Color.secondaryText
        let row = UIStackView(arrangedSubviews: [label, icon])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        control.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)) }
        control.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }
        control.addAction(UIAction { [weak self] _ in
            let safari = SFSafariViewController(url: sourceURL)
            safari.dismissButtonStyle = .close
            self?.present(safari, animated: true)
        }, for: .touchUpInside)
        return control
    }

    private func makeLicenseSection() -> UIView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.text = license.licenseText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: "\n")
        let font = UIFontMetrics(forTextStyle: .footnote).scaledFont(
            for: .monospacedSystemFont(ofSize: 12, weight: .regular)
        )
        textView.font = font
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = 19
        paragraph.lineHeightMultiple = 19 / 12
        textView.typingAttributes = [.paragraphStyle: paragraph]
        textView.textColor = SettingsStyle.Color.body
        textView.adjustsFontForContentSizeCategory = true
        let attributed = NSMutableAttributedString(string: textView.text, attributes: [
            .font: font,
            .foregroundColor: SettingsStyle.Color.body,
            .paragraphStyle: paragraph
        ])
        textView.attributedText = attributed
        let card = UIView()
        card.backgroundColor = SettingsStyle.Color.card
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        card.addSubview(textView)
        textView.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        let section = SettingsSectionView(
            header: String(localized: "licenses.full_text"),
            content: card
        )
        return padded(section, horizontal: 0)
    }

    private func padded(_ view: UIView, horizontal: CGFloat) -> UIView {
        let container = UIView()
        container.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(
                top: 0,
                left: horizontal,
                bottom: 0,
                right: horizontal
            ))
        }
        return container
    }
}
