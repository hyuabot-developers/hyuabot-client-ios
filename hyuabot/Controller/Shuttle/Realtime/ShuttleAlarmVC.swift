//
//  ShuttleAlarmVC.swift
//  hyuabot
//

// swiftlint:disable file_length

import CoreLocation
import SnapKit
import Then
import UIKit
import UserNotifications

// swiftlint:disable:next type_body_length
class ShuttleAlarmVC: UIViewController {
    private let context: ShuttleAlarmContext
    private var selectedDestinationIndex = 0
    private var isBoardingAlarmActive = false
    private var isAlightingAlarmActive = false
    private var isAlarmRequestInFlight = false
    private let locationPermissionRequester = ShuttleAlarmLocationPermissionRequester()
    var shareJourney: ((String) -> Void)?

    private let titleLabel = UILabel().then { $0.text = String(localized: "shuttle.alarm.sheet.title") }
    private lazy var sheetView = HYUSheetView(title: titleLabel.text ?? "")
    private let boardingTitleLabel = UILabel().then {
        $0.attributedText = SettingsStyle.attributedText(
            String(localized: "shuttle.alarm.boarding"),
            font: SettingsStyle.font(15, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 20
        )
    }

    private let boardingDescriptionLabel = UILabel().then {
        $0.font = SettingsStyle.font(13)
        $0.textColor = SettingsStyle.Color.secondaryText
        $0.numberOfLines = 0
    }

    private let departureTimeLabel = UILabel()
    private let remainingTimeLabel = UILabel()
    private let boardingSwitch = UISwitch().then {
        $0.onTintColor = SettingsStyle.Color.accent
        $0.accessibilityIdentifier = "shuttle.alarm.boarding_switch"
    }

    private var radioRows: [ShuttleAlarmStopRadioRow] = []
    private let permissionBanner = UIView()
    private let shareButton = UIButton(type: .system)
    private let startButton = UIButton(type: .system)

    init(context: ShuttleAlarmContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var sheetHeight: CGFloat {
        sheetView.contentHeight
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        reloadAlarmState()
    }

    private func setupUI() {
        view.backgroundColor = SettingsStyle.Color.busSheetBackground
        view.addSubview(sheetView)
        sheetView.snp.makeConstraints { $0.edges.equalToSuperview() }
        configurePermissionBanner()
        sheetView.contentStack.addArrangedSubview(permissionBanner)
        sheetView.contentStack.setCustomSpacing(12, after: permissionBanner)

        let badge = BusRouteBadgeView(size: .shuttle)
        badge.configure(text: context.routeDisplayName, fill: BusRouteBadgeView.shuttleFill(for: shuttleChipKind))
        badge.setContentHuggingPriority(.required, for: .horizontal)
        let head = UIStackView(arrangedSubviews: [badge, departureTimeLabel, UIView(), remainingTimeLabel])
        head.alignment = .center
        head.spacing = 8
        head.isLayoutMarginsRelativeArrangement = true
        head.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        head.snp.makeConstraints { $0.height.greaterThanOrEqualTo(56) }
        let departs = String(localized: "shuttle.alarm.departs")
        departureTimeLabel.text = "\(context.boardingStop.name) \(timeText(context.departureTime)) \(departs)"
        departureTimeLabel.font = SettingsStyle.monospacedDigitFont(17, bold: true)
        departureTimeLabel.textColor = SettingsStyle.Color.text
        departureTimeLabel.lineBreakMode = .byTruncatingTail
        departureTimeLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        remainingTimeLabel.text = remainingText()
        remainingTimeLabel.font = SettingsStyle.monospacedDigitFont(15, bold: true)
        remainingTimeLabel.textColor = SettingsStyle.Color.link
        remainingTimeLabel.setContentHuggingPriority(.required, for: .horizontal)
        remainingTimeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let boardingRow = switchRow(title: boardingTitleLabel, subtitle: boardingDescriptionLabel, toggle: boardingSwitch, minHeight: 64)
        let boardingCard = HYUSheetView.card()
        boardingCard.addArrangedSubview(head)
        boardingCard.addArrangedSubview(HYUSheetView.separator())
        boardingCard.addArrangedSubview(boardingRow)
        boardingDescriptionLabel.text = String(localized: "shuttle.alarm.boarding.hint")
        boardingSwitch.addTarget(self, action: #selector(boardingSwitchChanged(_:)), for: .valueChanged)
        sheetView.contentStack.addArrangedSubview(boardingCard)

        let destinations = context.destinationStops
        if !destinations.isEmpty {
            sheetView.contentStack.addArrangedSubview(HYUSheetView.sectionHeader(String(localized: "shuttle.alarm.alighting.header")))
            let radioCard = HYUSheetView.card()
            for (index, stop) in destinations.enumerated() {
                if index > 0 {
                    radioCard.addArrangedSubview(HYUSheetView.separator())
                }
                let row = ShuttleAlarmStopRadioRow(name: stop.name, time: timeText(stop.time))
                row.addTarget(self, action: #selector(radioRowTapped(_:)), for: .touchUpInside)
                row.tag = index
                radioRows.append(row)
                radioCard.addArrangedSubview(row)
            }
            sheetView.contentStack.addArrangedSubview(radioCard)
            let footnote = HYUSheetView.footnote(String(localized: "shuttle.alarm.alighting.footnote"))
            sheetView.contentStack.addArrangedSubview(footnote)
            sheetView.contentStack.setCustomSpacing(16, after: footnote)
            applyRadioSelection()
            configureActionButtons()
        }
    }

    private var shuttleChipKind: ShuttleDisplayLogic.RouteChipKind {
        context.chipKind
    }

    private func remainingText() -> String {
        let minutes = ShuttleDisplayLogic.minutesUntil(context.departureTime, now: .now)
        if minutes <= 0 {
            return String(localized: "shuttle.alarm.remaining.now")
        }
        return String(format: String(localized: "shuttle.alarm.remaining.format.%lld"), minutes)
    }

    private func configurePermissionBanner() {
        permissionBanner.isHidden = true
        permissionBanner.backgroundColor = SettingsStyle.Color.warnFill
        permissionBanner.layer.cornerRadius = 12
        permissionBanner.layer.cornerCurve = .continuous
        let icon = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        icon.tintColor = SettingsStyle.Color.warnText
        icon.setContentHuggingPriority(.required, for: .horizontal)
        let label = UILabel().then {
            $0.attributedText = SettingsStyle.attributedText(
                String(localized: "shuttle.alarm.permission.off"),
                font: SettingsStyle.font(13, bold: true),
                color: SettingsStyle.Color.warnText,
                lineHeight: 18
            )
            $0.numberOfLines = 0
        }
        var configuration = UIButton.Configuration.plain()
        configuration.background.backgroundColor = SettingsStyle.Color.sheet
        configuration.background.cornerRadius = 16
        configuration.baseForegroundColor = SettingsStyle.Color.link
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        configuration.attributedTitle = AttributedString(
            String(localized: "shuttle.alarm.permission.open"),
            attributes: AttributeContainer([.font: SettingsStyle.font(13, bold: true)])
        )
        let openButton = UIButton(configuration: configuration)
        openButton.addAction(UIAction { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }, for: .touchUpInside)
        openButton.setContentHuggingPriority(.required, for: .horizontal)
        let row = UIStackView(arrangedSubviews: [icon, label, openButton])
        row.alignment = .center
        row.spacing = 10
        permissionBanner.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 8)) }
        openButton.snp.makeConstraints { $0.height.equalTo(32) }
        permissionBanner.snp.makeConstraints { $0.height.greaterThanOrEqualTo(48) }
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            let denied = settings.authorizationStatus == .denied
            DispatchQueue.main.async {
                self?.permissionBanner.isHidden = !denied
                self?.sheetView.contentStack.setCustomSpacing(denied ? 12 : 0, after: self?.permissionBanner ?? UIView())
            }
        }
    }

    private func configureActionButtons() {
        let share = HYUSheetView.actionButton(
            title: String(localized: "shuttle.share.journey.short"),
            systemImage: "square.and.arrow.up",
            identifier: "shuttle.alarm.share"
        )
        shareButton.configuration = share.configuration
        shareButton.accessibilityIdentifier = share.accessibilityIdentifier
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        let start = HYUSheetView.primaryButton(title: "", identifier: "shuttle.alarm.alighting_start")
        startButton.configuration = start.configuration
        startButton.accessibilityIdentifier = start.accessibilityIdentifier
        startButton.addTarget(self, action: #selector(alightingButtonTapped), for: .touchUpInside)
        let buttons = UIStackView(arrangedSubviews: [shareButton, startButton])
        buttons.spacing = 8
        buttons.distribution = .fill
        sheetView.contentStack.addArrangedSubview(buttons)
        shareButton.snp.makeConstraints { $0.height.equalTo(48) }
        startButton.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.width.equalTo(shareButton).multipliedBy(2).offset(-8)
        }
        updateStartButtonTitle()
    }

    private func updateStartButtonTitle() {
        guard var configuration = startButton.configuration else { return }
        let key = isAlightingAlarmActive ? "shuttle.alarm.alighting.stop" : "shuttle.alarm.alighting.start"
        configuration.attributedTitle = AttributedString(
            String(localized: String.LocalizationValue(key)),
            attributes: AttributeContainer([.font: SettingsStyle.font(15, bold: true)])
        )
        startButton.configuration = configuration
    }

    private func applyRadioSelection() {
        for (index, row) in radioRows.enumerated() {
            row.setSelected(index == selectedDestinationIndex)
        }
    }

    @objc
    private func radioRowTapped(_ sender: UIControl) {
        selectedDestinationIndex = sender.tag
        applyRadioSelection()
    }

    private func switchRow(title: UILabel, subtitle: UILabel?, toggle: UISwitch, minHeight: CGFloat) -> UIView {
        let row = UIView()
        let labels = UIStackView(arrangedSubviews: subtitle.map { [title, $0] } ?? [title])
        labels.axis = .vertical
        labels.spacing = 2
        row.addSubview(labels)
        row.addSubview(toggle)
        labels.snp
            .makeConstraints {
                $0.leading.equalToSuperview().offset(16); $0.centerY.equalToSuperview(); $0.trailing.lessThanOrEqualTo(toggle.snp.leading)
                    .offset(-12)
            }
        toggle.snp.makeConstraints { $0.trailing.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }
        row.snp.makeConstraints { $0.height.greaterThanOrEqualTo(minHeight) }
        return row
    }

    private func reloadAlarmState() {
        ShuttleAlarmNotificationService.shared.activeStates(for: context.key) { [weak self] boarding, alighting in
            guard let self else { return }
            isBoardingAlarmActive = boarding
            isAlightingAlarmActive = alighting
            syncSwitches()
        }
    }

    private func syncSwitches() {
        boardingSwitch.setOn(isBoardingAlarmActive, animated: true)
        boardingSwitch.isEnabled = !isAlarmRequestInFlight
        startButton.isEnabled = !isAlarmRequestInFlight
        updateStartButtonTitle()
    }

    private func finishAlarmRequest() {
        isAlarmRequestInFlight = false
        syncSwitches()
        reloadAlarmState()
    }

    @objc
    private func boardingSwitchChanged(_ sender: UISwitch) {
        sender.setOn(isBoardingAlarmActive, animated: false)
        guard !isAlarmRequestInFlight else { return }
        isAlarmRequestInFlight = true
        syncSwitches()
        if isBoardingAlarmActive {
            ShuttleAlarmNotificationService.shared.cancelBoardingAlarm(for: context.key)
            finishAlarmRequest()
            dismiss(animated: true)
            return
        }
        requestNotificationAndLocationAuthorization { [weak self] granted in
            guard let self else { return }
            if granted {
                ShuttleAlarmNotificationService.shared.scheduleBoardingAlarm(context: context)
                NotificationCenter.default.post(name: .shuttleBoardingAlarmStateDidChange, object: nil)
                finishAlarmRequest()
                dismiss(animated: true)
            } else {
                finishAlarmRequest()
                presentPermissionAlert()
            }
        }
    }

    @objc
    private func alightingButtonTapped() {
        guard !isAlarmRequestInFlight else { return }
        isAlarmRequestInFlight = true
        syncSwitches()
        if isAlightingAlarmActive {
            ShuttleAlarmNotificationService.shared.cancelAlightingAlarm(for: context.key)
            finishAlarmRequest()
            dismiss(animated: true)
            return
        }
        guard context.destinationStops.indices.contains(selectedDestinationIndex) else { finishAlarmRequest(); return }
        let destination = context.destinationStops[selectedDestinationIndex]
        requestNotificationAndLocationAuthorization { [weak self] granted in
            guard let self else { return }
            if granted {
                ShuttleAlarmNotificationService.shared.scheduleAlightingAlarm(context: context, destination: destination)
                finishAlarmRequest()
                dismiss(animated: true)
            } else {
                finishAlarmRequest()
                presentPermissionAlert()
            }
        }
    }

    @objc
    private func shareButtonTapped() {
        guard context.destinationStops.indices.contains(selectedDestinationIndex) else { return }
        shareButton.isHidden = true
        let destination = context.destinationStops[selectedDestinationIndex]
        let text = String(
            format: String(localized: "shuttle.share.journey.format"),
            context.boardingStop.name,
            timeText(context.departureTime),
            destination.name,
            timeText(destination.time),
            shareURL(destination: destination)
        )
        shareJourney?(text)
    }

    private func shareURL(destination: ShuttleAlarmStop) -> String {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "hyuabot.app"
        components.path = "/shuttle"
        components.queryItems = [
            URLQueryItem(name: "stop", value: context.boardingStop.id),
            URLQueryItem(name: "to", value: destination.id)
        ]
        return components.url?.absoluteString ?? "hyuabot://shuttle?stop=\(context.boardingStop.id)"
    }

    private func requestNotificationAndLocationAuthorization(completion: @escaping @MainActor @Sendable (Bool) -> Void) {
        requestNotificationAuthorization { [weak self] granted in
            guard let self else { return }
            guard granted else { completion(false); return }
            locationPermissionRequester.requestIfNeeded { completion(true) }
        }
    }

    private func requestNotificationAuthorization(completion: @escaping @MainActor @Sendable (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    private func presentPermissionAlert() {
        let title = String(localized: "shuttle.alarm.no.permission")
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.applyGodoTypography(title: title, message: nil)
        alert.addAction(UIAlertAction(title: String(localized: "common.ok"), style: .default))
        present(alert, animated: true)
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

@MainActor
private final class ShuttleAlarmLocationPermissionRequester: NSObject, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: (@MainActor @Sendable () -> Void)?
    private var shouldRequestAlways = false

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestIfNeeded(completion: @escaping @MainActor @Sendable () -> Void) {
        shouldRequestAlways = true
        switch manager.authorizationStatus {
        case .notDetermined:
            self.completion = completion
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            self.completion = completion
            manager.requestAlwaysAuthorization()
        default:
            completion()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus != .notDetermined else { return }
        if shouldRequestAlways, manager.authorizationStatus == .authorizedWhenInUse {
            shouldRequestAlways = false
            manager.requestAlwaysAuthorization()
            return
        }
        shouldRequestAlways = false
        completion?()
        completion = nil
    }
}

private final class ShuttleAlarmStopRadioRow: UIControl {
    private let radio = UIView()
    private let dot = UIView()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()

    init(name: String, time: String) {
        super.init(frame: .zero)
        radio.layer.cornerRadius = 11
        radio.layer.borderWidth = 2
        radio.isUserInteractionEnabled = false
        dot.layer.cornerRadius = 5
        dot.isUserInteractionEnabled = false
        radio.addSubview(dot)
        nameLabel.text = name
        nameLabel.numberOfLines = 1
        nameLabel.isUserInteractionEnabled = false
        timeLabel.text = time
        timeLabel.font = SettingsStyle.monospacedDigitFont(15)
        timeLabel.textColor = SettingsStyle.Color.secondaryText
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        timeLabel.isUserInteractionEnabled = false
        let row = UIStackView(arrangedSubviews: [radio, nameLabel, timeLabel])
        row.alignment = .center
        row.spacing = 12
        row.isUserInteractionEnabled = false
        addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)) }
        radio.snp.makeConstraints { $0.size.equalTo(22) }
        dot.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(10) }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(48) }
        isAccessibilityElement = true
        accessibilityLabel = "\(name) \(time)"
        setSelected(false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelected(_ selected: Bool) {
        radio.layer.borderColor = (selected ? SettingsStyle.Color.accent : SettingsStyle.Color.commuterFaint).cgColor
        dot.backgroundColor = selected ? SettingsStyle.Color.accent : .clear
        nameLabel.font = SettingsStyle.font(15, bold: selected)
        nameLabel.textColor = SettingsStyle.Color.text
        accessibilityTraits = selected ? [.button, .selected] : .button
    }
}

struct ShuttleActiveBoardingAlarm {
    let identifier: String
    let key: String
    let routeName: String
    let routeDisplayName: String
    let boardingStopName: String
    let departureTime: Date

    var minutesUntilDeparture: Int {
        max(Int(ceil(departureTime.timeIntervalSince(Date.now) / 60)), 0)
    }
}

extension Notification.Name {
    static let shuttleBoardingAlarmStateDidChange = Notification.Name("shuttleBoardingAlarmStateDidChange")
}

final class ShuttleAlarmNotificationService: @unchecked Sendable {
    static let shared = ShuttleAlarmNotificationService()

    private init() {}

    func activeStates(
        for key: String,
        completion: @escaping @MainActor @Sendable (_ boarding: Bool, _ alighting: Bool) -> Void
    ) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = Set(requests.map(\.identifier))
            DispatchQueue.main.async {
                completion(ids.contains(self.boardingIdentifier(key)), ids.contains(self.alightingIdentifier(key)))
            }
        }
    }

    func activeAlarmKeys(completion: @escaping @MainActor @Sendable (Set<String>) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let keys = requests.compactMap { request -> String? in
                guard self.isShuttleAlarmIdentifier(request.identifier) else { return nil }
                if let key = request.content.userInfo["key"] as? String {
                    return key
                }
                return request.identifier
                    .replacingOccurrences(of: ".boarding", with: "")
                    .replacingOccurrences(of: ".alighting", with: "")
            }
            DispatchQueue.main.async {
                completion(Set(keys))
            }
        }
    }

    func activeBoardingKeys(completion: @escaping @MainActor @Sendable (Set<String>) -> Void) {
        activeAlarmKeys(completion: completion)
    }

    func activeBoardingAlarm(completion: @escaping @MainActor @Sendable (ShuttleActiveBoardingAlarm?) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let alarm = requests.compactMap { request -> ShuttleActiveBoardingAlarm? in
                guard request.identifier.hasSuffix(".boarding"),
                      let trigger = request.trigger as? UNCalendarNotificationTrigger,
                      let departureTime = trigger.nextTriggerDate(),
                      departureTime > Date.now else { return nil }
                let userInfo = request.content.userInfo
                return ShuttleActiveBoardingAlarm(
                    identifier: request.identifier,
                    key: userInfo["key"] as? String ?? request.identifier.replacingOccurrences(of: ".boarding", with: ""),
                    routeName: userInfo["routeName"] as? String ?? "",
                    routeDisplayName: userInfo["routeDisplayName"] as? String ?? userInfo["routeName"] as? String ?? "",
                    boardingStopName: userInfo["boardingStopName"] as? String ?? "",
                    departureTime: departureTime
                )
            }
            .min { $0.departureTime < $1.departureTime }
            DispatchQueue.main.async {
                completion(alarm)
            }
        }
    }

    private static func clockText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    @MainActor
    func scheduleBoardingAlarm(context: ShuttleAlarmContext) {
        let content = UNMutableNotificationContent()
        content.title = String(format: String(localized: "shuttle.alarm.notif.boarding.title.%@"), context.routeDisplayName)
        content.body = String(
            format: String(localized: "shuttle.alarm.notif.boarding.body.%@.%@.%d"),
            context.boardingStop.name,
            Self.clockText(context.departureTime),
            context.minutesUntilDeparture
        )
        content.sound = .default
        content.userInfo = [
            "url": "hyuabot://shuttle",
            "key": context.key,
            "type": "boarding",
            "routeName": context.routeName,
            "routeDisplayName": context.routeDisplayName,
            "boardingStopName": context.boardingStop.name
        ]
        replaceShuttleAlarm {
            self.schedule(identifier: self.boardingIdentifier(context.key), content: content, date: context.departureTime) {
                NotificationCenter.default.post(name: .shuttleBoardingAlarmStateDidChange, object: nil)
            }
            ShuttleBoardingLiveActivityManager.shared.start(context: context)
        }
    }

    @MainActor
    func scheduleAlightingAlarm(context: ShuttleAlarmContext, destination: ShuttleAlarmStop) {
        let content = UNMutableNotificationContent()
        content.title = String(format: String(localized: "shuttle.alarm.notif.alighting.title.%@"), destination.name)
        content.body = String(
            format: String(localized: "shuttle.alarm.notif.alighting.body.%@.%@"),
            destination.name,
            Self.clockText(destination.time)
        )
        content.sound = .default
        content.userInfo = [
            "url": "hyuabot://shuttle",
            "key": context.key,
            "type": "alighting",
            "routeName": context.routeName,
            "routeDisplayName": context.routeDisplayName,
            "boardingStopName": context.boardingStop.name,
            "destinationStopName": destination.name
        ]
        replaceShuttleAlarm {
            self.schedule(identifier: self.alightingIdentifier(context.key), content: content, date: destination.time) {
                NotificationCenter.default.post(name: .shuttleBoardingAlarmStateDidChange, object: nil)
            }
            ShuttleBoardingLiveActivityManager.shared.startAlighting(context: context, destination: destination)
        }
    }

    @MainActor
    func fireAlightingProximityAlert(context: ShuttleAlarmContext, destination: ShuttleAlarmStop, distance: Int) {
        cancelAlightingAlarm(for: context.key)
        let content = UNMutableNotificationContent()
        content.title = String(localized: "shuttle.alarm.notif.soon.title")
        content.body = String(
            format: String(localized: "shuttle.alarm.notif.soon.body.%@.%@"),
            destination.name,
            formatDistance(distance)
        )
        content.sound = .default
        content.userInfo = [
            "url": "hyuabot://shuttle",
            "key": context.key,
            "type": "alighting"
        ]
        let request = UNNotificationRequest(
            identifier: "\(alightingIdentifier(context.key)).proximity",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
        NotificationCenter.default.post(name: .shuttleBoardingAlarmStateDidChange, object: nil)
    }

    @MainActor
    func cancelBoardingAlarm(for key: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [boardingIdentifier(key)])
        ShuttleBoardingLiveActivityManager.shared.end(for: key)
        NotificationCenter.default.post(name: .shuttleBoardingAlarmStateDidChange, object: nil)
    }

    @MainActor
    func cancelAlightingAlarm(for key: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alightingIdentifier(key)])
        ShuttleBoardingLiveActivityManager.shared.end(for: key)
        NotificationCenter.default.post(name: .shuttleBoardingAlarmStateDidChange, object: nil)
    }

    @MainActor
    private func schedule(
        identifier: String,
        content: UNNotificationContent,
        date: Date,
        completion: (@MainActor () -> Void)? = nil
    ) {
        guard date > Date.now else { return }
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { _ in
            DispatchQueue.main.async {
                completion?()
            }
        }
    }

    @MainActor
    private func replaceShuttleAlarm(scheduleNewAlarm: @escaping @MainActor () -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiers = requests
                .map(\.identifier)
                .filter { self.isShuttleAlarmIdentifier($0) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            DispatchQueue.main.async {
                Task {
                    if #available(iOS 16.1, *) {
                        await ShuttleBoardingLiveActivityManager.shared.endAllAndWait()
                    } else {
                        ShuttleBoardingLiveActivityManager.shared.endAll()
                    }
                    NotificationCenter.default.post(name: .shuttleBoardingAlarmStateDidChange, object: nil)
                    scheduleNewAlarm()
                }
            }
        }
    }

    private func isShuttleAlarmIdentifier(_ identifier: String) -> Bool {
        identifier.hasSuffix(".boarding") || identifier.hasSuffix(".alighting")
    }

    private func formatDistance(_ distance: Int) -> String {
        if distance >= 1000 {
            if distance.isMultiple(of: 1000) {
                return "\(distance / 1000)km"
            }
            return String(format: "%.1fkm", locale: Locale(identifier: "en_US_POSIX"), Double(distance) / 1000)
        }
        return "\(distance)m"
    }

    private func boardingIdentifier(_ key: String) -> String {
        "\(key).boarding"
    }

    private func alightingIdentifier(_ key: String) -> String {
        "\(key).alighting"
    }
}
