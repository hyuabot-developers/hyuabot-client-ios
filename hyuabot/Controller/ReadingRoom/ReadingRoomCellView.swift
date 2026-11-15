//
//  ReadingRoomCellView.swift
//  hyuabot
//

import Api
import FirebaseMessaging
import SnapKit
import UIKit

class ReadingRoomCellView: UITableViewCell {
    static let reuseIdentifier = "ReadingRoomCellView"

    private var item: ReadingRoomPageQuery.Data.ReadingRoom?
    private var fullName = ""
    private var occupiedRatio: CGFloat = 0
    private var showSubscribeToastMessage: (@MainActor @Sendable (String) -> Void)?
    private var showUnsubscribeToastMessage: (@MainActor @Sendable (String) -> Void)?

    private let cardView = UIView()
    private let separator = UIView()
    private let infoContainer = UIView()
    private let nameRow = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .firstBaseline
        $0.spacing = 6
    }
    private let leftStack = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 2
        $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }
    private let rightStack = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .center
        $0.spacing = 2
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    private let nameLabel = UILabel().then {
        $0.numberOfLines = 1
        $0.adjustsFontForContentSizeCategory = true
        $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }
    private let floorLabel = UILabel().then {
        $0.font = SettingsStyle.font(13)
        $0.textColor = SettingsStyle.Color.secondaryText
        $0.numberOfLines = 1
        $0.adjustsFontForContentSizeCategory = true
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    private let numberLabel = UILabel().then {
        $0.numberOfLines = 1
        $0.adjustsFontForContentSizeCategory = true
        $0.textAlignment = .right
    }
    let alarmButton = UIButton(type: .system).then { $0.backgroundColor = .clear }
    private let bellCircle = UIView()
    private let bellImageView = UIImageView().then {
        $0.isUserInteractionEnabled = false
        $0.contentMode = .center
    }
    private let barTrack = UIView()
    private let barFill = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupCardChrome()
        setupInfoLayout()
        setupBellLayout()
        setupBarLayout()
    }

    private func setupCardChrome() {
        cardView.backgroundColor = SettingsStyle.Color.card
        cardView.layer.cornerCurve = .continuous
        cardView.clipsToBounds = true
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(SettingsStyle.Metric.cardInset)
        }

        separator.backgroundColor = SettingsStyle.Color.separator
        cardView.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview()
            make.height.equalTo(1 / traitCollection.displayScale)
        }

    }

    private func setupInfoLayout() {
        cardView.addSubview(infoContainer)
        cardView.addSubview(alarmButton)
        infoContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0).priority(250)
            make.height.greaterThanOrEqualTo(44)
        }
        nameRow.addArrangedSubview(nameLabel)
        nameRow.addArrangedSubview(floorLabel)
        leftStack.addArrangedSubview(nameRow)
        rightStack.addArrangedSubview(numberLabel)
        infoContainer.addSubview(leftStack)
        infoContainer.addSubview(rightStack)
        leftStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(rightStack.snp.leading).offset(-12)
        }
        rightStack.snp.makeConstraints { make in
            make.trailing.equalTo(alarmButton.snp.leading).offset(-8)
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(40)
        }
    }

    private func setupBellLayout() {
        bellCircle.isUserInteractionEnabled = false
        bellCircle.layer.cornerRadius = 18
        alarmButton.addSubview(bellCircle)
        bellCircle.addSubview(bellImageView)
        bellCircle.snp.makeConstraints { make in
            make.size.equalTo(36)
            make.center.equalToSuperview()
        }
        bellImageView.snp.makeConstraints { make in make.center.equalToSuperview() }
        alarmButton.addTarget(self, action: #selector(alarmButtonTapped), for: .touchUpInside)
        alarmButton.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.width.equalTo(44).priority(.required)
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalTo(infoContainer.snp.centerY)
            make.top.greaterThanOrEqualTo(infoContainer.snp.top)
        }

    }

    private func setupBarLayout() {
        barTrack.backgroundColor = SettingsStyle.Color.segmentBackground
        barTrack.layer.cornerRadius = 3
        barTrack.clipsToBounds = true
        barFill.layer.cornerRadius = 3
        barTrack.addSubview(barFill)
        cardView.addSubview(barTrack)
        barTrack.snp.makeConstraints { make in
            make.top.equalTo(infoContainer.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(6)
            make.bottom.equalToSuperview().inset(14)
        }
    }

    func setupUI(
        item: ReadingRoomPageQuery.Data.ReadingRoom,
        isFirst: Bool,
        isLast: Bool,
        showSubscribeToastMessage: @escaping @MainActor @Sendable (String) -> Void,
        showUnsubscribeToastMessage: @escaping @MainActor @Sendable (String) -> Void
    ) {
        self.item = item
        self.showSubscribeToastMessage = showSubscribeToastMessage
        self.showUnsubscribeToastMessage = showUnsubscribeToastMessage
        fullName = String(localized: ReadingRoomDisplayLogic.localizationKey(for: item.seq))
        let displayName = ReadingRoomDisplayLogic.splitDisplayName(fullName)
        let level = ReadingRoomDisplayLogic.occupancyLevel(available: item.seats.available, active: item.seats.active)
        occupiedRatio = ReadingRoomDisplayLogic.occupiedRatio(available: item.seats.available, active: item.seats.active)

        nameLabel.attributedText = SettingsStyle.attributedText(
            displayName.name,
            font: SettingsStyle.font(16, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 22,
            lineBreakMode: .byTruncatingTail
        )
        floorLabel.text = displayName.floor
        floorLabel.isHidden = displayName.floor == nil
        numberLabel.attributedText = SettingsStyle.attributedText(
            "\(max(item.seats.available, 0))/\(item.seats.active)",
            font: SettingsStyle.monospacedDigitFont(19, bold: true),
            color: level.color,
            lineHeight: 24,
            alignment: .right
        )
        let seatsLeftText = String(
            format: String(localized: "reading_room.seats_left_format.%lld.%lld"),
            item.seats.active,
            max(item.seats.available, 0)
        )
        barFill.backgroundColor = level.color
        let corners = corners(isFirst: isFirst, isLast: isLast)
        cardView.layer.maskedCorners = corners
        cardView.layer.cornerRadius = (isFirst || isLast) ? SettingsStyle.Metric.cardRadius : 0
        separator.isHidden = isFirst

        let key = "reading_room_\(item.seq)"
        let subscribed = (UserDefaults.standard.stringArray(forKey: "readingRoomNotificationArray") ?? []).contains(key)
        updateBell(isOn: subscribed)
        infoContainer.isAccessibilityElement = true
        infoContainer.accessibilityLabel = "\(fullName), \(seatsLeftText)"
        isAccessibilityElement = false
        accessibilityElements = [infoContainer, alarmButton]
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        barFill.frame = CGRect(x: 0, y: 0, width: barTrack.bounds.width * occupiedRatio, height: barTrack.bounds.height)
    }

    private func updateBell(isOn: Bool) {
        let configuration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        bellImageView.image = UIImage(systemName: isOn ? "bell.fill" : "bell", withConfiguration: configuration)
        bellImageView.tintColor = isOn ? SettingsStyle.Color.link : SettingsStyle.Color.secondaryText
        bellCircle.backgroundColor = isOn ? SettingsStyle.Color.accentFill : SettingsStyle.Color.segmentBackground
        alarmButton.accessibilityIdentifier = "reading_room.bell"
        alarmButton.accessibilityLabel = String(
            format: String(localized: isOn
                ? "reading_room.bell.unsubscribe.accessibility.%@"
                : "reading_room.bell.subscribe.accessibility.%@"),
            fullName
        )
        alarmButton.accessibilityTraits = isOn ? [.button, .selected] : .button
    }

    private func corners(isFirst: Bool, isLast: Bool) -> CACornerMask {
        var mask: CACornerMask = []
        if isFirst { mask.formUnion([.layerMinXMinYCorner, .layerMaxXMinYCorner]) }
        if isLast { mask.formUnion([.layerMinXMaxYCorner, .layerMaxXMaxYCorner]) }
        return mask
    }

    @objc
    func alarmButtonTapped() {
        AnalyticsManager.logSelect(.readingRoomAlarmToggle, type: .toggle)
        guard let item,
              let showSubscribeToastMessage,
              let showUnsubscribeToastMessage else { return }
        let roomName = fullName
        let itemKey = "reading_room_\(item.seq)"
        let notifiedRooms = UserDefaults.standard.stringArray(forKey: "readingRoomNotificationArray") ?? []
        if notifiedRooms.contains(itemKey) {
            UserDefaults.standard.set(notifiedRooms.filter { $0 != itemKey }, forKey: "readingRoomNotificationArray")
            Messaging.messaging().unsubscribe(fromTopic: itemKey) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    showUnsubscribeToastMessage(roomName)
                }
            }
            updateBell(isOn: false)
        } else {
            UserDefaults.standard.set(notifiedRooms + [itemKey], forKey: "readingRoomNotificationArray")
            Messaging.messaging().subscribe(toTopic: itemKey) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    showSubscribeToastMessage(roomName)
                }
            }
            updateBell(isOn: true)
        }
    }
}
