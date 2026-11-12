//
//  ShuttleExpandedTransferCellView.swift
//  hyuabot
//

import SnapKit
import UIKit

/// Inline panel shown under an expanded shuttle row: optional transfer info plus the
/// "알림 받기" and "모든 정류장" actions.
final class ShuttleExpandedTransferCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleExpandedTransferCellView"
    static let transferHeaderHeight: CGFloat = 34
    static let actionHeight: CGFloat = 44
    static let verticalGap: CGFloat = 10
    static let noteHeight: CGFloat = 40
    static let bottomPadding: CGFloat = 12

    private let cardView = UIView()
    private let panelView = UIView()
    private let groupStack = UIStackView()
    private let alarmButton = UIButton(type: .system)
    private let stopsButton = UIButton(type: .system)
    private var onAlarm: (() -> Void)?
    private var onStops: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        cardView.backgroundColor = SettingsStyle.Color.card
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(SettingsStyle.Metric.cardInset)
        }

        panelView.backgroundColor = SettingsStyle.Color.inset
        panelView.layer.cornerRadius = 12
        panelView.layer.cornerCurve = .continuous
        panelView.layer.masksToBounds = true
        groupStack.axis = .vertical
        panelView.addSubview(groupStack)
        groupStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        cardView.addSubview(panelView)

        configureActionButton(alarmButton, symbol: "bell", title: String(localized: "shuttle.expand.alarm"))
        configureActionButton(stopsButton, symbol: "list.bullet", title: String(localized: "shuttle.expand.all_stops"))
        alarmButton.accessibilityIdentifier = "shuttle.expand.alarm"
        stopsButton.accessibilityIdentifier = "shuttle.expand.all_stops"
        alarmButton.addTarget(self, action: #selector(alarmTapped), for: .touchUpInside)
        stopsButton.addTarget(self, action: #selector(stopsTapped), for: .touchUpInside)
        let actions = UIStackView(arrangedSubviews: [alarmButton, stopsButton])
        actions.axis = .horizontal
        actions.distribution = .fillEqually
        actions.spacing = 8
        cardView.addSubview(actions)
        actions.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(Self.actionHeight)
            make.bottom.equalToSuperview().inset(Self.bottomPadding)
        }
        panelView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(actions.snp.top).offset(-Self.verticalGap)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        clearContent()
    }

    func setCardBottomRounded(_ rounded: Bool) {
        cardView.layer.cornerRadius = rounded ? 16 : 0
        cardView.layer.cornerCurve = .continuous
        cardView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        cardView.clipsToBounds = rounded
    }

    static func preferredHeight(transferView: ShuttleTransferInfoView?) -> CGFloat {
        preferredHeight(transferViews: transferView.map { [$0] } ?? [])
    }

    static func preferredHeight(transferViews: [ShuttleTransferInfoView]) -> CGFloat {
        let actions = actionHeight + bottomPadding
        let visible = transferViews.filter { $0.preferredHeight > 0 }
        guard !visible.isEmpty else { return actions }
        let groups = visible.reduce(CGFloat(0)) { $0 + transferHeaderHeight + $1.preferredHeight + ($1.inlineNote == nil ? 0 : noteHeight) }
        return groups + verticalGap + actions
    }

    func setup(
        transferView: ShuttleTransferInfoView?,
        isAlarmActive: Bool,
        onAlarm: @escaping () -> Void,
        onStops: @escaping () -> Void
    ) {
        setup(transferViews: transferView.map { [$0] } ?? [], isAlarmActive: isAlarmActive, onAlarm: onAlarm, onStops: onStops)
    }

    func setup(
        transferViews: [ShuttleTransferInfoView],
        isAlarmActive: Bool,
        onAlarm: @escaping () -> Void,
        onStops: @escaping () -> Void
    ) {
        clearContent()
        self.onAlarm = onAlarm
        self.onStops = onStops
        updateAlarmButton(isActive: isAlarmActive)
        let visible = transferViews.filter { $0.preferredHeight > 0 }
        guard !visible.isEmpty else {
            panelView.isHidden = true
            return
        }
        panelView.isHidden = false
        for (index, transferView) in visible.enumerated() {
            groupStack.addArrangedSubview(makeGroup(transferView: transferView, showsTopDivider: index > 0))
        }
    }

    private func makeGroup(transferView: ShuttleTransferInfoView, showsTopDivider: Bool) -> UIView {
        let group = UIView()
        let header = UILabel()
        header.numberOfLines = 1
        header.lineBreakMode = .byTruncatingTail
        header.attributedText = Self.headerText(
            location: transferView.inlineLocationName,
            walkMinutes: transferView.inlineConnectorTravelMinutes
        )
        let separator = UIView()
        separator.backgroundColor = SettingsStyle.Color.separator
        group.addSubview(header)
        group.addSubview(separator)
        group.addSubview(transferView)
        header.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalTo(Self.transferHeaderHeight)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        separator.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        if let note = transferView.inlineNote {
            let noteLabel = UILabel()
            noteLabel.numberOfLines = 2
            noteLabel.font = SettingsStyle.font(12)
            noteLabel.textColor = SettingsStyle.Color.secondaryText
            noteLabel.text = note
            group.addSubview(noteLabel)
            noteLabel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(12)
                make.bottom.equalToSuperview()
                make.height.equalTo(Self.noteHeight)
            }
            transferView.snp.remakeConstraints { make in
                make.top.equalTo(separator.snp.bottom)
                make.leading.trailing.equalToSuperview()
                make.bottom.equalTo(noteLabel.snp.top)
            }
        } else {
            transferView.snp.remakeConstraints { make in
                make.top.equalTo(separator.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
        }
        if showsTopDivider {
            let divider = UIView()
            divider.backgroundColor = SettingsStyle.Color.separator
            group.addSubview(divider)
            divider.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(1 / UIScreen.main.scale)
            }
        }
        return group
    }

    private func clearContent() {
        for group in groupStack.arrangedSubviews {
            groupStack.removeArrangedSubview(group)
            group.removeFromSuperview()
        }
        onAlarm = nil
        onStops = nil
    }

    private func updateAlarmButton(isActive: Bool) {
        configureActionButton(
            alarmButton,
            symbol: isActive ? "bell.fill" : "bell",
            title: String(localized: isActive ? "shuttle.expand.alarm.on" : "shuttle.expand.alarm")
        )
    }

    private func configureActionButton(_ button: UIButton, symbol: String, title: String) {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(
            systemName: symbol,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        )
        configuration.imagePadding = 8
        configuration.baseForegroundColor = SettingsStyle.Color.link
        configuration.background.backgroundColor = SettingsStyle.Color.inset
        configuration.background.cornerRadius = 12
        var attributed = AttributedString(title)
        attributed.font = SettingsStyle.font(14, bold: true)
        configuration.attributedTitle = attributed
        button.configuration = configuration
    }

    private static func headerText(location: String?, walkMinutes: Int?) -> NSAttributedString {
        let result = NSMutableAttributedString()
        if let location {
            result.append(NSAttributedString(
                string: String(format: String(localized: "shuttle.expand.alight.%@"), locale: Locale.current, location),
                attributes: [.font: SettingsStyle.font(13, bold: true), .foregroundColor: SettingsStyle.Color.text]
            ))
        }
        if let walkMinutes {
            let walk = String(format: String(localized: "shuttle.expand.walk.%lld"), locale: Locale.current, walkMinutes)
            result.append(NSAttributedString(
                string: (result.length > 0 ? " · " : "") + walk,
                attributes: [.font: SettingsStyle.font(12), .foregroundColor: SettingsStyle.Color.secondaryText]
            ))
        }
        return result
    }

    @objc
    private func alarmTapped() {
        onAlarm?()
    }

    @objc
    private func stopsTapped() {
        onStops?()
    }
}
