import UIKit
import UserNotifications
import SnapKit
import Then

class ShuttleAlarmVC: UIViewController {
    private let context: ShuttleAlarmContext
    private var selectedDestinationIndex = 0
    private var isBoardingAlarmActive = false
    private var isAlightingAlarmActive = false
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
        $0.showsMenuAsPrimaryAction = true
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
        configureDestinationMenu()
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

    private func configureDestinationMenu() {
        let actions = context.destinationStops.enumerated().map { index, stop in
            UIAction(title: stop.name, state: index == selectedDestinationIndex ? .on : .off) { [weak self] _ in
                self?.selectedDestinationIndex = index
                self?.configureDestinationMenu()
            }
        }
        destinationButton.menu = UIMenu(children: actions)
        destinationButton.configuration?.title = context.destinationStops[selectedDestinationIndex].name
    }

    @objc private func boardingButtonTapped() {
        if isBoardingAlarmActive {
            ShuttleAlarmNotificationService.shared.cancelBoardingAlarm(for: context.key)
            dismiss(animated: true)
            return
        }
        requestNotificationAuthorization { [weak self] granted in
            guard let self else { return }
            if granted {
                ShuttleAlarmNotificationService.shared.scheduleBoardingAlarm(context: self.context)
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
        requestNotificationAuthorization { [weak self] granted in
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

private final class ShuttleAlarmNotificationService {
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

    func scheduleBoardingAlarm(context: ShuttleAlarmContext) {
        let content = UNMutableNotificationContent()
        content.title = String(format: String(localized: "shuttle.alarm.boarding.notification.title"), context.boardingStop.name)
        content.body = String(format: String(localized: "shuttle.alarm.boarding.notification.body"), context.minutesUntilDeparture, context.boardingStop.name)
        content.sound = .default
        content.userInfo = ["url": "hyuabot://shuttle"]
        schedule(identifier: boardingIdentifier(context.key), content: content, date: context.departureTime)
    }

    func scheduleAlightingAlarm(context: ShuttleAlarmContext, destination: ShuttleAlarmStop) {
        let content = UNMutableNotificationContent()
        content.title = String(format: String(localized: "shuttle.alarm.alighting.notification.title"), destination.name)
        content.body = String(format: String(localized: "shuttle.alarm.alighting.notification.body"), destination.name)
        content.sound = .default
        content.userInfo = ["url": "hyuabot://shuttle"]
        schedule(identifier: alightingIdentifier(context.key), content: content, date: destination.time)
    }

    func cancelBoardingAlarm(for key: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [boardingIdentifier(key)])
    }

    func cancelAlightingAlarm(for key: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alightingIdentifier(key)])
    }

    private func schedule(identifier: String, content: UNNotificationContent, date: Date) {
        guard date > Date.now else { return }
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func boardingIdentifier(_ key: String) -> String {
        "\(key).boarding"
    }

    private func alightingIdentifier(_ key: String) -> String {
        "\(key).alighting"
    }
}
