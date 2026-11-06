//
//  SearchEmptyCellView.swift
//  hyuabot
//

import SnapKit
import UIKit

class SearchEmptyCellView: UITableViewCell {
    static let reuseIdentifier = "SearchEmptyCellView"
    private let stateView = StateView(sourceScreen: .map)
    private let mapEmptyView = UIView()
    private let emptyStack = UIStackView()
    private let iconCircle = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private var iconName = "magnifyingglass"

    func configure(_ content: StateContent) {
        stateView.isHidden = false
        mapEmptyView.isHidden = true
        stateView.apply(content)
    }

    func configure(keyword: String) {
        let title = String(localized: "map.search.empty.title")
        let message = String(format: String(localized: "map.search.empty.message"), keyword)
        configureMapEmpty(icon: "magnifyingglass", title: title, message: message)
        stateView.apply(.empty(title: title, message: message, symbolName: "magnifyingglass", action: nil))
    }

    func configureFailure() {
        let title = String(localized: "map.search.error.title")
        let message = String(localized: "map.search.error.message")
        configureMapEmpty(icon: "wifi.slash", title: title, message: message)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(stateView)
        stateView.snp.makeConstraints { $0.edges.equalToSuperview() }
        stateView.apply(.empty(message: String(localized: "map.search.empty")))

        mapEmptyView.isHidden = true
        contentView.addSubview(mapEmptyView)
        mapEmptyView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(46)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.lessThanOrEqualToSuperview().inset(24)
        }
        emptyStack.axis = .vertical
        emptyStack.alignment = .center
        emptyStack.spacing = 12
        mapEmptyView.addSubview(emptyStack)
        emptyStack.snp.makeConstraints { $0.edges.equalToSuperview() }

        iconCircle.backgroundColor = SettingsStyle.Color.segmentBackground
        iconCircle.layer.cornerRadius = 28
        iconCircle.layer.cornerCurve = .continuous
        iconCircle.addSubview(iconView)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = SettingsStyle.Color.accent
        iconView.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(24) }
        iconCircle.snp.makeConstraints { $0.size.equalTo(56) }
        emptyStack.addArrangedSubview(iconCircle)

        [titleLabel, messageLabel].forEach { $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 0; $0.textAlignment = .center }
        titleLabel.font = SettingsStyle.font(17, bold: true)
        titleLabel.textColor = SettingsStyle.Color.text
        messageLabel.font = SettingsStyle.font(14)
        messageLabel.textColor = SettingsStyle.Color.secondaryText
        let textStack = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        textStack.axis = .vertical
        textStack.alignment = .center
        textStack.spacing = 4
        emptyStack.addArrangedSubview(textStack)
        textStack.snp.makeConstraints { $0.leading.trailing.equalToSuperview() }
    }

    private func configureMapEmpty(icon: String, title: String, message: String) {
        iconName = icon
        iconView.image = UIImage(systemName: iconName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .medium))
        titleLabel.attributedText = attributed(title, font: titleLabel.font, lineSpacing: 0)
        messageLabel.attributedText = attributed(message, font: messageLabel.font, lineSpacing: 3)
        mapEmptyView.isAccessibilityElement = true
        mapEmptyView.accessibilityLabel = "\(title), \(message)"
        mapEmptyView.isHidden = false
        stateView.isHidden = true
    }

    private func attributed(_ text: String, font: UIFont, lineSpacing: CGFloat) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = lineSpacing
        return NSAttributedString(string: text, attributes: [.font: font, .paragraphStyle: paragraph])
    }
}
