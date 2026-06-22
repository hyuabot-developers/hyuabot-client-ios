import UIKit
import UserNotifications
import CoreLocation
import SnapKit
import Then

class ShuttleAlarmVC: UIViewController {
    private let context: ShuttleAlarmContext
    private var selectedDestinationIndex = 0
    private var isBoardingAlarmActive = false
    private var isAlightingAlarmActive = false
    private let locationPermissionRequester = ShuttleAlarmLocationPermissionRequester()
    var shareJourney: ((String) -> Void)?

    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 20, weight: .bold)
        $0.textColor = .white
        $0.backgroundColor = .hanyangBlue
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.alarm.title")
    }
    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
        $0.alignment = .fill
        $0.isLayoutMarginsRelativeArrangement = true
        $0.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 18, bottom: 18, trailing: 18)
    }
    private lazy var boardingCard = makeCard()
    private lazy var boardingTitleLabel = makeTitleLabel(text: String(localized: "shuttle.alarm.boarding"))
    private let boardingDescriptionLabel = UILabel().then {
        $0.font = .godo(size: 15, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
    }
    private lazy var boardingButton = makeActionButton()
    private lazy var alightingCard = makeCard()
    private lazy var alightingTitleLabel = makeTitleLabel(text: String(localized: "shuttle.alarm.alighting"))
    private let destinationButton = UIButton(type: .system).then {
        var configuration = UIButton.Configuration.bordered()
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .godo(size: 15, weight: .medium)
            return outgoing
        }
        $0.configuration = configuration
        $0.contentHorizontalAlignment = .center
    }
    private lazy var alightingButton = makeActionButton()
    private let shareButton = UIButton(type: .system).then {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "square.and.arrow.up")
        configuration.imagePadding = 8
        configuration.title = String(localized: "shuttle.share.journey")
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .godo(size: 15, weight: .medium)
            return outgoing
        }
        $0.configuration = configuration
        $0.tintColor = .hanyangBlue
    }

    init(context: ShuttleAlarmContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var sheetHeight: CGFloat {
        let baseHeight: CGFloat = 52 + 28 + 122 + 28
        let alightingHeight: CGFloat = context.destinationStops.isEmpty ? 0 : 176
        return baseHeight + alightingHeight
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        reloadAlarmState()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        boardingCard.backgroundColor = cardBackgroundColor
        alightingCard.backgroundColor = cardBackgroundColor
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(titleLabel)
        view.addSubview(stackView)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }
        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        boardingDescriptionLabel.text = "\(context.boardingStop.name) · \(String(format: String(localized: "shuttle.alarm.boarding.initial"), context.minutesUntilDeparture))"
        boardingButton.addTarget(self, action: #selector(boardingButtonTapped), for: .touchUpInside)
        let boardingStack = makeCardStack([boardingTitleLabel, boardingDescriptionLabel, boardingButton])
        boardingCard.addSubview(boardingStack)
        boardingStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(14)
        }
        stackView.addArrangedSubview(boardingCard)

        guard !context.destinationStops.isEmpty else { return }
        configureDestinationButton()
        destinationButton.addTarget(self, action: #selector(destinationButtonTapped), for: .touchUpInside)
        alightingButton.addTarget(self, action: #selector(alightingButtonTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        let alightingStack = makeCardStack([alightingTitleLabel, destinationButton, alightingButton, shareButton])
        alightingCard.addSubview(alightingStack)
        alightingStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(14)
        }
        stackView.addArrangedSubview(alightingCard)
    }

    private func reloadAlarmState() {
        ShuttleAlarmNotificationService.shared.activeStates(for: context.key) { [weak self] boarding, alighting in
            guard let self else { return }
            self.isBoardingAlarmActive = boarding
            self.isAlightingAlarmActive = alighting
            self.updateButtons()
        }
    }

    private func updateButtons() {
        boardingButton.configuration?.title = String(localized: isBoardingAlarmActive ? "shuttle.alarm.cancel" : "shuttle.alarm.start")
        alightingButton.configuration?.title = String(localized: isAlightingAlarmActive ? "shuttle.alarm.cancel" : "shuttle.alarm.start")
    }

    private func configureDestinationButton() {
        destinationButton.configuration?.title = context.destinationStops[selectedDestinationIndex].name
    }

    @objc private func destinationButtonTapped() {
        let vc = ShuttleDestinationSelectionVC(
            stops: context.destinationStops,
            selectedIndex: selectedDestinationIndex
        ) { [weak self] index in
            self?.selectedDestinationIndex = index
            self?.configureDestinationButton()
        }
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom(resolver: { _ in vc.sheetHeight })]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }

    @objc private func boardingButtonTapped() {
        if isBoardingAlarmActive {
            ShuttleAlarmNotificationService.shared.cancelBoardingAlarm(for: context.key)
            dismiss(animated: true)
            return
        }
        requestNotificationAndLocationAuthorization { [weak self] granted in
            guard let self else { return }
            if granted {
                ShuttleAlarmNotificationService.shared.scheduleBoardingAlarm(context: self.context)
                NotificationCenter.default.post(name: .shuttleBoardingAlarmStateDidChange, object: nil)
                self.dismiss(animated: true)
            } else {
                self.presentPermissionAlert()
            }
        }
    }

    @objc private func alightingButtonTapped() {
        if isAlightingAlarmActive {
            ShuttleAlarmNotificationService.shared.cancelAlightingAlarm(for: context.key)
            dismiss(animated: true)
            return
        }
        guard context.destinationStops.indices.contains(selectedDestinationIndex) else { return }
        let destination = context.destinationStops[selectedDestinationIndex]
        requestNotificationAndLocationAuthorization { [weak self] granted in
            guard let self else { return }
            if granted {
                ShuttleAlarmNotificationService.shared.scheduleAlightingAlarm(context: self.context, destination: destination)
                self.dismiss(animated: true)
            } else {
                self.presentPermissionAlert()
            }
        }
    }

    @objc private func shareButtonTapped() {
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

    private func requestNotificationAndLocationAuthorization(completion: @escaping (Bool) -> Void) {
        requestNotificationAuthorization { [weak self] granted in
            guard let self else { return }
            guard granted else {
                completion(false)
                return
            }
            self.locationPermissionRequester.requestIfNeeded {
                completion(true)
            }
        }
    }

    private func requestNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    private func presentPermissionAlert() {
        let alert = UIAlertController(
            title: String(localized: "shuttle.alarm.no.permission"),
            message: nil,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: "common.ok"), style: .default))
        present(alert, animated: true)
    }

    private func makeCard() -> UIView {
        UIView().then {
            $0.backgroundColor = cardBackgroundColor
            $0.layer.cornerRadius = 8
            $0.layer.masksToBounds = false
            $0.layer.borderWidth = 1
            $0.layer.borderColor = UIColor.separator.cgColor
            $0.layer.shadowColor = UIColor.black.cgColor
            $0.layer.shadowOpacity = 0.08
            $0.layer.shadowRadius = 8
            $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        }
    }

    private var cardBackgroundColor: UIColor {
        traitCollection.userInterfaceStyle == .dark ? .tertiarySystemBackground : .secondarySystemBackground
    }

    private func makeCardStack(_ views: [UIView]) -> UIStackView {
        UIStackView(arrangedSubviews: views).then {
            $0.axis = .vertical
            $0.spacing = 10
            $0.alignment = .fill
        }
    }

    private func makeTitleLabel(text: String) -> UILabel {
        UILabel().then {
            $0.font = .godo(size: 17, weight: .bold)
            $0.text = text
            $0.textColor = .label
        }
    }

    private func makeActionButton() -> UIButton {
        UIButton(type: .system).then {
            var configuration = UIButton.Configuration.filled()
            configuration.baseBackgroundColor = .hanyangBlue
            configuration.baseForegroundColor = .white
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .godo(size: 16, weight: .medium)
                return outgoing
            }
            $0.configuration = configuration
            $0.snp.makeConstraints { make in
                make.height.equalTo(42)
            }
        }
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

private final class ShuttleAlarmLocationPermissionRequester: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: (() -> Void)?
    private var shouldRequestAlways = false

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestIfNeeded(completion: @escaping () -> Void) {
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

private final class ShuttleDestinationSelectionVC: UIViewController {
    private let stops: [ShuttleAlarmStop]
    private let selectedIndex: Int
    private let onSelect: (Int) -> Void

    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 18, weight: .bold)
        $0.textColor = .label
        $0.text = String(localized: "shuttle.alarm.alighting")
    }
    private let tableView = UITableView(frame: .zero, style: .plain).then {
        $0.backgroundColor = .clear
        $0.separatorInset = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        $0.rowHeight = 68
        $0.register(ShuttleDestinationSelectionCell.self, forCellReuseIdentifier: ShuttleDestinationSelectionCell.reuseIdentifier)
    }

    var sheetHeight: CGFloat {
        min(CGFloat(stops.count) * 68 + 72, 460)
    }

    init(stops: [ShuttleAlarmStop], selectedIndex: Int, onSelect: @escaping (Int) -> Void) {
        self.stops = stops
        self.selectedIndex = selectedIndex
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(titleLabel)
        view.addSubview(tableView)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(18)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

extension ShuttleDestinationSelectionVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        stops.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ShuttleDestinationSelectionCell.reuseIdentifier,
            for: indexPath
        ) as? ShuttleDestinationSelectionCell else { return UITableViewCell() }
        let stop = stops[indexPath.row]
        cell.configure(name: stop.name, time: timeText(stop.time), isSelected: indexPath.row == selectedIndex)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelect(indexPath.row)
        dismiss(animated: true)
    }
}

private final class ShuttleDestinationSelectionCell: UITableViewCell {
    static let reuseIdentifier = "ShuttleDestinationSelectionCell"

    private let nameLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .medium)
        $0.textColor = .label
        $0.lineBreakMode = .byTruncatingTail
    }
    private let timeLabel = UILabel().then {
        $0.font = .godo(size: 13, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.lineBreakMode = .byTruncatingTail
    }
    private let checkImageView = UIImageView().then {
        $0.image = UIImage(systemName: "checkmark")
        $0.tintColor = .hanyangBlue
        $0.contentMode = .scaleAspectFit
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .systemBackground
        contentView.addSubview(nameLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(checkImageView)

        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(11)
            make.leading.equalToSuperview().offset(18)
            make.trailing.lessThanOrEqualTo(checkImageView.snp.leading).offset(-12)
        }
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(5)
            make.leading.equalTo(nameLabel)
            make.trailing.lessThanOrEqualTo(checkImageView.snp.leading).offset(-12)
            make.bottom.lessThanOrEqualToSuperview().offset(-10)
        }
        checkImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(18)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(name: String, time: String, isSelected: Bool) {
        nameLabel.text = name
        timeLabel.text = time
        checkImageView.isHidden = !isSelected
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

final class ShuttleAlarmNotificationService {
    static let shared = ShuttleAlarmNotificationService()

    private init() {}

    func activeStates(for key: String, completion: @escaping (_ boarding: Bool, _ alighting: Bool) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = Set(requests.map(\.identifier))
            DispatchQueue.main.async {
                completion(ids.contains(self.boardingIdentifier(key)), ids.contains(self.alightingIdentifier(key)))
            }
        }
    }

    func activeAlarmKeys(completion: @escaping (Set<String>) -> Void) {
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

    func activeBoardingKeys(completion: @escaping (Set<String>) -> Void) {
        activeAlarmKeys(completion: completion)
    }

    func activeBoardingAlarm(completion: @escaping (ShuttleActiveBoardingAlarm?) -> Void) {
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
            .sorted { $0.departureTime < $1.departureTime }
            .first
            DispatchQueue.main.async {
                completion(alarm)
            }
        }
    }

    func scheduleBoardingAlarm(context: ShuttleAlarmContext) {
        let content = UNMutableNotificationContent()
        content.title = String(format: String(localized: "shuttle.alarm.boarding.notification.title"), context.boardingStop.name)
        content.body = String(format: String(localized: "shuttle.alarm.boarding.notification.body"), context.minutesUntilDeparture, context.boardingStop.name)
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

    func scheduleAlightingAlarm(context: ShuttleAlarmContext, destination: ShuttleAlarmStop) {
        let content = UNMutableNotificationContent()
        content.title = String(format: String(localized: "shuttle.alarm.alighting.notification.title"), destination.name)
        content.body = String(format: String(localized: "shuttle.alarm.alighting.notification.body"), destination.name)
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

    func fireAlightingProximityAlert(context: ShuttleAlarmContext, destination: ShuttleAlarmStop, distance: Int) {
        cancelAlightingAlarm(for: context.key)
        let content = UNMutableNotificationContent()
        content.title = String(localized: "shuttle.alarm.alighting.alert.title")
        content.body = String(
            format: String(localized: "shuttle.alarm.alighting.alert.body"),
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

    func cancelBoardingAlarm(for key: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [boardingIdentifier(key)])
        ShuttleBoardingLiveActivityManager.shared.end(for: key)
        NotificationCenter.default.post(name: .shuttleBoardingAlarmStateDidChange, object: nil)
    }

    func cancelAlightingAlarm(for key: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alightingIdentifier(key)])
        ShuttleBoardingLiveActivityManager.shared.end(for: key)
        NotificationCenter.default.post(name: .shuttleBoardingAlarmStateDidChange, object: nil)
    }

    private func schedule(identifier: String, content: UNNotificationContent, date: Date, completion: (() -> Void)? = nil) {
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

    private func replaceShuttleAlarm(scheduleNewAlarm: @escaping () -> Void) {
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
        if distance >= 1_000 {
            if distance % 1_000 == 0 {
                return "\(distance / 1_000)km"
            }
            return String(format: "%.1fkm", locale: Locale(identifier: "en_US_POSIX"), Double(distance) / 1_000)
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
