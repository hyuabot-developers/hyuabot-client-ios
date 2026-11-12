//
//  BusSectionCardView.swift
//  hyuabot
//

import SnapKit
import Then
import UIKit

struct BusSectionContent: Equatable {
    let routeNames: [String]
    let stopName: String
    let rows: [BusArrivalRowModel]
    let isLoading: Bool
}

final class BusSectionCardView: UIView {
    var onStopInfoTap: (() -> Void)?
    var onTimetableTap: (() -> Void)?
    var onLogTap: (() -> Void)?
    let stopInfoButton = UIButton(type: .system)
    let timetableButton = BusSectionFooterButton()
    let logButton = BusSectionFooterButton()
    private let header = UIView()
    private let stopLabel = UILabel()
    private let bodyStack = UIStackView()
    private var routeNames: [String] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = SettingsStyle.Color.card
        layer.cornerRadius = SettingsStyle.Metric.cardRadius
        clipsToBounds = true
        accessibilityIdentifier = "bus.section.card"
        bodyStack.axis = .vertical
        bodyStack.spacing = 0
        let footer = makeFooter()
        [header, bodyStack, footer].forEach(addSubview)
        header.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.height.equalTo(48) }
        bodyStack.snp.makeConstraints { $0.top.equalTo(header.snp.bottom); $0.leading.trailing.equalToSuperview() }
        footer.snp.makeConstraints {
            $0.top.equalTo(bodyStack.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.greaterThanOrEqualTo(44)
        }
        setupHeader()
        configureButtonTargets()
    }

    func configure(_ content: BusSectionContent) {
        routeNames = content.routeNames
        stopLabel.text = content.stopName
        stopLabel.attributedText = SettingsStyle.attributedText(
            content.stopName,
            font: SettingsStyle.font(15, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 20,
            lineBreakMode: .byTruncatingTail
        )
        stopInfoButton.accessibilityLabel = String(format: String(localized: "bus.realtime.stop_info.%@"), content.stopName)
        rebuildBody(content)
    }

    private func setupHeader() {
        stopLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stopLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        stopLabel.font = SettingsStyle.font(15, bold: true)
        stopLabel.adjustsFontForContentSizeCategory = true
        stopLabel.numberOfLines = 1
        stopLabel.lineBreakMode = .byTruncatingTail
        stopLabel.accessibilityTraits = .header
        let symbol = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        stopInfoButton.setImage(UIImage(systemName: "info.circle", withConfiguration: symbol), for: .normal)
        stopInfoButton.tintColor = SettingsStyle.Color.secondaryText
        stopInfoButton.accessibilityIdentifier = "bus.section.stopInfo"
        stopInfoButton.accessibilityLabel = String(format: String(localized: "bus.realtime.stop_info.%@"), "")
        [stopLabel, stopInfoButton].forEach(header.addSubview)
        stopLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(stopInfoButton.snp.leading).offset(-4)
        }
        stopInfoButton.snp.makeConstraints { $0.trailing.equalToSuperview().inset(4); $0.centerY.equalToSuperview(); $0.size.equalTo(44) }
        let line = UIView().then { $0.backgroundColor = SettingsStyle.Color.separator }
        header.addSubview(line)
        line.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }
    }

    private func rebuildBody(_ content: BusSectionContent) {
        bodyStack.arrangedSubviews.forEach { view in bodyStack.removeArrangedSubview(view); view.removeFromSuperview() }
        if content.isLoading { addSkeleton(); return }
        if content.rows.isEmpty { bodyStack.addArrangedSubview(emptyState()); return }
        for (index, model) in content.rows.enumerated() {
            let row = BusArrivalRowView()
            row.configure(model, showsRouteBadge: true, showsSeparator: index > 0)
            bodyStack.addArrangedSubview(row)
        }
    }

    private func addSkeleton() {
        let widths: [(CGFloat, CGFloat)] = [(0.42, 0.56), (0.36, 0.44), (0.48, 0.30)]
        for (index, width) in widths.enumerated() {
            let row = UIView()
            let first = skeletonBar(height: 16, radius: 8)
            let second = skeletonBar(height: 12, radius: 6)
            let left = UIStackView(arrangedSubviews: [first, second])
            left.axis = .vertical; left.spacing = 8
            let right = skeletonBar(height: 20, radius: 8)
            row.addSubview(left); row.addSubview(right)
            left.snp.makeConstraints {
                $0.leading.equalToSuperview().inset(16)
                $0.centerY.equalToSuperview()
                $0.width.equalTo(row.snp.width).multipliedBy(width.0)
            }
            right.snp.makeConstraints {
                $0.trailing.equalToSuperview().inset(16)
                $0.centerY.equalToSuperview()
                $0.size.equalTo(CGSize(width: 44, height: 20))
            }
            first.snp.makeConstraints { $0.height.equalTo(16); $0.width.equalTo(left.snp.width) }
            second.snp.makeConstraints { $0.height.equalTo(12); $0.width.equalTo(left.snp.width).multipliedBy(width.1) }
            row.snp.makeConstraints { $0.height.equalTo(64) }
            if index > 0 { addSeparator(to: row) }
            bodyStack.addArrangedSubview(row)
        }
    }

    private func skeletonBar(height: CGFloat, radius: CGFloat) -> UIView {
        UIView().then {
            $0.backgroundColor = SettingsStyle.Color.segmentBackground
            $0.layer.cornerRadius = radius
            $0.snp.makeConstraints { $0.height.equalTo(height) }
        }
    }

    private func addSeparator(to row: UIView) {
        let line = UIView().then { $0.backgroundColor = SettingsStyle.Color.separator }
        row.addSubview(line)
        line.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview().inset(16); $0.height.equalTo(1) }
    }

    private func emptyState() -> UIView {
        let symbol = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        let icon = UIImageView(image: UIImage(systemName: "bus", withConfiguration: symbol))
        icon.tintColor = SettingsStyle.Color.commuterFaint; icon.contentMode = .center
        icon.backgroundColor = SettingsStyle.Color.segmentBackground; icon.layer.cornerRadius = 22
        let title = emptyLabel("bus.realtime.empty.title", size: 15, bold: true, color: SettingsStyle.Color.text, lineHeight: 20)
        let detail = emptyLabel(
            "bus.realtime.empty.detail", size: 13, bold: false,
            color: SettingsStyle.Color.secondaryText, lineHeight: 18
        )
        let stack = UIStackView(arrangedSubviews: [icon, title, detail]); stack.axis = .vertical; stack.alignment = .center
        stack.setCustomSpacing(12, after: icon); stack.setCustomSpacing(4, after: title)
        let container = UIView(); container.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 24, left: 24, bottom: 28, right: 24)) }
        icon.snp.makeConstraints { $0.size.equalTo(44) }
        title.snp.makeConstraints { $0.leading.trailing.equalToSuperview() }
        detail.snp.makeConstraints { $0.leading.trailing.equalToSuperview() }
        container.layoutMargins = UIEdgeInsets(top: 24, left: 24, bottom: 28, right: 24)
        return container
    }

    private func emptyLabel(_ key: String, size: CGFloat, bold: Bool, color: UIColor, lineHeight: CGFloat) -> UILabel {
        let text = String(localized: String.LocalizationValue(key))
        let label = UILabel(); label.font = SettingsStyle.font(size, bold: bold); label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center; label.numberOfLines = 0
        label.attributedText = SettingsStyle.attributedText(
            text, font: SettingsStyle.font(size, bold: bold), color: color,
            lineHeight: lineHeight, alignment: .center
        )
        return label
    }

    private func makeFooter() -> UIView {
        let footer = UIView()
        let top = UIView().then { $0.backgroundColor = SettingsStyle.Color.separator }
        let vertical = UIView().then { $0.backgroundColor = SettingsStyle.Color.separator }
        timetableButton.accessibilityIdentifier = "bus.section.timetable"
        logButton.accessibilityIdentifier = "bus.section.log"
        setButton(timetableButton, title: String(localized: "bus.show.entire.timetable"), image: "clock")
        setButton(logButton, title: String(localized: "bus.show.departure.log"), image: "clock.arrow.circlepath")
        footer.addSubview(top); footer.addSubview(timetableButton); footer.addSubview(logButton); footer.addSubview(vertical)
        top.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.height.equalTo(1) }
        timetableButton.snp.makeConstraints {
            $0.leading.bottom.equalToSuperview()
            $0.top.equalTo(top.snp.bottom)
            $0.trailing.equalTo(footer.snp.centerX)
        }
        logButton.snp.makeConstraints {
            $0.trailing.bottom.equalToSuperview()
            $0.top.equalTo(top.snp.bottom)
            $0.leading.equalTo(footer.snp.centerX)
        }
        vertical.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(top.snp.bottom).offset(8)
            $0.bottom.equalToSuperview().inset(8)
            $0.width.equalTo(1)
        }
        return footer
    }

    private func setButton(_ button: UIButton, title: String, image: String) {
        let symbol = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        let icon = UIImageView(image: UIImage(systemName: image, withConfiguration: symbol))
        icon.tintColor = SettingsStyle.Color.link
        icon.contentMode = .center
        let label = UILabel()
        label.text = title
        label.font = SettingsStyle.font(13, bold: true)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = SettingsStyle.Color.link
        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 6
        stack.isUserInteractionEnabled = false
        stack.isAccessibilityElement = false
        button.accessibilityLabel = title
        button.addSubview(stack)
        stack.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview().inset(8)
            $0.bottom.lessThanOrEqualToSuperview().inset(8)
            $0.top.equalToSuperview().inset(8).priority(.high)
            $0.leading.greaterThanOrEqualToSuperview().inset(8)
            $0.trailing.lessThanOrEqualToSuperview().inset(8)
        }
        (button as? BusSectionFooterButton)?.contentView = stack
    }

    private func configureButtonTargets() {
        stopInfoButton.addTarget(self, action: #selector(stopInfoTapped), for: .touchUpInside)
        timetableButton.addTarget(self, action: #selector(timetableTapped), for: .touchUpInside)
        logButton.addTarget(self, action: #selector(logTapped), for: .touchUpInside)
    }

    @objc
    private func stopInfoTapped() {
        onStopInfoTap?()
    }

    @objc
    private func timetableTapped() {
        onTimetableTap?()
    }

    @objc
    private func logTapped() {
        onLogTap?()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// Footer action button whose overlaid icon/label stack dims while pressed.
final class BusSectionFooterButton: UIButton {
    weak var contentView: UIView?

    override var isHighlighted: Bool {
        didSet { contentView?.alpha = isHighlighted ? 0.4 : 1 }
    }
}
