//
//  ContactListViews.swift
//  hyuabot
//

import SnapKit
import UIKit

final class ContactSectionHeaderView: UITableViewHeaderFooterView {
    private let departmentLabel = UILabel()
    private let countLabel = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        var background = UIBackgroundConfiguration.clear()
        background.backgroundColor = SettingsStyle.Color.background
        backgroundConfiguration = background
        configureLabels()
        configureLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(department: String, count: Int, isFirstSection: Bool = false) {
        departmentLabel.text = department
        let countText = String(format: String(localized: "contact.section.count.%lld"), count)
        countLabel.text = countText
        accessibilityLabel = "\(department), \(countText)"
        departmentLabel.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(isFirstSection ? 4 : 14)
        }
    }

    private func configureLabels() {
        departmentLabel.font = SettingsStyle.font(13, bold: true)
        departmentLabel.textColor = SettingsStyle.Color.secondaryText
        countLabel.font = SettingsStyle.font(13)
        countLabel.textColor = SettingsStyle.Color.secondaryText
        countLabel.textAlignment = .right
        isAccessibilityElement = true
        accessibilityTraits = .header
    }

    private func configureLayout() {
        contentView.addSubview(departmentLabel)
        contentView.addSubview(countLabel)
        departmentLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.top.equalToSuperview().offset(14)
            make.bottom.equalToSuperview().inset(8)
        }
        countLabel.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(departmentLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(24)
            make.centerY.equalTo(departmentLabel)
        }
    }
}

final class ContactLoadingView: UIView {
    private let banner = UIView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let messageLabel = UILabel()
    private let skeletonCard = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = SettingsStyle.Color.background
        configureBanner()
        configureSkeleton()
        configureLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setMessage(_ message: String) {
        messageLabel.text = message
        banner.accessibilityLabel = message
    }

    private func configureBanner() {
        banner.backgroundColor = SettingsStyle.Color.accentFill
        banner.layer.cornerRadius = 12
        banner.isAccessibilityElement = true
        banner.accessibilityTraits = .updatesFrequently
        spinner.color = SettingsStyle.Color.link
        spinner.startAnimating()
        messageLabel.font = SettingsStyle.font(14)
        messageLabel.textColor = SettingsStyle.Color.link
        messageLabel.numberOfLines = 0
        banner.addSubview(spinner)
        banner.addSubview(messageLabel)
        spinner.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
        }
        messageLabel.snp.makeConstraints { make in
            make.leading.equalTo(spinner.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(14)
            make.top.bottom.equalToSuperview().inset(12)
        }
    }

    private func configureSkeleton() {
        skeletonCard.backgroundColor = SettingsStyle.Color.card
        skeletonCard.layer.cornerRadius = 16
        skeletonCard.clipsToBounds = true
        skeletonCard.accessibilityElementsHidden = true
        for row in 0..<7 {
            addSkeletonRow(row)
        }
    }

    private func addSkeletonRow(_ index: Int) {
        let row = UIView()
        skeletonCard.addSubview(row)
        row.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(index * 64)
            make.height.equalTo(64)
        }
        if index > 0 {
            addSeparator(to: row)
        }
        addSkeletonContents(to: row, index: index)
    }

    private func addSeparator(to row: UIView) {
        let separator = UIView()
        separator.backgroundColor = SettingsStyle.Color.separator
        row.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
    }

    private func addSkeletonContents(to row: UIView, index: Int) {
        let circle = UIView()
        circle.backgroundColor = SettingsStyle.Color.segmentBackground
        circle.layer.cornerRadius = 20
        row.addSubview(circle)
        circle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        addSkeletonBars(to: row, beside: circle, index: index)
    }

    private func addSkeletonBars(to row: UIView, beside circle: UIView, index: Int) {
        let widths: [CGFloat] = [0.70, 0.55, 0.80, 0.60, 0.75, 0.50, 0.65]
        let column = UIView()
        row.addSubview(column)
        column.snp.makeConstraints { make in
            make.leading.equalTo(circle.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(48)
            make.centerY.equalToSuperview()
        }
        let first = makeBar(height: 14, radius: 7)
        let second = makeBar(height: 12, radius: 6)
        column.addSubview(first)
        column.addSubview(second)
        first.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(widths[index])
            make.height.equalTo(14)
        }
        second.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.40)
            make.height.equalTo(12)
            make.top.equalTo(first.snp.bottom).offset(8)
        }
    }

    private func makeBar(height: CGFloat, radius: CGFloat) -> UIView {
        let bar = UIView()
        bar.backgroundColor = SettingsStyle.Color.segmentBackground
        bar.layer.cornerRadius = radius
        bar.snp.makeConstraints { make in
            make.height.equalTo(height)
        }
        return bar
    }

    private func configureLayout() {
        let stack = UIStackView(arrangedSubviews: [banner, skeletonCard])
        stack.axis = .vertical
        stack.spacing = 12
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }
        skeletonCard.snp.makeConstraints { make in
            make.height.equalTo(448)
        }
    }
}

final class ContactSummaryView: UIView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        label.font = SettingsStyle.font(12.5)
        label.textColor = SettingsStyle.Color.secondaryText
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(_ text: String) {
        label.text = text
    }
}

final class ContactListFooterView: UIView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = SettingsStyle.font(12.5)
        label.textColor = SettingsStyle.Color.secondaryText
        label.numberOfLines = 0
        label.textAlignment = .center
        addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.bottom.equalToSuperview().inset(32)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        setVersion(nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setVersion(_ version: String?) {
        let hint = String(localized: "contact.footer.hint")
        if let version, !version.isEmpty {
            let updated = String(format: String(localized: "contact.footer.updated.%@"), version)
            label.text = "\(updated)\n\(hint)"
        } else {
            label.text = hint
        }
        label.attributedText = footerText(label.text ?? "")
    }

    private func footerText(_ text: String) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.minimumLineHeight = 18
        paragraph.maximumLineHeight = 18
        return NSAttributedString(string: text, attributes: [.paragraphStyle: paragraph])
    }
}

extension UITableView {
    func contactLayoutAccessoryViews() {
        guard bounds.width > 0 else { return }
        layoutAccessoryHeader()
        layoutAccessoryFooter()
    }

    private func layoutAccessoryHeader() {
        guard let header = tableHeaderView else { return }
        sizeAccessoryView(header) { tableHeaderView = $0 }
    }

    private func layoutAccessoryFooter() {
        guard let footer = tableFooterView else { return }
        sizeAccessoryView(footer) { tableFooterView = $0 }
    }

    private func sizeAccessoryView(_ view: UIView, assign: (UIView) -> Void) {
        let target = CGSize(width: bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let size = view.systemLayoutSizeFitting(
            target,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        guard view.frame.width != bounds.width || abs(view.frame.height - size.height) > 0.5 else { return }
        view.frame = CGRect(x: 0, y: 0, width: bounds.width, height: size.height)
        assign(view)
    }
}
