import Api
import ApolloAPI
import CoreLocation
import RxSwift
import SnapKit
import Then
import UIKit

private final class HomePaddedLabel: UILabel {
    var contentInsets = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12) {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }
}

private enum HomeDeparture: CaseIterable {
    case dormitory
    case shuttlecock
    case station
    case terminal
    case jungang

    var title: String {
        switch self {
        case .dormitory: String(localized: "shuttle.stop.dormitory.out")
        case .shuttlecock: String(localized: "shuttle.stop.shuttlecock.out")
        case .station: String(localized: "shuttle.stop.station")
        case .terminal: String(localized: "shuttle.stop.terminal")
        case .jungang: String(localized: "shuttle.stop.jungang.station")
        }
    }

    var location: CLLocation {
        switch self {
        case .dormitory: CLLocation(latitude: 37.29339607529377, longitude: 126.83630604103446)
        case .shuttlecock: CLLocation(latitude: 37.29875417910844, longitude: 126.83784054072336)
        case .station: CLLocation(latitude: 37.309700971618255, longitude: 126.85207173389148)
        case .terminal: CLLocation(latitude: 37.319338173415936, longitude: 126.8455263115596)
        case .jungang: CLLocation(latitude: 37.31487247528457, longitude: 126.83963540399434)
        }
    }

    func presenceStopID(for destination: HomeDestination) -> String {
        if self == .shuttlecock, destination == .dormitory {
            return "shuttlecock_i"
        }
        return switch self {
        case .dormitory: "dormitory_o"
        case .shuttlecock: "shuttlecock_o"
        case .station: "station"
        case .terminal: "terminal"
        case .jungang: "jungang_stn"
        }
    }

    var destinations: [HomeDestination] {
        switch self {
        case .dormitory: [.station, .terminal, .jungang]
        case .shuttlecock: [.station, .terminal, .jungang, .dormitory]
        case .station: [.dormitory, .terminal, .jungang]
        case .terminal, .jungang: [.dormitory]
        }
    }

    func timetableStart(for destination: HomeDestination) -> String.LocalizationValue {
        if case (.shuttlecock, .dormitory) = (self, destination) {
            return "shuttle.stop.shuttlecock.in"
        }
        return switch self {
        case .dormitory: "shuttle.stop.dormitory.out"
        case .shuttlecock: "shuttle.stop.shuttlecock.out"
        case .station: "shuttle.stop.station"
        case .terminal: "shuttle.stop.terminal"
        case .jungang: "shuttle.stop.jungang.station"
        }
    }
}

#if DEBUG
    private extension HomeDeparture {
        init?(debugValue: String) {
            switch debugValue {
            case "dormitory":
                self = .dormitory
            case "shuttlecock":
                self = .shuttlecock
            case "station":
                self = .station
            case "terminal":
                self = .terminal
            case "jungang":
                self = .jungang
            default:
                return nil
            }
        }
    }
#endif

private enum HomeDestination: CaseIterable {
    case station
    case terminal
    case jungang
    case dormitory

    var title: String {
        switch self {
        case .station: String(localized: "home.destination.station")
        case .terminal: String(localized: "shuttle.stop.terminal")
        case .jungang: String(localized: "home.destination.jungang")
        case .dormitory: String(localized: "shuttle.stop.dormitory.in")
        }
    }

    var analyticsValue: String {
        switch self {
        case .station: "station"
        case .terminal: "terminal"
        case .jungang: "jungang"
        case .dormitory: "dormitory"
        }
    }

    var timetableDestination: String.LocalizationValue {
        switch self {
        case .station: "shuttle.destination.shorten.station"
        case .terminal: "shuttle.destination.shorten.terminal"
        case .jungang: "shuttle.destination.shorten.jungang_station"
        case .dormitory: "shuttle.destination.shorten.campus"
        }
    }
}

#if DEBUG
    private extension HomeDestination {
        init?(debugValue: String) {
            switch debugValue {
            case "station":
                self = .station
            case "terminal":
                self = .terminal
            case "jungang":
                self = .jungang
            case "dormitory":
                self = .dormitory
            default:
                return nil
            }
        }
    }
#endif

private struct HomeTransitOption {
    enum Kind {
        case shuttle
        case alternative
        case transfer
    }

    let kind: Kind
    let title: String
    let subtitle: String
    let minutes: Int?
    let badge: String
    let tintColor: UIColor
    let connections: [HomeTransferConnection]

    init(
        kind: Kind,
        title: String,
        subtitle: String,
        minutes: Int?,
        badge: String,
        tintColor: UIColor,
        connections: [HomeTransferConnection] = []
    ) {
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.minutes = minutes
        self.badge = badge
        self.tintColor = tintColor
        self.connections = connections
    }
}

private struct HomeTransferConnection {
    let badge: String
    let title: String
    let subtitle: String
    let connectorTitle: String
    let connectorTravelMinutes: Int?
    let trailing: String
    let tintColor: UIColor
    let arrivalDate: Foundation.Date
    let minimumTransferMinutes: Int
}

private final class HomeTransferConnectorView: UIStackView {
    private let connectorTintColor: UIColor
    private let linkIcon = UIImageView(image: UIImage(systemName: "link"))
    private let titleLabel = UILabel()

    init(title: String, travelMinutes: Int?, tintColor: UIColor) {
        connectorTintColor = tintColor
        super.init(frame: .zero)

        axis = .horizontal
        alignment = .center
        spacing = 4
        layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        isLayoutMarginsRelativeArrangement = true
        layer.cornerRadius = 12
        layer.borderWidth = 1

        linkIcon.contentMode = .scaleAspectFit
        linkIcon.isAccessibilityElement = false
        titleLabel.text = if let travelMinutes {
            String(
                format: String(localized: "home.transfer.connector.travel_time"),
                locale: Locale.current,
                title,
                travelMinutes
            )
        } else {
            title
        }
        isAccessibilityElement = true
        accessibilityLabel = titleLabel.text
        accessibilityTraits = .staticText
        titleLabel.font = .godo(size: 10, weight: .bold)
        titleLabel.numberOfLines = 1
        titleLabel.isAccessibilityElement = false

        addArrangedSubview(linkIcon)
        addArrangedSubview(titleLabel)
        linkIcon.snp.makeConstraints { make in
            make.width.height.equalTo(11)
        }
        updateAppearance()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateAppearance()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        updateAppearance()
    }

    private func updateAppearance() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        backgroundColor = isDarkMode ? .secondarySystemBackground : .systemBackground
        layer.borderColor = connectorTintColor
            .withAlphaComponent(isDarkMode ? 0.60 : 0.18)
            .resolvedColor(with: traitCollection)
            .cgColor
        linkIcon.tintColor = isDarkMode ? .white : connectorTintColor.withAlphaComponent(0.72)
        titleLabel.textColor = isDarkMode ? .white : connectorTintColor
    }
}

private struct HomeSubwayArrival {
    let lineBadge: String
    let terminalStationID: String
    let terminalName: String
    let tintColor: UIColor
    let arrivalDate: Foundation.Date
    let isRealtime: Bool
    let location: String?
    let stops: Int?
    let status: Int?
}

private struct HomeShuttleCandidate {
    struct Stop {
        let name: String
        let time: LocalTime
    }

    let seq: Int
    let routeTag: String
    let routeName: String
    let time: LocalTime
    let stops: [Stop]
}

private extension HomeShuttleCandidate {
    init(entry: HomePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) {
        seq = entry.seq
        routeTag = entry.route.tag
        routeName = entry.route.name
        time = entry.time
        stops = entry.stops.map { Stop(name: $0.stop, time: $0.time) }
    }
}

private struct HomeShuttleRoute {
    let stop: String
    let destination: String
    let routeFilter: ((HomePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) -> Bool)?
}

private struct HomeMealItem {
    let menu: String
    let price: String
}

private struct HomeMealSection {
    let cafeteria: String
    let runningTime: String?
    let items: [HomeMealItem]
}

private struct HomeMealPeriod {
    let marker: String
    let title: String
    let queryDate: Foundation.Date
    let iconName: String
    let mealIndex: Int
}

private extension UIColor {
    static let homeSubwayYellow = UIColor(red: 0.72, green: 0.48, blue: 0.00, alpha: 1.00)
    static let homeSubwaySeohae = UIColor(red: 0.56, green: 0.76, blue: 0.12, alpha: 1.00)
    static let homeActionButtonBackground = UIColor(red: 0.86, green: 0.93, blue: 0.98, alpha: 1.00)
    static let homeSelectorIconTint = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? .white : .hanyangBlue
    }
}

private enum HomeSettings {
    static let showBus50TransferKey = "home.showBus50Transfer"
    static let showSubwayTransferKey = "home.showSubwayTransfer"
    static let subwayTransferDestinationKey = "home.subwayTransferDestination"

    static var showBus50Transfer: Bool {
        get {
            if UserDefaults.standard.object(forKey: showBus50TransferKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: showBus50TransferKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: showBus50TransferKey)
        }
    }

    static var showSubwayTransfer: Bool {
        get {
            if UserDefaults.standard.object(forKey: showSubwayTransferKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: showSubwayTransferKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: showSubwayTransferKey)
        }
    }

    static var subwayTransferDestination: SubwayTransferDestination {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: subwayTransferDestinationKey),
                  let destination = SubwayTransferDestination(rawValue: rawValue)
            else { return .seoul }
            return destination
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: subwayTransferDestinationKey)
        }
    }
}

private enum SubwayTransferDestination: String, CaseIterable {
    case seoul
    case suwonYongin
    case incheon
    case oido
    case sosa

    var title: String {
        switch self {
        case .seoul:
            String(localized: "home.quick_settings.subway_destination.seoul")
        case .suwonYongin:
            String(localized: "home.quick_settings.subway_destination.suwon_yongin")
        case .incheon:
            String(localized: "home.quick_settings.subway_destination.incheon")
        case .oido:
            String(localized: "home.quick_settings.subway_destination.oido")
        case .sosa:
            String(localized: "home.quick_settings.subway_destination.sosa")
        }
    }
}

#if DEBUG
    private extension SubwayTransferDestination {
        init?(debugValue: String) {
            switch debugValue {
            case "seoul":
                self = .seoul
            case "suwonYongin", "suwon_yongin":
                self = .suwonYongin
            case "incheon":
                self = .incheon
            case "oido":
                self = .oido
            case "sosa":
                self = .sosa
            default:
                return nil
            }
        }
    }
#endif

private final class HomeQuickSettingsVC: UIViewController {
    var openLegacyShuttle: (() -> Void)?
    var updateShowPresenceStatus: ((Bool) -> Void)?
    var updateShowBus50Transfer: ((Bool) -> Void)?
    var updateShowSubwayTransfer: ((Bool) -> Void)?
    var updateSubwayTransferDestination: ((SubwayTransferDestination) -> Void)?
    let preferredSheetHeight: CGFloat = 460

    private let contentStack = UIStackView()
    private let showPresenceStatusSwitch = UISwitch()
    private let showBus50TransferSwitch = UISwitch()
    private let showSubwayTransferSwitch = UISwitch()
    private let subwayDestinationControl = UISegmentedControl()

    init(
        showPresenceStatus: Bool,
        showBus50Transfer: Bool,
        showSubwayTransfer: Bool,
        subwayTransferDestination: SubwayTransferDestination
    ) {
        showPresenceStatusSwitch.isOn = showPresenceStatus
        showBus50TransferSwitch.isOn = showBus50Transfer
        showSubwayTransferSwitch.isOn = showSubwayTransfer
        super.init(nibName: nil, bundle: nil)
        for (index, destination) in SubwayTransferDestination.allCases.enumerated() {
            subwayDestinationControl.insertSegment(withTitle: destination.title, at: index, animated: false)
        }
        subwayDestinationControl.selectedSegmentIndex = SubwayTransferDestination.allCases.firstIndex(of: subwayTransferDestination) ?? 0
        subwayDestinationControl.isEnabled = showSubwayTransfer
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.layoutMargins = UIEdgeInsets(top: 22, left: 20, bottom: 24, right: 20)
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide)
        }

        let title = UILabel()
        title.text = String(localized: "home.quick_settings.title")
        title.font = .godo(size: 20, weight: .bold)
        title.textColor = .label

        showPresenceStatusSwitch.addTarget(self, action: #selector(onChangeShowPresenceStatus), for: .valueChanged)
        showBus50TransferSwitch.addTarget(self, action: #selector(onChangeShowBus50Transfer), for: .valueChanged)
        showSubwayTransferSwitch.addTarget(self, action: #selector(onChangeShowSubwayTransfer), for: .valueChanged)
        subwayDestinationControl.addTarget(self, action: #selector(onChangeSubwayTransferDestination), for: .valueChanged)

        contentStack.addArrangedSubview(title)
        contentStack.addArrangedSubview(settingRow(
            title: String(localized: "shuttle.quick_settings.presence.title"),
            subtitle: String(localized: "shuttle.quick_settings.presence.subtitle"),
            control: showPresenceStatusSwitch,
            identifier: "home.quick_settings.presence_row"
        ))
        contentStack.addArrangedSubview(settingRow(
            title: String(localized: "home.quick_settings.bus50_transfer.title"),
            subtitle: String(localized: "home.quick_settings.bus50_transfer.subtitle"),
            control: showBus50TransferSwitch,
            identifier: "home.quick_settings.bus50_transfer_row"
        ))
        contentStack.addArrangedSubview(subwayTransferRow())
        contentStack.addArrangedSubview(legacyActionRow())
    }

    private func settingRow(title: String, subtitle: String, control: UISwitch, identifier: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.accessibilityIdentifier = identifier
        row.isAccessibilityElement = true
        row.layoutMargins = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        row.isLayoutMarginsRelativeArrangement = true
        row.backgroundColor = .secondarySystemBackground
        row.layer.cornerRadius = 8

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 4

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .godo(size: 16, weight: .bold)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .godo(size: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        row.addArrangedSubview(textStack)
        row.addArrangedSubview(control)
        row.snp.makeConstraints { make in
            make.height.equalTo(76)
        }
        row.setContentHuggingPriority(.required, for: .vertical)
        row.setContentCompressionResistancePriority(.required, for: .vertical)
        return row
    }

    private func subwayTransferRow() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.accessibilityIdentifier = "home.quick_settings.subway_transfer_row"
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.backgroundColor = .secondarySystemBackground
        stack.layer.cornerRadius = 8

        let header = UIStackView()
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 4

        let titleLabel = UILabel()
        titleLabel.text = String(localized: "home.quick_settings.subway_transfer.title")
        titleLabel.font = .godo(size: 16, weight: .bold)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = String(localized: "home.quick_settings.subway_transfer.subtitle")
        subtitleLabel.font = .godo(size: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        header.addArrangedSubview(textStack)
        header.addArrangedSubview(showSubwayTransferSwitch)

        subwayDestinationControl.setTitleTextAttributes([
            .font: UIFont.godo(size: 12, weight: .regular)
        ], for: .normal)
        subwayDestinationControl.setTitleTextAttributes([
            .font: UIFont.godo(size: 12, weight: .bold)
        ], for: .selected)

        stack.addArrangedSubview(header)
        stack.addArrangedSubview(subwayDestinationControl)
        stack.snp.makeConstraints { make in
            make.height.equalTo(118)
        }
        stack.setContentHuggingPriority(.required, for: .vertical)
        stack.setContentCompressionResistancePriority(.required, for: .vertical)
        return stack
    }

    private func legacyActionRow() -> UIView {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.background.backgroundColor = .homeActionButtonBackground
        config.baseForegroundColor = .hanyangBlue
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "bus.fill")
        config.attributedTitle = AttributedString(String(localized: "home.quick_settings.legacy"), attributes: AttributeContainer([
            .font: UIFont.godo(size: 17, weight: .bold)
        ]))
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        button.configuration = config
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(onTapLegacy), for: .touchUpInside)
        button.accessibilityIdentifier = "home.quick_settings.open_legacy"
        button.snp.makeConstraints { make in
            make.height.equalTo(52)
        }
        button.setContentHuggingPriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        return button
    }

    @objc private func onChangeShowBus50Transfer() {
        updateShowBus50Transfer?(showBus50TransferSwitch.isOn)
    }

    @objc private func onChangeShowPresenceStatus() {
        updateShowPresenceStatus?(showPresenceStatusSwitch.isOn)
    }

    @objc private func onChangeShowSubwayTransfer() {
        subwayDestinationControl.isEnabled = showSubwayTransferSwitch.isOn
        updateShowSubwayTransfer?(showSubwayTransferSwitch.isOn)
    }

    @objc private func onChangeSubwayTransferDestination() {
        guard SubwayTransferDestination.allCases.indices.contains(subwayDestinationControl.selectedSegmentIndex) else { return }
        updateSubwayTransferDestination?(SubwayTransferDestination.allCases[subwayDestinationControl.selectedSegmentIndex])
    }

    @objc private func onTapLegacy() {
        dismiss(animated: true) { [weak self] in
            self?.openLegacyShuttle?()
        }
    }
}

private final class HomeWeatherIconView: UIView {
    private enum Condition {
        case clear
        case cloud
        case rain
        case sleet
        case snow
    }

    private struct Palette {
        let sunCore: UIColor
        let sunEdge: UIColor
        let sunRay: UIColor
        let cloudBack: UIColor
        let cloudFrontTop: UIColor
        let cloudFrontBottom: UIColor
        let rain: UIColor
        let snow: UIColor
        let shadow: UIColor
    }

    private let artLayer = CALayer()
    private let sunRaysLayer = CAShapeLayer()
    private let sunCoreLayer = CAShapeLayer()
    private let sunHighlightLayer = CAShapeLayer()
    private let cloudBackLayer = CAShapeLayer()
    private let cloudShadowLayer = CAShapeLayer()
    private let cloudGradientLayer = CAGradientLayer()
    private let cloudMaskLayer = CAShapeLayer()
    private let particleLayers = (0..<4).map { _ in CAShapeLayer() }
    private var condition = Condition.cloud

    override var isHidden: Bool {
        didSet {
            updateAnimationState()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    func setWeatherCondition(_ value: String) {
        let nextCondition: Condition = switch value {
        case "CLEAR": .clear
        case "RAIN": .rain
        case "SLEET": .sleet
        case "SNOW": .snow
        default: .cloud
        }
        guard condition != nextCondition else { return }
        condition = nextCondition
        configureArtwork()
        updateAnimationState()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let artworkScale = min(bounds.width, bounds.height) / 100
        artLayer.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        artLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        artLayer.setAffineTransform(CGAffineTransform(scaleX: artworkScale, y: artworkScale))
        configureArtwork()
        updateAnimationState()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateAnimationState()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        updateColors()
    }

    private func setupLayers() {
        isAccessibilityElement = false
        isUserInteractionEnabled = false
        layer.addSublayer(artLayer)

        [
            sunRaysLayer,
            sunCoreLayer,
            sunHighlightLayer,
            cloudBackLayer,
            cloudShadowLayer,
            cloudGradientLayer
        ].forEach(artLayer.addSublayer)
        particleLayers.forEach(artLayer.addSublayer)

        sunRaysLayer.fillColor = UIColor.clear.cgColor
        sunRaysLayer.lineCap = .round
        sunRaysLayer.lineJoin = .round
        cloudGradientLayer.startPoint = CGPoint(x: 0.28, y: 0.18)
        cloudGradientLayer.endPoint = CGPoint(x: 0.72, y: 0.88)
        cloudGradientLayer.mask = cloudMaskLayer
        particleLayers.forEach {
            $0.fillColor = UIColor.clear.cgColor
            $0.lineCap = .round
            $0.lineJoin = .round
        }
        configureArtwork()
    }

    private func configureArtwork() {
        guard !artLayer.bounds.isEmpty else { return }
        let usesSun = condition == .clear || condition == .cloud
        let usesCloud = condition != .clear
        sunRaysLayer.isHidden = !usesSun
        sunCoreLayer.isHidden = !usesSun
        sunHighlightLayer.isHidden = !usesSun
        cloudBackLayer.isHidden = !usesCloud
        cloudShadowLayer.isHidden = !usesCloud
        cloudGradientLayer.isHidden = !usesCloud

        let sunCenter = condition == .clear ? CGPoint(x: 53, y: 50) : CGPoint(x: 35, y: 35)
        let sunRadius: CGFloat = condition == .clear ? 22 : 13
        configureSun(center: sunCenter, radius: sunRadius)

        let cloudPath = makeCloudPath()
        cloudBackLayer.path = makeCloudPath(offsetX: 5, offsetY: -5, scale: 0.9).cgPath
        cloudShadowLayer.path = cloudPath.cgPath
        cloudShadowLayer.setAffineTransform(CGAffineTransform(translationX: 0, y: 2.2))
        cloudMaskLayer.path = cloudPath.cgPath
        cloudGradientLayer.frame = artLayer.bounds
        cloudMaskLayer.frame = cloudGradientLayer.bounds

        configureParticles()
        updateColors()
    }

    private func configureSun(center: CGPoint, radius: CGFloat) {
        let rays = UIBezierPath()
        let inner = radius + (condition == .clear ? 7 : 4.5)
        let outer = inner + (condition == .clear ? 7 : 4)
        for index in 0..<8 {
            let angle = CGFloat(index) * .pi / 4
            rays.move(to: CGPoint(
                x: center.x + cos(angle) * inner,
                y: center.y + sin(angle) * inner
            ))
            rays.addLine(to: CGPoint(
                x: center.x + cos(angle) * outer,
                y: center.y + sin(angle) * outer
            ))
        }
        sunRaysLayer.path = rays.cgPath
        sunRaysLayer.lineWidth = condition == .clear ? 4.2 : 3

        sunCoreLayer.path = UIBezierPath(
            ovalIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
        ).cgPath
        let highlightRadius = radius * 0.22
        sunHighlightLayer.path = UIBezierPath(
            ovalIn: CGRect(
                x: center.x - radius * 0.28 - highlightRadius,
                y: center.y - radius * 0.32 - highlightRadius,
                width: highlightRadius * 2,
                height: highlightRadius * 2
            )
        ).cgPath
    }

    private func makeCloudPath(
        offsetX: CGFloat = 0,
        offsetY: CGFloat = 0,
        scale: CGFloat = 1
    ) -> UIBezierPath {
        func x(_ value: CGFloat) -> CGFloat { 50 + (value - 50) * scale + offsetX }
        func y(_ value: CGFloat) -> CGFloat { 53 + (value - 53) * scale + offsetY }
        func size(_ value: CGFloat) -> CGFloat { value * scale }

        let path = UIBezierPath()
        path.append(UIBezierPath(
            ovalIn: CGRect(x: x(35) - size(17), y: y(54) - size(17), width: size(34), height: size(34))
        ))
        path.append(UIBezierPath(
            ovalIn: CGRect(x: x(55) - size(22), y: y(43) - size(22), width: size(44), height: size(44))
        ))
        path.append(UIBezierPath(
            ovalIn: CGRect(x: x(75) - size(15), y: y(56) - size(15), width: size(30), height: size(30))
        ))
        path.append(UIBezierPath(
            roundedRect: CGRect(x: x(18), y: y(52), width: x(90) - x(18), height: y(75) - y(52)),
            cornerRadius: size(11.5)
        ))
        return path
    }

    private func configureParticles() {
        let positions: [CGFloat] = [31, 46, 61, 76]
        for (index, particleLayer) in particleLayers.enumerated() {
            let isVisible = switch condition {
            case .rain, .sleet, .snow: true
            default: false
            }
            particleLayer.isHidden = !isVisible
            guard isVisible else { continue }

            let isSnowParticle = condition == .snow || (condition == .sleet && index.isMultiple(of: 2))
            let path = UIBezierPath()
            if isSnowParticle {
                let radius: CGFloat = index.isMultiple(of: 2) ? 3.2 : 2.6
                path.move(to: CGPoint(x: positions[index] - radius, y: 79))
                path.addLine(to: CGPoint(x: positions[index] + radius, y: 79))
                path.move(to: CGPoint(x: positions[index], y: 79 - radius))
                path.addLine(to: CGPoint(x: positions[index], y: 79 + radius))
                particleLayer.lineWidth = 1.9
            } else {
                path.move(to: CGPoint(x: positions[index] + 2, y: 76))
                path.addLine(to: CGPoint(x: positions[index] - 1.5, y: 82.5))
                particleLayer.lineWidth = 3.6
            }
            particleLayer.path = path.cgPath
        }
    }

    private func updateColors() {
        let palette = palette()
        sunRaysLayer.strokeColor = palette.sunRay.cgColor
        sunCoreLayer.fillColor = palette.sunCore.cgColor
        sunCoreLayer.shadowColor = palette.sunEdge.cgColor
        sunCoreLayer.shadowOpacity = 0.34
        sunCoreLayer.shadowRadius = 5
        sunCoreLayer.shadowOffset = CGSize(width: 0, height: 2)
        sunHighlightLayer.fillColor = UIColor.white.withAlphaComponent(0.38).cgColor
        cloudBackLayer.fillColor = palette.cloudBack.cgColor
        cloudShadowLayer.fillColor = palette.shadow.cgColor
        cloudGradientLayer.colors = [palette.cloudFrontTop.cgColor, palette.cloudFrontBottom.cgColor]

        for (index, particleLayer) in particleLayers.enumerated() {
            let isSnowParticle = condition == .snow || (condition == .sleet && index.isMultiple(of: 2))
            particleLayer.strokeColor = (isSnowParticle ? palette.snow : palette.rain).cgColor
        }
    }

    private func palette() -> Palette {
        if traitCollection.userInterfaceStyle == .dark {
            return Palette(
                sunCore: UIColor(red: 1, green: 0.855, blue: 0.388, alpha: 1),
                sunEdge: UIColor(red: 1, green: 0.631, blue: 0.188, alpha: 1),
                sunRay: UIColor(red: 1, green: 0.722, blue: 0.251, alpha: 1),
                cloudBack: UIColor(red: 0.314, green: 0.545, blue: 0.761, alpha: 1),
                cloudFrontTop: UIColor(red: 0.812, green: 0.902, blue: 0.976, alpha: 1),
                cloudFrontBottom: UIColor(red: 0.561, green: 0.706, blue: 0.827, alpha: 1),
                rain: UIColor(red: 0.329, green: 0.788, blue: 1, alpha: 1),
                snow: UIColor(red: 0.745, green: 0.937, blue: 1, alpha: 1),
                shadow: UIColor(red: 0, green: 0.078, blue: 0.141, alpha: 0.28)
            )
        }
        return Palette(
            sunCore: UIColor(red: 1, green: 0.867, blue: 0.396, alpha: 1),
            sunEdge: UIColor(red: 1, green: 0.631, blue: 0.137, alpha: 1),
            sunRay: UIColor(red: 1, green: 0.682, blue: 0.165, alpha: 1),
            cloudBack: UIColor(red: 0.4, green: 0.682, blue: 0.937, alpha: 1),
            cloudFrontTop: UIColor(red: 0.945, green: 0.973, blue: 1, alpha: 1),
            cloudFrontBottom: UIColor(red: 0.706, green: 0.835, blue: 0.941, alpha: 1),
            rain: UIColor(red: 0.11, green: 0.659, blue: 0.91, alpha: 1),
            snow: UIColor(red: 0.259, green: 0.706, blue: 0.898, alpha: 1),
            shadow: UIColor(red: 0.047, green: 0.204, blue: 0.322, alpha: 0.12)
        )
    }

    private func updateAnimationState() {
        stopAnimating()
        guard window != nil, !isHidden, !UIAccessibility.isReduceMotionEnabled else { return }

        let floatingAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        floatingAnimation.values = [-1.35, 1.35, -1.35]
        floatingAnimation.keyTimes = [0, 0.5, 1]
        floatingAnimation.duration = 3.6
        floatingAnimation.repeatCount = .infinity
        floatingAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        artLayer.add(floatingAnimation, forKey: "weather.float")

        let sunPulse = CABasicAnimation(keyPath: "opacity")
        sunPulse.fromValue = 0.72
        sunPulse.toValue = 1
        sunPulse.duration = 1.8
        sunPulse.autoreverses = true
        sunPulse.repeatCount = .infinity
        sunRaysLayer.add(sunPulse, forKey: "weather.sunPulse")

        let baseTime = CACurrentMediaTime()
        for (index, particleLayer) in particleLayers.enumerated() where !particleLayer.isHidden {
            let isSnowParticle = condition == .snow || (condition == .sleet && index.isMultiple(of: 2))
            let duration = isSnowParticle ? 2.6 : 1.2

            let fall = CABasicAnimation(keyPath: "transform.translation.y")
            fall.fromValue = -2
            fall.toValue = isSnowParticle ? 12 : 10
            fall.duration = duration
            fall.repeatCount = .infinity
            fall.beginTime = baseTime + Double(index) * duration * 0.23
            particleLayer.add(fall, forKey: "weather.fall")

            let fade = CAKeyframeAnimation(keyPath: "opacity")
            fade.values = [0, 1, 1, 0]
            fade.keyTimes = [0, 0.22, 0.72, 1]
            fade.duration = duration
            fade.repeatCount = .infinity
            fade.beginTime = fall.beginTime
            particleLayer.add(fade, forKey: "weather.fade")
        }
    }

    private func stopAnimating() {
        artLayer.removeAllAnimations()
        sunRaysLayer.removeAllAnimations()
        particleLayers.forEach { $0.removeAllAnimations() }
    }
}

final class TodayHomeVC: UIViewController { // swiftlint:disable:this type_body_length
    private static let autoRefreshIntervalSeconds = 60
    private static let departureSwitchHysteresisMeters: CLLocationDistance = 75
    private static let subwayMinimumTransferMinutes = 5
    private static let chojiMinimumTransferMinutes = 8
    private static let shuttleDisplayCount = 2
    private static let shuttleTransferLookaheadCount = 3
    private static let selectorTitleFontSize: CGFloat = 18

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let destinationControl = UISegmentedControl()
    private let noticeContainer = UIView()
    private let noticeView = NoticeCarouselView()
    private lazy var locationManager = CLLocationManager().then {
        $0.delegate = self
        $0.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    private let movementCard = UIStackView()
    private let movementStateRow = UIStackView()
    private let movementStateLabel = UILabel()
    private lazy var departureSelectorButton = UIButton(type: .system).then {
        $0.showsMenuAsPrimaryAction = true
        $0.titleLabel?.adjustsFontSizeToFitWidth = true
        $0.titleLabel?.minimumScaleFactor = 0.75
        $0.titleLabel?.lineBreakMode = .byTruncatingTail
        $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        $0.accessibilityLabel = String(localized: "home.movement.departure.selector")
    }
    private let presenceStatusPill = UIView().then {
        $0.backgroundColor = .homeActionButtonBackground
        $0.layer.cornerRadius = 15
        $0.isAccessibilityElement = true
        $0.accessibilityTraits = .staticText
        $0.isHidden = true
    }

    private let presenceStatusIconView = UIImageView().then {
        $0.image = UIImage(systemName: "person.2.fill")
        $0.tintColor = .hanyangBlue
        $0.contentMode = .scaleAspectFit
        $0.isAccessibilityElement = false
    }

    private let presenceStatusLabel = UILabel().then {
        $0.textColor = .hanyangBlue
        $0.font = .godo(size: 12, weight: .bold)
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.75
        $0.lineBreakMode = .byTruncatingTail
    }

    private lazy var presenceStatusRow = UIStackView(arrangedSubviews: [presenceStatusIconView, presenceStatusLabel]).then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 4
    }

    private let shuttleOptionStack = UIStackView()
    private let supportingOptionStack = UIStackView()
    private let cafeteriaCard = UIStackView()
    private let cafeteriaIconView = UIImageView()
    private lazy var cafeteriaPeriodSelectorButton = UIButton(type: .system).then {
        $0.showsMenuAsPrimaryAction = true
        $0.titleLabel?.adjustsFontSizeToFitWidth = true
        $0.titleLabel?.minimumScaleFactor = 0.75
        $0.titleLabel?.lineBreakMode = .byTruncatingTail
        $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        $0.accessibilityLabel = String(localized: "home.meal.period.selector")
    }
    private let mealStack = UIStackView()
    private let refreshControl = UIRefreshControl()
    private let homeHeroTitleLabel = UILabel()
    private let homeHeroSubtitleLabel = UILabel()
    private let homeWeatherIconView = HomeWeatherIconView()
    private var homeWeatherIconSizeConstraints: [NSLayoutConstraint] = []
    private var homeWeatherTextTrailingConstraints: [NSLayoutConstraint] = []
    private lazy var legacyBar = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.borderWidth = 1 / UIScreen.main.scale
        $0.layer.borderColor = UIColor.separator.cgColor
    }

    private lazy var legacyBarLabel = UILabel().then {
        $0.text = String(localized: "home.quick_settings.action_bar.title")
        $0.textColor = .secondaryLabel
        $0.font = .godo(size: 13, weight: .bold)
    }

    private lazy var legacyButton = UIButton(type: .system).then {
        var config = UIButton.Configuration.plain()
        config.background.backgroundColor = .homeActionButtonBackground
        config.baseForegroundColor = .hanyangBlue
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "slider.horizontal.3")?.withConfiguration(UIImage.SymbolConfiguration(
            pointSize: 16,
            weight: .semibold
        ))
        config.attributedTitle = AttributedString(String(localized: "home.quick_settings.button"), attributes: AttributeContainer([
            .font: UIFont.godo(size: 14, weight: .bold)
        ]))
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 12)
        $0.configuration = config
        $0.addTarget(self, action: #selector(openQuickSettings), for: .touchUpInside)
        $0.accessibilityLabel = String(localized: "home.quick_settings.title")
        $0.accessibilityIdentifier = "home.quick_settings"
    }

    private var selectedDeparture: HomeDeparture = .dormitory
    private var hasResolvedInitialDepartureLocation = false
    private var isDepartureManuallySelected = false
    private var shouldRestoreAutomaticDepartureOnActivation = false
    private var selectedDestination: HomeDestination = .station
    private var availableDestinations: [HomeDestination] {
        selectedDeparture.destinations
    }

    private var shuttleData: HomePageQuery.Data?
    private var busAlternatives: [String: [HomeTransitOption]] = [:]
    private var bus50TerminalLogTimes: [LocalTime] = []
    private var mealSections: [HomeMealSection] = []
    private var displayedMealPeriod: HomeMealPeriod?
    private var isMealPeriodManuallySelected = false
    private var isLoading = false
    private var autoRefreshSubscription: Disposable?
    private var presenceSubscription: Disposable?
    #if DEBUG
        private var usesDebugDeparture = false
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        #if DEBUG
            applyDebugRouteOverride()
        #endif
        updateDestinationControl()
        updateDepartureSelector()
        updateMealPeriodSelector()
        observeApplicationActivation()
        refreshHomeContext()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let iconSize: CGFloat = view.bounds.width <= 375 ? 88 : 96
        homeWeatherIconSizeConstraints.forEach { constraint in
            if constraint.constant != iconSize {
                constraint.constant = iconSize
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.home)
        startPresenceUpdates()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        startAutoRefresh()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoRefresh()
        stopPresenceUpdates()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        navigationItem.title = String(localized: "home.title.today")

        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        view.addSubview(scrollView)
        view.addSubview(legacyBar)
        legacyBar.addSubview(legacyBarLabel)
        legacyBar.addSubview(legacyButton)
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(legacyBar.snp.top)
        }
        legacyBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(54)
        }
        legacyBarLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        legacyButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
        }

        scrollView.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 30, right: 16)
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        contentStack.addArrangedSubview(makeHeaderView())
        contentStack.addArrangedSubview(makeNoticeView())
        contentStack.addArrangedSubview(makeDestinationControlView())
        contentStack.addArrangedSubview(makeMovementCard())
        contentStack.addArrangedSubview(makeCafeteriaCard())
        renderLoadingState()
    }

    private func makeHeaderView() -> UIView {
        let container = UIView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12

        let topRow = UIStackView()
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 10

        let eyebrow = UILabel()
        eyebrow.text = formattedToday()
        eyebrow.font = .godo(size: 13, weight: .regular)
        eyebrow.textColor = .secondaryLabel

        topRow.addArrangedSubview(eyebrow)
        topRow.addArrangedSubview(UIView())

        homeHeroTitleLabel.text = String(localized: "home.hero.title")
        homeHeroTitleLabel.font = .godo(size: 28, weight: .bold)
        homeHeroTitleLabel.textColor = .label
        homeHeroTitleLabel.numberOfLines = 0

        homeHeroSubtitleLabel.text = String(localized: "home.hero.subtitle")
        homeHeroSubtitleLabel.font = .godo(size: 15, weight: .regular)
        homeHeroSubtitleLabel.textColor = .secondaryLabel
        homeHeroSubtitleLabel.numberOfLines = 0

        homeWeatherIconView.isHidden = true
        homeWeatherIconView.isAccessibilityElement = false

        let titleRow = UIView()
        titleRow.addSubview(homeHeroTitleLabel)
        let subtitleRow = UIView()
        subtitleRow.addSubview(homeHeroSubtitleLabel)

        stack.addArrangedSubview(topRow)
        stack.addArrangedSubview(titleRow)
        stack.addArrangedSubview(subtitleRow)
        stack.setCustomSpacing(16, after: topRow)
        stack.setCustomSpacing(4, after: titleRow)
        container.addSubview(homeWeatherIconView)
        container.addSubview(stack)

        stack.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
        }
        homeHeroTitleLabel.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        homeHeroSubtitleLabel.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        homeWeatherIconView.translatesAutoresizingMaskIntoConstraints = false
        let initialIconSize: CGFloat = view.bounds.width <= 375 ? 88 : 96
        homeWeatherIconSizeConstraints = [
            homeWeatherIconView.widthAnchor.constraint(equalToConstant: initialIconSize),
            homeWeatherIconView.heightAnchor.constraint(equalToConstant: initialIconSize)
        ]
        NSLayoutConstraint.activate(homeWeatherIconSizeConstraints + [
            homeWeatherIconView.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor),
            homeWeatherIconView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            homeWeatherIconView.bottomAnchor.constraint(equalTo: homeHeroSubtitleLabel.bottomAnchor)
        ])

        // The artwork starts about 16% inside its canvas. Allowing text 3pt into
        // that transparent area keeps about 12pt of visible space on compact screens.
        homeWeatherTextTrailingConstraints = [
            homeHeroTitleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: homeWeatherIconView.leadingAnchor,
                constant: 3
            ),
            homeHeroSubtitleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: homeWeatherIconView.leadingAnchor,
                constant: 3
            )
        ]
        return container
    }

    private func makeDestinationControlView() -> UIView {
        destinationControl.setTitleTextAttributes([
            .font: UIFont.godo(size: 13, weight: .regular)
        ], for: .normal)
        destinationControl.setTitleTextAttributes([
            .font: UIFont.godo(size: 13, weight: .bold)
        ], for: .selected)
        destinationControl.addTarget(self, action: #selector(destinationChanged), for: .valueChanged)

        return destinationControl
    }

    private func makeNoticeView() -> UIView {
        noticeContainer.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .secondarySystemGroupedBackground : .hanyangBlue
        }
        noticeContainer.layer.cornerRadius = 20
        noticeContainer.layer.masksToBounds = true
        noticeContainer.isHidden = true
        noticeView.titleColor = .white
        noticeView.onNoticeTapped = { [weak self] urlString in
            guard let url = URL(string: urlString) else { return }
            self?.present(NoticeWebVC(url: url), animated: true)
        }
        noticeContainer.addSubview(noticeView)
        noticeView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        noticeContainer.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        return noticeContainer
    }

    private func makeMovementCard() -> UIView {
        let card = cardView()
        movementCard.axis = .vertical
        movementCard.spacing = 14
        movementCard.layoutMargins = UIEdgeInsets(top: 18, left: 16, bottom: 16, right: 16)
        movementCard.isLayoutMarginsRelativeArrangement = true

        let header = makeMovementHeader()
        movementStateLabel.font = .godo(size: 15, weight: .regular)
        movementStateLabel.textColor = .secondaryLabel
        movementStateLabel.numberOfLines = 0
        movementStateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        movementStateRow.axis = .horizontal
        movementStateRow.alignment = .center
        movementStateRow.spacing = 10
        movementStateRow.addArrangedSubview(movementStateLabel)
        movementStateRow.addArrangedSubview(UIView())
        movementStateRow.addArrangedSubview(presenceStatusPill)
        presenceStatusPill.addSubview(presenceStatusRow)
        presenceStatusIconView.snp.makeConstraints { make in
            make.width.equalTo(15)
            make.height.equalTo(12)
        }
        presenceStatusPill.snp.makeConstraints { make in
            make.height.equalTo(30)
        }
        presenceStatusRow.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
        }

        shuttleOptionStack.axis = .vertical
        shuttleOptionStack.spacing = 10
        supportingOptionStack.axis = .vertical
        supportingOptionStack.spacing = 8

        movementCard.addArrangedSubview(header)
        movementCard.addArrangedSubview(movementStateRow)
        movementCard.addArrangedSubview(shuttleOptionStack)
        movementCard.addArrangedSubview(supportingOptionStack)

        card.addSubview(movementCard)
        movementCard.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return card
    }

    private func makeMovementHeader() -> UIView {
        let header = UIStackView()
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 10

        let imageView = UIImageView(image: UIImage(systemName: "bus.fill"))
        imageView.tintColor = .homeSelectorIconTint
        imageView.contentMode = .scaleAspectFit
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(22)
        }

        departureSelectorButton.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(44)
        }

        header.addArrangedSubview(imageView)
        header.addArrangedSubview(departureSelectorButton)
        header.addArrangedSubview(UIView())
        header.addArrangedSubview(makeHeaderButton(
            title: String(localized: "home.movement.timetable"),
            action: #selector(openShuttleTimetable),
            showsChevron: true
        ))
        return header
    }

    private func makeCafeteriaCard() -> UIView {
        let card = cardView()
        cafeteriaCard.axis = .vertical
        cafeteriaCard.spacing = 12
        cafeteriaCard.layoutMargins = UIEdgeInsets(top: 18, left: 16, bottom: 16, right: 16)
        cafeteriaCard.isLayoutMarginsRelativeArrangement = true

        cafeteriaCard.addArrangedSubview(makeCafeteriaHeader())

        mealStack.axis = .vertical
        mealStack.spacing = 10
        cafeteriaCard.addArrangedSubview(mealStack)

        card.addSubview(cafeteriaCard)
        cafeteriaCard.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return card
    }

    private func makeCafeteriaHeader() -> UIView {
        let header = UIStackView()
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 10

        cafeteriaIconView.tintColor = .homeSelectorIconTint
        cafeteriaIconView.contentMode = .scaleAspectFit
        cafeteriaIconView.snp.makeConstraints { make in
            make.width.height.equalTo(22)
        }
        cafeteriaPeriodSelectorButton.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(44)
        }

        header.addArrangedSubview(cafeteriaIconView)
        header.addArrangedSubview(cafeteriaPeriodSelectorButton)
        header.addArrangedSubview(UIView())
        header.addArrangedSubview(makeHeaderButton(
            title: String(localized: "home.cafeteria.detail"),
            action: #selector(openCafeteria),
            showsChevron: true
        ))
        return header
    }

    private func makeSectionHeader(
        icon: String,
        iconView providedIconView: UIImageView? = nil,
        title: String,
        titleLabel providedTitleLabel: UILabel? = nil,
        buttonTitle: String? = nil,
        action: Selector? = nil,
        showsChevron: Bool = true
    ) -> UIView {
        let titleRow = UIStackView()
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 10

        let imageView = providedIconView ?? UIImageView()
        imageView.image = UIImage(systemName: icon)
        imageView.tintColor = .hanyangBlue
        imageView.contentMode = .scaleAspectFit
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(22)
        }

        let label = providedTitleLabel ?? UILabel()
        label.text = title
        label.font = .godo(size: 20, weight: .bold)
        label.textColor = .label

        titleRow.addArrangedSubview(imageView)
        titleRow.addArrangedSubview(label)
        titleRow.addArrangedSubview(UIView())
        if let buttonTitle, let action {
            titleRow.addArrangedSubview(makeHeaderButton(
                title: buttonTitle,
                action: action,
                showsChevron: showsChevron
            ))
        }
        return titleRow
    }

    private func makeHeaderButton(title: String, action: Selector, showsChevron: Bool) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .plainButtonText
        config.attributedTitle = AttributedString(title, attributes: AttributeContainer([
            .font: UIFont.godo(size: 13, weight: .bold)
        ]))
        if showsChevron {
            config.image = UIImage(systemName: "chevron.right")?.withConfiguration(UIImage.SymbolConfiguration(
                pointSize: 13,
                weight: .bold
            ))
            config.imagePlacement = .trailing
            config.imagePadding = 3
        }
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
        button.configuration = config
        button.addTarget(self, action: action, for: .touchUpInside)
        button.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(44)
        }
        return button
    }

    private func cardView() -> UIView {
        UIView().then {
            $0.backgroundColor = .secondarySystemGroupedBackground
            $0.layer.cornerRadius = 8
            $0.layer.borderWidth = 1
            $0.layer.borderColor = UIColor.separator.withAlphaComponent(0.35).cgColor
        }
    }

    private func renderLoadingState() {
        movementStateLabel.text = String(localized: "home.loading")
        updateDepartureSelector()
        updateMealPeriodSelector()
        replaceSubviews(in: shuttleOptionStack, with: [makeSkeletonRow(widthRatio: 0.72), makeSkeletonRow(widthRatio: 0.54)])
        replaceSubviews(in: supportingOptionStack, with: [])
        replaceSubviews(in: mealStack, with: [makeSkeletonRow(widthRatio: 0.82), makeSkeletonRow(widthRatio: 0.64)])
    }

    private func render() {
        renderWeather()
        renderNotices()
        renderMovement()
        renderMeals()
    }

    private func renderWeather() {
        #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if let condition = argumentValue(named: "-homeWeatherPreview", in: arguments)?.uppercased() {
                renderWeather(
                    condition: condition,
                    currentTemperature: 28,
                    minimumTemperature: 23,
                    maximumTemperature: 31,
                    precipitationProbabilityMax: 70,
                    precipitationType: condition == "RAIN" ? "RAIN" : "NONE"
                )
                return
            }
        #endif
        guard let weather = shuttleData?.homeWeather else {
            homeHeroTitleLabel.text = String(localized: "home.hero.title")
            homeHeroSubtitleLabel.text = String(localized: "home.hero.subtitle")
            setHomeWeatherIconHidden(true)
            return
        }

        renderWeather(
            condition: weather.primaryCondition,
            currentTemperature: weather.currentTemperature,
            minimumTemperature: weather.minimumTemperature,
            maximumTemperature: weather.maximumTemperature,
            precipitationProbabilityMax: weather.precipitationProbabilityMax,
            precipitationType: weather.precipitationType
        )
    }

    private func renderWeather(
        condition: String,
        currentTemperature: Double?,
        minimumTemperature: Double?,
        maximumTemperature: Double?,
        precipitationProbabilityMax: Int,
        precipitationType: String
    ) {
        let titleKey: String.LocalizationValue = if condition == "RAIN" {
            "home.weather.rain.title"
        } else if condition == "SLEET" {
            "home.weather.sleet.title"
        } else if condition == "SNOW" {
            "home.weather.snow.title"
        } else if let maximumTemperature, maximumTemperature >= 32 {
            "home.weather.hot.title"
        } else if let currentTemperature, currentTemperature <= -5 {
            "home.weather.cold.title"
        } else if condition == "CLEAR" {
            "home.weather.clear.title"
        } else {
            "home.weather.cloudy.title"
        }

        homeHeroTitleLabel.text = String(localized: titleKey)
        homeWeatherIconView.setWeatherCondition(condition)
        setHomeWeatherIconHidden(false)

        if let minimumTemperature, let maximumTemperature {
            if precipitationType != "NONE" {
                homeHeroSubtitleLabel.text = String(
                    format: String(localized: "home.weather.precipitation.subtitle"),
                    locale: Locale.current,
                    precipitationProbabilityMax,
                    minimumTemperature,
                    maximumTemperature
                )
            } else if let currentTemperature {
                homeHeroSubtitleLabel.text = String(
                    format: String(localized: "home.weather.temperature.subtitle"),
                    locale: Locale.current,
                    currentTemperature,
                    minimumTemperature,
                    maximumTemperature
                )
            } else {
                homeHeroSubtitleLabel.text = String(localized: "home.hero.subtitle")
            }
        } else {
            homeHeroSubtitleLabel.text = String(localized: "home.hero.subtitle")
        }
    }

    private func setHomeWeatherIconHidden(_ isHidden: Bool) {
        homeWeatherTextTrailingConstraints.forEach { $0.isActive = !isHidden }
        homeWeatherIconView.isHidden = isHidden
    }

    private func renderNotices() {
        let notices = shuttleData?.notices.flatMap(\.notices).map {
            Notice(title: $0.title, url: $0.url)
        } ?? []
        noticeContainer.isHidden = notices.isEmpty
        if notices.isEmpty {
            noticeView.stopAutoScroll()
        } else {
            noticeView.setupUI(with: notices)
        }
    }

    private func renderMovement() {
        let options = movementOptions(for: selectedDestination)
        let shuttleOptions = options.filter { $0.kind == .shuttle }
        let supportOptions = options.filter { $0.kind != .shuttle }
        let nextShuttleMinutes = shuttleOptions.first?.minutes
        let shouldEmphasizeSupport = nextShuttleMinutes.map { $0 > 20 } ?? true

        movementStateLabel.text = String(
            format: String(localized: "home.movement.destination.summary"),
            selectedDestination.title
        )
        updateDepartureSelector()
        if shuttleOptions.isEmpty {
            replaceSubviews(in: shuttleOptionStack, with: [
                makeEmptyView(
                    title: String(localized: "home.empty.shuttle.title"),
                    message: String(localized: "home.empty.shuttle.message")
                )
            ])
        } else {
            replaceSubviews(in: shuttleOptionStack, with: shuttleTransferPairViews(for: Array(shuttleOptions.prefix(2))))
        }

        let supportHeader = UILabel()
        supportHeader.font = .godo(size: 13, weight: .bold)
        supportHeader.textColor = shouldEmphasizeSupport ? .label : .secondaryLabel
        supportHeader
            .text = shouldEmphasizeSupport ? String(localized: "home.support.emphasized") : String(localized: "home.support.default")

        let rows = supportOptions.prefix(shouldEmphasizeSupport ? 4 : 2).map { makeTransitRow($0, emphasized: true) }
        replaceSubviews(in: supportingOptionStack, with: rows.isEmpty ? [] : [supportHeader] + rows)
    }

    private var presencePreviewCount: Int? {
        #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            return arguments.firstIndex(of: "-shuttlePresencePreview").flatMap { index in
                arguments.indices.contains(index + 1) ? Int(arguments[index + 1]) : nil
            }
        #else
            return nil
        #endif
    }

    private var currentPresenceStopID: String {
        selectedDeparture.presenceStopID(for: selectedDestination)
    }

    private func startPresenceUpdates() {
        stopPresenceUpdates()
        guard ShuttlePresenceSettings.showsStatus else { return }
        refreshPresenceStatus()
        guard presencePreviewCount == nil else { return }
        presenceSubscription = Observable<Int>.interval(.seconds(30), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in self?.reportPresence() })
    }

    private func stopPresenceUpdates() {
        presenceSubscription?.dispose()
        presenceSubscription = nil
        updatePresenceStatus(viewerCount: nil)
    }

    private func refreshPresenceStatus() {
        if let presencePreviewCount {
            updatePresenceStatus(viewerCount: presencePreviewCount)
        } else {
            updatePresenceStatus(viewerCount: nil)
            reportPresence()
        }
    }

    private func reportPresence() {
        guard ShuttlePresenceSettings.showsStatus, view.window != nil else { return }
        let requestedStopID = currentPresenceStopID
        Task { [weak self] in
            let count = await ShuttlePresenceService.shared.heartbeat(stopId: requestedStopID)
            await MainActor.run {
                guard let self, self.currentPresenceStopID == requestedStopID else { return }
                self.updatePresenceStatus(viewerCount: count)
            }
        }
    }

    private func updatePresenceStatus(viewerCount: Int?) {
        guard ShuttlePresenceSettings.showsStatus, let viewerCount else {
            presenceStatusLabel.text = nil
            presenceStatusPill.accessibilityLabel = nil
            presenceStatusPill.isHidden = true
            return
        }
        presenceStatusLabel.text = viewerCount.formatted()
        presenceStatusPill.accessibilityLabel = String(
            format: String(localized: "shuttle.presence.viewer.count"),
            locale: Locale.current,
            viewerCount
        )
        presenceStatusPill.isHidden = false
    }

    private func applyShowPresenceStatus(_ isOn: Bool) {
        ShuttlePresenceSettings.showsStatus = isOn
        if isOn {
            startPresenceUpdates()
        } else {
            stopPresenceUpdates()
        }
    }

    private func renderMeals() {
        let mealPeriod = activeMealPeriod()
        cafeteriaIconView.image = UIImage(systemName: mealPeriod.iconName)
        updateMealPeriodSelector()
        if mealSections.isEmpty {
            replaceSubviews(in: mealStack, with: [
                makeEmptyView(
                    title: String(format: String(localized: "home.empty.meal.title"), currentMealTitle()),
                    message: String(localized: "home.empty.meal.message")
                )
            ])
            return
        }
        replaceSubviews(in: mealStack, with: mealSections.map(makeMealSection))
    }

    private func movementOptions(for destination: HomeDestination) -> [HomeTransitOption] {
        var options: [HomeTransitOption] = []
        if let route = shuttleRoute(from: selectedDeparture, to: destination) {
            options.append(contentsOf: shuttleOptions(
                stop: route.stop,
                destination: route.destination,
                routeFilter: route.routeFilter
            ))
        }

        switch (selectedDeparture, destination) {
        case (.dormitory, .station):
            options.append(contentsOf: busAlternatives["dormitory_station"] ?? [])
        case (.dormitory, .terminal):
            options.append(contentsOf: busAlternatives["dormitory_terminal"] ?? [])
        case (.dormitory, .jungang):
            options.append(contentsOf: busAlternatives["dormitory_jungang"] ?? [])
        case (.shuttlecock, .terminal):
            options.append(contentsOf: busAlternatives["shuttlecock_terminal"] ?? [])
        case (.shuttlecock, .jungang):
            options.append(contentsOf: busAlternatives["shuttlecock_jungang"] ?? [])
        case (.station, .dormitory):
            options.append(contentsOf: busAlternatives["station_dormitory"] ?? [])
        case (.terminal, .dormitory):
            options.append(contentsOf: busAlternatives["terminal_dormitory"] ?? [])
        case (.jungang, .dormitory):
            options.append(contentsOf: busAlternatives["jungang_dormitory"] ?? [])
        default:
            break
        }
        return options
    }

    private func shuttleOptions(
        stop stopName: String,
        destination: String,
        routeFilter: ((HomePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) -> Bool)? = nil
    ) -> [HomeTransitOption] {
        guard let stop = shuttleData?.shuttle.stops.first(where: { $0.name == stopName }) else { return [] }
        let candidates = shuttleCandidates(stop: stop, stopName: stopName, destination: destination, routeFilter: routeFilter)
        let transferCandidates = Array(candidates.prefix(Self.shuttleTransferLookaheadCount))
        let visibleCandidates = Array(transferCandidates.prefix(Self.shuttleDisplayCount))
        let connectionGroups = transferCandidates.map { transferConnections(from: stopName, to: destination, candidate: $0) }
        return visibleCandidates
            .enumerated()
            .map { index, candidate in
                let routeDisplay = shuttleRouteDisplay(stop: stopName, destination: destination, candidate: candidate)
                let summary = shuttleStopSummary(from: stopName, to: destination, candidate: candidate)
                let subtitle = if candidate.seq == transferCandidates.last?.seq {
                    String(format: String(localized: "home.shuttle.last_run.subtitle"), summary)
                } else {
                    summary
                }
                return HomeTransitOption(
                    kind: .shuttle,
                    title: String(format: String(localized: "home.shuttle.departure.title"), compactTime(candidate.time)),
                    subtitle: subtitle,
                    minutes: minutesUntil(candidate.time),
                    badge: routeDisplay.badge,
                    tintColor: routeDisplay.tintColor,
                    connections: displayableConnections(
                        at: index,
                        to: destination,
                        in: connectionGroups,
                        candidates: transferCandidates
                    )
                )
            }
    }

    private func displayableConnections(
        at index: Int,
        to destination: String,
        in connectionGroups: [[HomeTransferConnection]],
        candidates: [HomeShuttleCandidate]
    ) -> [HomeTransferConnection] {
        let connections = connectionGroups[index]
        guard let firstConnection = connections.first else { return [] }
        let laterCandidates = candidates.suffix(from: candidates.index(after: index))
        if laterCandidates.contains(where: {
            candidateCanCatchConnection(
                $0,
                destination: destination,
                arrivalDate: firstConnection.arrivalDate,
                minimumTransferMinutes: firstConnection.minimumTransferMinutes
            )
        }) {
            return []
        }
        return connections
    }

    private func candidateCanCatchConnection(
        _ candidate: HomeShuttleCandidate,
        destination: String,
        arrivalDate: Foundation.Date,
        minimumTransferMinutes: Int
    ) -> Bool {
        guard let transferArrival = candidateArrivalDate(candidate, for: destination) else {
            return false
        }
        return arrivalDate.timeIntervalSince(transferArrival) >= TimeInterval(minimumTransferMinutes * 60)
    }

    private func shuttleCandidates(
        stop: HomePageQuery.Data.Shuttle.Stop,
        stopName: String,
        destination: String,
        routeFilter: ((HomePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) -> Bool)?
    ) -> [HomeShuttleCandidate] {
        guard let group = stop.timetable.destination.first(where: { $0.destination == destination }) else { return [] }
        return group.entries
            .filter { routeFilter?($0) ?? true }
            .map(HomeShuttleCandidate.init(entry:))
    }

    private func transferConnections(
        from stopName: String,
        to destination: String,
        candidate: HomeShuttleCandidate
    ) -> [HomeTransferConnection] {
        if HomeSettings.showBus50Transfer,
           let busConnection = bus50TransferConnection(from: stopName, to: destination, candidate: candidate)
        {
            return [busConnection]
        }
        if HomeSettings.showSubwayTransfer {
            return subwayTransferConnection(from: stopName, to: destination, candidate: candidate)
        }
        return []
    }

    private func bus50TransferConnection(
        from stopName: String,
        to destination: String,
        candidate: HomeShuttleCandidate
    ) -> HomeTransferConnection? {
        guard destination == "TERMINAL",
              stopName == "dormitory_o" || stopName == "shuttlecock_o",
              let terminalArrival = candidate.stops.first(where: { $0.name == "terminal" })?.time.toLocalTimeOrNil()
        else { return nil }

        if let realtimeConnection = bus50RealtimeTransferConnection(after: terminalArrival) {
            return realtimeConnection
        }
        return bus50LogTransferConnection(after: terminalArrival)
    }

    private func bus50RealtimeTransferConnection(after terminalArrival: Foundation.Date) -> HomeTransferConnection? {
        let busArrivals = shuttleData?.transferBus
            .filter { $0.stop.seq == 216_000_759 }
            .flatMap(\.arrival)
            .compactMap { arrival -> (date: Foundation.Date, minutes: Int, stops: Int?)? in
                guard arrival.isRealtime, let minutes = arrival.minutes else { return nil }
                return (
                    Foundation.Date.now.addingTimeInterval(TimeInterval(minutes * 60)),
                    minutes,
                    arrival.stops
                )
            }
            .sorted { $0.date < $1.date } ?? []
        guard let busArrival = busArrivals.first(where: { $0.date >= terminalArrival }) else { return nil }

        let bufferMinutes = max(0, Int(floor(busArrival.date.timeIntervalSince(terminalArrival) / 60)))
        let arrivalText = busRealtimeArrivalText(stops: busArrival.stops, minutes: busArrival.minutes)
        return HomeTransferConnection(
            badge: String(localized: "home.transfer.bus50.badge"),
            title: bus50DestinationTitle(),
            subtitle: arrivalText,
            connectorTitle: String(localized: "home.transfer.bus50.connector"),
            connectorTravelMinutes: nil,
            trailing: transferWaitingText(bufferMinutes: bufferMinutes, travelMinutes: nil),
            tintColor: bufferMinutes >= 3 ? .hanyangGreen : .systemOrange,
            arrivalDate: busArrival.date,
            minimumTransferMinutes: 0
        )
    }

    private func bus50LogTransferConnection(after terminalArrival: Foundation.Date) -> HomeTransferConnection? {
        let logDates = bus50TerminalLogTimes
            .compactMap { $0.toLocalTimeOrNil() }
            .filter { $0 >= terminalArrival }
            .sorted()
        guard let busArrival = logDates.first else { return nil }

        let bufferMinutes = max(0, Int(floor(busArrival.timeIntervalSince(terminalArrival) / 60)))
        let arrivalText = arrivalClockText(busArrival, key: "home.transfer.bus50.log.arrival_record")
        return HomeTransferConnection(
            badge: String(localized: "home.transfer.bus50.badge"),
            title: bus50DestinationTitle(),
            subtitle: arrivalText,
            connectorTitle: String(localized: "home.transfer.bus50.connector"),
            connectorTravelMinutes: nil,
            trailing: transferWaitingText(bufferMinutes: bufferMinutes, travelMinutes: nil),
            tintColor: UIColor(named: "busGreen") ?? .systemGreen,
            arrivalDate: busArrival,
            minimumTransferMinutes: 0
        )
    }

    private func busRealtimeArrivalText(stops: Int?, minutes: Int) -> String {
        if let stops, stops > 0 {
            return String(
                format: String(localized: "home.transfer.bus50.realtime.stops"),
                locale: Locale.current,
                stops
            )
        }
        if stops == 0 {
            return String(localized: "home.transfer.realtime.arriving")
        }
        return String(
            format: String(localized: "home.transfer.realtime.minutes"),
            locale: Locale.current,
            minutes
        )
    }

    private func bus50DestinationTitle() -> String {
        String(
            format: String(localized: "subway.terminal.%@"),
            String(localized: "home.destination.gwangmyeong")
        )
    }

    private func transferWaitingText(bufferMinutes: Int, travelMinutes: Int?) -> String {
        let waitingMinutes = max(0, bufferMinutes - (travelMinutes ?? 0))
        guard waitingMinutes > 0 else {
            return String(localized: "home.transfer.wait.immediate")
        }
        return String(
            format: String(localized: "home.transfer.wait.minutes"),
            locale: Locale.current,
            waitingMinutes
        )
    }

    private func subwayArrivalText(_ arrival: HomeSubwayArrival) -> String {
        guard arrival.isRealtime else {
            return arrivalClockText(arrival.arrivalDate, key: "home.transfer.subway.timetable.arrival")
        }
        guard let stops = arrival.stops, stops > 0 else {
            return String(localized: "home.transfer.realtime.arriving")
        }

        let isKorean = (Locale.current.language.languageCode?.identifier ?? "ko").hasPrefix("ko")
        if isKorean, arrival.status == 3 {
            return String(
                format: String(localized: "home.transfer.subway.realtime.previous_departure"),
                locale: Locale.current,
                stops
            )
        }
        if isKorean,
           let location = arrival.location,
           !location.isEmpty,
           let status = subwayRealtimeStatusText(arrival.status)
        {
            return String(
                format: String(localized: "home.transfer.subway.realtime.status"),
                locale: Locale.current,
                stops,
                location,
                status
            )
        }
        return String(
            format: String(localized: "home.transfer.subway.realtime.stops"),
            locale: Locale.current,
            stops
        )
    }

    private func subwayRealtimeStatusText(_ status: Int?) -> String? {
        switch status {
        case 0:
            String(localized: "home.transfer.subway.status.entering")
        case 1:
            String(localized: "home.transfer.subway.status.arrived")
        case 2:
            String(localized: "home.transfer.subway.status.departed")
        default:
            nil
        }
    }

    private func arrivalClockText(_ date: Foundation.Date, key: String) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else {
            return compactTime(date)
        }
        return String(
            format: String(localized: String.LocalizationValue(key)),
            locale: Locale.current,
            hour,
            minute
        )
    }

    private func subwayTransferConnection(
        from stopName: String,
        to destination: String,
        candidate: HomeShuttleCandidate
    ) -> [HomeTransferConnection] {
        guard destination == "STATION",
              stopName == "dormitory_o" || stopName == "shuttlecock_o",
              let stationArrival = candidateArrivalDate(candidate, for: destination),
              let subwayConnections = bestSubwayConnections(after: stationArrival)
        else { return [] }

        return subwayConnections
    }

    private func bestSubwayConnections(after stationArrival: Foundation.Date) -> [HomeTransferConnection]? {
        switch HomeSettings.subwayTransferDestination {
        case .incheon:
            return bestIncheonSubwayConnections(after: stationArrival)
        case .sosa:
            return chojiTransferSubwayConnections(after: stationArrival)
                .min { lhs, rhs in
                    (lhs.last?.arrivalDate ?? .distantFuture) < (rhs.last?.arrivalDate ?? .distantFuture)
                }
        case .seoul, .suwonYongin, .oido:
            guard let subwayArrival = subwayArrivalOptions()
                .filter({ canTransfer(to: $0.arrivalDate, after: stationArrival) })
                .min(by: { $0.arrivalDate < $1.arrivalDate })
            else { return nil }
            return [subwayConnection(for: subwayArrival, after: stationArrival)]
        }
    }

    private func chojiTransferSubwayConnections(after stationArrival: Foundation.Date) -> [[HomeTransferConnection]] {
        let firstLegs = subwayArrivalOptions(for: .choji)
            .filter { canTransfer(to: $0.arrivalDate, after: stationArrival) }
        let secondLegs = subwayArrivalOptions(for: .sosaFromChoji)
        return firstLegs.compactMap { firstLeg in
            guard let secondLeg = secondLegs
                .filter({
                    canTransfer(
                        to: $0.arrivalDate,
                        after: firstLeg.arrivalDate,
                        minimumTransferMinutes: Self.chojiMinimumTransferMinutes
                    )
                })
                .min(by: { $0.arrivalDate < $1.arrivalDate })
            else { return nil }
            return [
                subwayConnection(for: firstLeg, after: stationArrival),
                subwayConnection(
                    for: secondLeg,
                    after: firstLeg.arrivalDate,
                    connectorKey: "home.transfer.subway.choji.connector",
                    connectorTravelMinutes: Self.chojiMinimumTransferMinutes,
                    minimumTransferMinutes: Self.chojiMinimumTransferMinutes
                )
            ]
        }
    }

    private func bestIncheonSubwayConnections(after stationArrival: Foundation.Date) -> [HomeTransferConnection]? {
        let direct = subwayArrivalOptions(for: .incheonDirect)
            .filter { canTransfer(to: $0.arrivalDate, after: stationArrival) }
            .map { [subwayConnection(for: $0, after: stationArrival)] }

        let transfer = oidoTransferSubwayConnections(after: stationArrival)
        return (direct + transfer)
            .min { lhs, rhs in
                (lhs.last?.arrivalDate ?? .distantFuture) < (rhs.last?.arrivalDate ?? .distantFuture)
            }
    }

    private func oidoTransferSubwayConnections(after stationArrival: Foundation.Date) -> [[HomeTransferConnection]] {
        let firstLegs = subwayArrivalOptions(for: .oido)
            .filter { canTransfer(to: $0.arrivalDate, after: stationArrival) }
        let secondLegs = subwayArrivalOptions(for: .incheonFromOido)
        return firstLegs.compactMap { firstLeg in
            guard let secondLeg = secondLegs
                .filter({ canTransfer(to: $0.arrivalDate, after: firstLeg.arrivalDate) })
                .min(by: { $0.arrivalDate < $1.arrivalDate })
            else { return nil }
            return [
                subwayConnection(for: firstLeg, after: stationArrival),
                subwayConnection(
                    for: secondLeg,
                    after: firstLeg.arrivalDate,
                    connectorKey: "home.transfer.subway.oido.connector",
                    connectorTravelMinutes: nil
                )
            ]
        }
    }

    private func subwayConnection(
        for subwayArrival: HomeSubwayArrival,
        after transferStartDate: Foundation.Date,
        connectorKey: String = "home.transfer.subway.connector",
        connectorTravelMinutes: Int? = TodayHomeVC.subwayMinimumTransferMinutes,
        minimumTransferMinutes: Int = TodayHomeVC.subwayMinimumTransferMinutes
    ) -> HomeTransferConnection {
        let bufferMinutes = max(0, Int(floor(subwayArrival.arrivalDate.timeIntervalSince(transferStartDate) / 60)))
        let terminal = localizedSubwayStationName(
            subwayArrival.terminalStationID,
            fallback: subwayArrival.terminalName
        )
        return HomeTransferConnection(
            badge: subwayArrival.lineBadge,
            title: String(format: String(localized: "subway.terminal.%@"), terminal),
            subtitle: subwayArrivalText(subwayArrival),
            connectorTitle: String(localized: String.LocalizationValue(connectorKey)),
            connectorTravelMinutes: connectorTravelMinutes,
            trailing: transferWaitingText(
                bufferMinutes: bufferMinutes,
                travelMinutes: connectorTravelMinutes
            ),
            tintColor: subwayArrival.tintColor,
            arrivalDate: subwayArrival.arrivalDate,
            minimumTransferMinutes: minimumTransferMinutes
        )
    }

    private func canTransfer(
        to arrivalDate: Foundation.Date,
        after previousArrivalDate: Foundation.Date,
        minimumTransferMinutes: Int = TodayHomeVC.subwayMinimumTransferMinutes
    ) -> Bool {
        arrivalDate.timeIntervalSince(previousArrivalDate) >= TimeInterval(minimumTransferMinutes * 60)
    }

    private func subwayArrivalOptions() -> [HomeSubwayArrival] {
        switch HomeSettings.subwayTransferDestination {
        case .seoul:
            subwayArrivalOptions(for: .seoul)
        case .suwonYongin:
            subwayArrivalOptions(for: .suwonYongin)
        case .incheon:
            subwayArrivalOptions(for: .incheonDirect)
        case .oido:
            subwayArrivalOptions(for: .oido)
        case .sosa:
            subwayArrivalOptions(for: .sosaFromChoji)
        }
    }

    private enum HomeSubwayRouteTarget {
        case seoul
        case suwonYongin
        case incheonDirect
        case incheonFromOido
        case sosaFromChoji
        case choji
        case oido
    }

    private func subwayArrivalOptions(for target: HomeSubwayRouteTarget) -> [HomeSubwayArrival] {
        let subwayList = shuttleData?.subway ?? []
        let line4 = subwayList.first { $0.stationID == "K449" }
        let suin = subwayList.first { $0.stationID == "K251" }
        let oidoSuin = subwayList.first { $0.stationID == "K258" }
        let chojiSeohae = subwayList.first { $0.stationID == "S26" }
        let blue = UIColor.subwaySkyblue
        let yellow = UIColor.homeSubwayYellow
        let green = UIColor.homeSubwaySeohae

        switch target {
        case .seoul:
            return subwayArrivalOptions(
                subway: line4,
                direction: "up",
                badge: String(localized: "subway.line4"),
                tintColor: blue
            )
        case .suwonYongin:
            return subwayArrivalOptions(
                subway: suin,
                direction: "up",
                badge: String(localized: "home.transfer.subway.suin_bundang.badge"),
                tintColor: yellow
            )
        case .incheonDirect:
            return subwayArrivalOptions(
                subway: suin,
                direction: "down",
                badge: String(localized: "home.transfer.subway.suin_bundang.badge"),
                tintColor: yellow
            ) { $0.terminal.stationID > "K258" && $0.terminal.stationID.hasPrefix("K2") }
        case .incheonFromOido:
            return subwayArrivalOptions(
                subway: oidoSuin,
                direction: "down",
                badge: String(localized: "home.transfer.subway.suin_bundang.badge"),
                tintColor: yellow
            ) { $0.terminal.stationID > "K258" && $0.terminal.stationID.hasPrefix("K2") }
        case .sosaFromChoji:
            return subwayTimetableOptions(
                subway: chojiSeohae,
                direction: "up",
                badge: String(localized: "home.transfer.subway.seohae.badge"),
                tintColor: green
            ) { $0.terminal.stationID <= "S16" && $0.terminal.stationID.hasPrefix("S") }
        case .choji:
            let line4Down = subwayArrivalOptions(
                subway: line4,
                direction: "down",
                badge: String(localized: "subway.line4"),
                tintColor: blue
            ) { $0.terminal.stationID >= "K452" && $0.terminal.stationID.hasPrefix("K4") }
            let suinDown = subwayArrivalOptions(
                subway: suin,
                direction: "down",
                badge: String(localized: "home.transfer.subway.suin_bundang.badge"),
                tintColor: yellow
            ) { $0.terminal.stationID >= "K254" && $0.terminal.stationID.hasPrefix("K2") }
            return line4Down + suinDown
        case .oido:
            let line4Down = subwayArrivalOptions(
                subway: line4,
                direction: "down",
                badge: String(localized: "subway.line4"),
                tintColor: blue
            ) { $0.terminal.stationID == "K456" }
            let suinDown = subwayArrivalOptions(
                subway: suin,
                direction: "down",
                badge: String(localized: "home.transfer.subway.suin_bundang.badge"),
                tintColor: yellow
            ) { $0.terminal.stationID >= "K258" && $0.terminal.stationID.hasPrefix("K2") }
            return line4Down + suinDown
        }
    }

    private func subwayArrivalOptions(
        subway: HomePageQuery.Data.Subway?,
        direction: String,
        badge: String,
        tintColor: UIColor,
        isEligible: (HomePageQuery.Data.Subway.Arrival.Entry) -> Bool = { _ in true }
    ) -> [HomeSubwayArrival] {
        subway?.arrival
            .first { $0.direction == direction }?
            .entries
            .filter(isEligible)
            .map {
                HomeSubwayArrival(
                    lineBadge: badge,
                    terminalStationID: $0.terminal.stationID,
                    terminalName: $0.terminal.name,
                    tintColor: tintColor,
                    arrivalDate: Foundation.Date.now.addingTimeInterval(TimeInterval($0.minutes * 60)),
                    isRealtime: $0.isRealtime,
                    location: $0.location,
                    stops: $0.stops,
                    status: $0.status
                )
            } ?? []
    }

    private func subwayTimetableOptions(
        subway: HomePageQuery.Data.Subway?,
        direction: String,
        badge: String,
        tintColor: UIColor,
        isEligible: (HomePageQuery.Data.Subway.Timetable) -> Bool
    ) -> [HomeSubwayArrival] {
        subway?.timetable
            .filter { $0.direction == direction }
            .filter(isEligible)
            .compactMap { entry in
                guard let arrivalDate = entry.time.toLocalTimeOrNil() else { return nil }
                return HomeSubwayArrival(
                    lineBadge: badge,
                    terminalStationID: entry.terminal.stationID,
                    terminalName: entry.terminal.name,
                    tintColor: tintColor,
                    arrivalDate: arrivalDate,
                    isRealtime: false,
                    location: nil,
                    stops: nil,
                    status: nil
                )
            } ?? []
    }

    private func candidateArrivalDate(_ candidate: HomeShuttleCandidate, for destination: String) -> Foundation.Date? {
        guard let stopID = shuttleStopID(for: destination) else { return nil }
        return candidate.stops.first(where: { $0.name == stopID })?.time.toLocalTimeOrNil()
    }

    private func shuttleStopSummary(
        from stopName: String,
        to destination: String,
        candidate: HomeShuttleCandidate
    ) -> String {
        let pathStopIDs = shuttlePathStopIDs(from: stopName, to: destination, stops: candidate.stops.map(\.name))
        let viaStopNames = pathStopIDs
            .dropFirst()
            .dropLast()
            .map(localizedShuttleViaStopName)
        guard !viaStopNames.isEmpty else {
            return String(localized: "home.shuttle.no_via")
        }
        return String(format: String(localized: "home.shuttle.via"), viaStopNames.joined(separator: " · "))
    }

    private func shuttlePathStopIDs(from stopName: String, to destination: String, stops stopIDs: [String]) -> [String] {
        let destinationStopID = shuttleStopID(for: destination)
        if let startIndex = stopIDs.firstIndex(of: stopName) {
            let remainingStopIDs = Array(stopIDs[startIndex...])
            if let destinationStopID,
               let destinationIndex = remainingStopIDs.firstIndex(of: destinationStopID)
            {
                return Array(remainingStopIDs[...destinationIndex])
            }
            return remainingStopIDs
        }
        return stopIDs
    }

    private func shuttleStopID(for destination: String) -> String? {
        switch destination {
        case "STATION":
            "station"
        case "TERMINAL":
            "terminal"
        case "JUNGANG":
            "jungang_stn"
        case "CAMPUS":
            "dormitory_i"
        default:
            nil
        }
    }

    private func localizedShuttleStopName(_ stopID: String) -> String {
        switch stopID {
        case "dormitory_o":
            String(localized: "shuttle.stop.dormitory.out")
        case "dormitory_i":
            String(localized: "shuttle.stop.dormitory.in")
        case "shuttlecock_o":
            String(localized: "shuttle.stop.shuttlecock.out")
        case "shuttlecock_i":
            String(localized: "shuttle.stop.shuttlecock.in")
        case "station":
            String(localized: "shuttle.stop.station")
        case "terminal":
            String(localized: "shuttle.stop.terminal")
        case "jungang_stn":
            String(localized: "shuttle.stop.jungang.station")
        default:
            stopID
        }
    }

    private func localizedShuttleViaStopName(_ stopID: String) -> String {
        switch stopID {
        case "shuttlecock_i":
            String(localized: "shuttle.stop.shuttlecock.out")
        default:
            localizedShuttleStopName(stopID)
        }
    }

    private func shuttleRouteDisplay(
        stop: String,
        destination: String,
        candidate: HomeShuttleCandidate
    ) -> (badge: String, tintColor: UIColor) {
        let routeTag = candidate.routeTag
        let routeName = candidate.routeName

        switch (stop, destination) {
        case ("dormitory_o", "STATION"), ("shuttlecock_o", "STATION"):
            if routeTag == "DH" || routeTag == "DJ" {
                return (String(localized: "shuttle.type.direct"), .busRed)
            }
            if routeTag == "C" {
                return (String(localized: "shuttle.type.circular"), UIColor(named: "busBlue") ?? .systemBlue)
            }
        case ("dormitory_o", "TERMINAL"), ("shuttlecock_o", "TERMINAL"):
            if routeTag == "DY" {
                return (String(localized: "shuttle.type.direct"), .busRed)
            }
            if routeTag == "DJ" {
                return (String(localized: "shuttle.type.jungang_station"), .hanyangGreen)
            }
            if routeTag == "C" {
                return (String(localized: "shuttle.type.circular"), UIColor(named: "busBlue") ?? .systemBlue)
            }
        case ("dormitory_o", "JUNGANG"), ("shuttlecock_o", "JUNGANG"), ("station", "JUNGANG"):
            return (String(localized: "shuttle.type.jungang_station"), .hanyangGreen)
        case ("station", "CAMPUS"):
            if routeTag == "DH" {
                return (String(localized: "shuttle.type.direct"), .busRed)
            }
            if routeTag == "DJ" {
                return (String(localized: "shuttle.type.jungang_station"), .hanyangGreen)
            }
            if routeTag == "C" {
                return (String(localized: "shuttle.type.circular"), UIColor(named: "busBlue") ?? .systemBlue)
            }
        case ("station", "TERMINAL"):
            if routeTag == "C" {
                return (String(localized: "shuttle.type.circular"), UIColor(named: "busBlue") ?? .systemBlue)
            }
        case ("terminal", "CAMPUS"), ("jungang_stn", "CAMPUS"), ("shuttlecock_i", "CAMPUS"):
            if routeName.hasSuffix("S") {
                return (String(localized: "shuttle.type.shuttlecock"), .busRed)
            }
            if routeName.hasSuffix("D") {
                return (String(localized: "shuttle.type.dormitory"), .hanyangBlue)
            }
        default:
            break
        }

        return (String(localized: "home.badge.free"), .hanyangBlue)
    }

    private func buildBusAlternatives(_ busList: [HomePageQuery.Data.Bus]) -> [String: [HomeTransitOption]] {
        func item(routeSeq: Int, stopSeq: Int) -> HomePageQuery.Data.Bus? {
            busList.first { $0.route.seq == routeSeq && $0.stop.seq == stopSeq }
        }

        func option(
            _ bus: HomePageQuery.Data.Bus?,
            route: String,
            stopName: String,
            direction: String,
            color: UIColor
        ) -> HomeTransitOption? {
            guard let bus, let minutes = bus.arrival.first?.minutes else { return nil }
            let subtitle = String(format: String(localized: "home.alt.bus_direction"), direction)
            return HomeTransitOption(
                kind: .alternative,
                title: stopName,
                subtitle: subtitle,
                minutes: minutes,
                badge: route,
                tintColor: color
            )
        }

        func best(_ options: [HomeTransitOption?]) -> HomeTransitOption? {
            options.compactMap { $0 }.min { ($0.minutes ?? Int.max) < ($1.minutes ?? Int.max) }
        }

        let green = UIColor(named: "busGreen") ?? .systemGreen
        let blue = UIColor(named: "busBlue") ?? .systemBlue
        let terminal = String(localized: "home.alt.direction.intercity_terminal")
        let terminalStop = String(localized: "home.alt.intercity_terminal")
        let jungang = String(localized: "home.destination.jungang")
        let dormitory = String(localized: "shuttle.stop.dormitory.in")
        let shuttlecock = String(localized: "shuttle.stop.shuttlecock.out")
        let sangnoksu = String(localized: "home.alt.direction.sangnoksu")
        let shuttlecockDormitory = String(localized: "home.alt.direction.shuttlecock_dormitory")
        let route80A = best([
            option(
                item(routeSeq: 216_000_081, stopSeq: 216_000_028),
                route: "80A",
                stopName: String(localized: "home.alt.gyeonggi_technopark"),
                direction: terminal,
                color: blue
            ),
            option(
                item(routeSeq: 216_000_101, stopSeq: 216_000_028),
                route: "N80A",
                stopName: String(localized: "home.alt.gyeonggi_technopark"),
                direction: terminal,
                color: blue
            )
        ])
        let terminal80B = best([
            option(
                item(routeSeq: 216_000_082, stopSeq: 216_000_077),
                route: "80B",
                stopName: terminalStop,
                direction: dormitory,
                color: blue
            ),
            option(
                item(routeSeq: 216_000_102, stopSeq: 216_000_077),
                route: "N80B",
                stopName: terminalStop,
                direction: dormitory,
                color: blue
            )
        ])
        let jungang80B = best([
            option(
                item(routeSeq: 216_000_082, stopSeq: 217_000_140),
                route: "80B",
                stopName: String(localized: "home.destination.jungang"),
                direction: dormitory,
                color: blue
            ),
            option(
                item(routeSeq: 216_000_102, stopSeq: 217_000_140),
                route: "N80B",
                stopName: String(localized: "home.destination.jungang"),
                direction: dormitory,
                color: blue
            )
        ])

        return [
            "dormitory_station": [
                option(
                    item(routeSeq: 216_000_068, stopSeq: 216_000_383),
                    route: "10-1",
                    stopName: String(localized: "home.alt.dormitory_nearby"),
                    direction: sangnoksu,
                    color: green
                )
            ].compactMap { $0 },
            "dormitory_terminal": [route80A].compactMap { $0 },
            "dormitory_jungang": [
                best([
                    option(
                        item(routeSeq: 216_000_081, stopSeq: 216_000_028),
                        route: "80A",
                        stopName: String(localized: "home.alt.gyeonggi_technopark"),
                        direction: jungang,
                        color: blue
                    ),
                    option(
                        item(routeSeq: 216_000_101, stopSeq: 216_000_028),
                        route: "N80A",
                        stopName: String(localized: "home.alt.gyeonggi_technopark"),
                        direction: jungang,
                        color: blue
                    )
                ])
            ].compactMap { $0 },
            "shuttlecock_terminal": [
                option(
                    item(routeSeq: 216_000_016, stopSeq: 216_000_152),
                    route: "62",
                    stopName: String(localized: "home.alt.seongan_entrance"),
                    direction: terminal,
                    color: green
                )
            ].compactMap { $0 },
            "shuttlecock_jungang": [
                option(
                    item(routeSeq: 216_000_016, stopSeq: 216_000_152),
                    route: "62",
                    stopName: String(localized: "home.alt.seongan_entrance"),
                    direction: jungang,
                    color: green
                )
            ].compactMap { $0 },
            "station_dormitory": [
                option(
                    item(routeSeq: 216_000_068, stopSeq: 216_000_138),
                    route: "10-1",
                    stopName: String(localized: "home.alt.sangnoksu"),
                    direction: shuttlecockDormitory,
                    color: green
                )
            ].compactMap { $0 },
            "terminal_dormitory": [
                terminal80B,
                option(
                    item(routeSeq: 216_000_016, stopSeq: 216_000_074),
                    route: "62",
                    stopName: terminalStop,
                    direction: shuttlecock,
                    color: green
                )
            ].compactMap { $0 },
            "jungang_dormitory": [
                jungang80B,
                option(
                    item(routeSeq: 216_000_016, stopSeq: 217_000_264),
                    route: "62",
                    stopName: String(localized: "home.destination.jungang"),
                    direction: shuttlecock,
                    color: green
                )
            ].compactMap { $0 }
        ]
    }

    private func fetchHomeData(showsLoadingState: Bool = true) {
        guard !isLoading else { return }
        isLoading = true
        if showsLoadingState || shuttleData == nil {
            renderLoadingState()
        }

        let mealPeriod = isMealPeriodManuallySelected ? activeMealPeriod() : currentMealPeriod()
        displayedMealPeriod = mealPeriod
        let weekday = currentSubwayWeekday()
        let timeFormatter = DateFormatter().then { $0.dateFormat = "HH:mm" }
        let campusID = UserDefaults.standard.integer(forKey: "campusID") == 0 ? 2 : UserDefaults.standard.integer(forKey: "campusID")

        Task {
            let response = try? await Network.shared.client.fetch(
                query: HomePageQuery(
                    language: currentNoticeLanguage(),
                    after: GraphQLNullable(stringLiteral: timeFormatter.string(from: Foundation.Date.now)),
                    weekday: weekday,
                    date: mealPeriod.queryDate.toLocalDateString(),
                    campusID: Int32(campusID),
                    busInput: homeBusInput()
                ),
                cachePolicy: .networkOnly
            )
            let bus50TerminalLogTimes = await fetchBus50TerminalLogTimes()

            await MainActor.run {
                if let data = response?.data {
                    shuttleData = data
                    busAlternatives = buildBusAlternatives(data.bus)
                    self.bus50TerminalLogTimes = bus50TerminalLogTimes
                    mealSections = buildMealSections(data.cafeteria, mealPeriod: activeMealPeriod())
                    Task {
                        await ShuttleServiceNoticeScheduler.shared.sync()
                    }
                }
                isLoading = false
                refreshControl.endRefreshing()
                render()
            }
        }
    }

    private func currentNoticeLanguage() -> String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "ko"
        return languageCode.starts(with: "ko") ? "KOREAN" : "ENGLISH"
    }

    private func fetchBus50TerminalLogTimes() async -> [LocalTime] {
        let now = Foundation.Date.now
        let queryDateFormatter = DateFormatter().then { $0.dateFormat = "yyyy-MM-dd" }
        let dates = [
            now.addingTimeInterval(-60 * 60 * 24 * 7),
            now.addingTimeInterval(-60 * 60 * 24 * 2),
            now.addingTimeInterval(-60 * 60 * 24)
        ].map(queryDateFormatter.string)

        let response = try? await Network.shared.client.fetch(query: BusDepartureLogDialogQuery(routeStops: [
            BusRouteStopInput(route: 216_000_075, stop: 216_000_759, dates: .some(dates))
        ]))
        return response?.data?.bus
            .flatMap(\.log)
            .map(\.time)
            .sorted() ?? []
    }

    private func startAutoRefresh() {
        stopAutoRefresh()
        autoRefreshSubscription = Observable<Int>
            .interval(.seconds(Self.autoRefreshIntervalSeconds), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.refreshHomeContext(showsLoadingState: false)
            })
    }

    private func stopAutoRefresh() {
        autoRefreshSubscription?.dispose()
        autoRefreshSubscription = nil
    }

    private func refreshHomeContext(showsLoadingState: Bool = true) {
        #if DEBUG
            if !usesDebugDeparture {
                requestDepartureLocation()
            }
        #else
            requestDepartureLocation()
        #endif
        fetchHomeData(showsLoadingState: showsLoadingState)
    }

    #if DEBUG
        private func applyDebugRouteOverride() {
            let arguments = ProcessInfo.processInfo.arguments
            if let departureValue = argumentValue(named: "-homeDebugDeparture", in: arguments),
               let departure = HomeDeparture(debugValue: departureValue)
            {
                selectedDeparture = departure
                usesDebugDeparture = true
            }
            if let destinationValue = argumentValue(named: "-homeDebugDestination", in: arguments),
               let destination = HomeDestination(debugValue: destinationValue),
               selectedDeparture.destinations.contains(destination)
            {
                selectedDestination = destination
            }
            if let subwayDestinationValue = argumentValue(named: "-homeDebugSubwayDestination", in: arguments),
               let subwayDestination = SubwayTransferDestination(debugValue: subwayDestinationValue)
            {
                HomeSettings.subwayTransferDestination = subwayDestination
                HomeSettings.showSubwayTransfer = true
            }
        }

        private func argumentValue(named name: String, in arguments: [String]) -> String? {
            guard let index = arguments.firstIndex(of: name),
                  arguments.indices.contains(arguments.index(after: index)) else { return nil }
            return arguments[arguments.index(after: index)]
        }
    #endif

    private func shuttleRoute(from departure: HomeDeparture, to destination: HomeDestination) -> HomeShuttleRoute? {
        let dormitoryRoute: (HomePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) -> Bool = {
            $0.route.name.hasSuffix("D")
        }

        switch (departure, destination) {
        case (.dormitory, .station):
            return HomeShuttleRoute(stop: "dormitory_o", destination: "STATION", routeFilter: nil)
        case (.dormitory, .terminal):
            return HomeShuttleRoute(stop: "dormitory_o", destination: "TERMINAL", routeFilter: nil)
        case (.dormitory, .jungang):
            return HomeShuttleRoute(stop: "dormitory_o", destination: "JUNGANG", routeFilter: nil)
        case (.shuttlecock, .station):
            return HomeShuttleRoute(stop: "shuttlecock_o", destination: "STATION", routeFilter: nil)
        case (.shuttlecock, .terminal):
            return HomeShuttleRoute(stop: "shuttlecock_o", destination: "TERMINAL", routeFilter: nil)
        case (.shuttlecock, .jungang):
            return HomeShuttleRoute(stop: "shuttlecock_o", destination: "JUNGANG", routeFilter: nil)
        case (.shuttlecock, .dormitory):
            return HomeShuttleRoute(stop: "shuttlecock_i", destination: "CAMPUS", routeFilter: dormitoryRoute)
        case (.station, .dormitory):
            return HomeShuttleRoute(stop: "station", destination: "CAMPUS", routeFilter: dormitoryRoute)
        case (.station, .terminal):
            return HomeShuttleRoute(stop: "station", destination: "TERMINAL", routeFilter: nil)
        case (.station, .jungang):
            return HomeShuttleRoute(stop: "station", destination: "JUNGANG", routeFilter: nil)
        case (.terminal, .dormitory):
            return HomeShuttleRoute(stop: "terminal", destination: "CAMPUS", routeFilter: dormitoryRoute)
        case (.jungang, .dormitory):
            return HomeShuttleRoute(stop: "jungang_stn", destination: "CAMPUS", routeFilter: dormitoryRoute)
        default:
            return nil
        }
    }

    private func homeBusInput() -> [BusRouteStopInput] {
        [
            BusRouteStopInput(route: 216_000_068, stop: 216_000_383, limit: 1),
            BusRouteStopInput(route: 216_000_068, stop: 216_000_138, limit: 1),
            BusRouteStopInput(route: 216_000_081, stop: 216_000_028, limit: 1),
            BusRouteStopInput(route: 216_000_101, stop: 216_000_028, limit: 1),
            BusRouteStopInput(route: 216_000_016, stop: 216_000_152, limit: 1),
            BusRouteStopInput(route: 216_000_082, stop: 216_000_077, limit: 1),
            BusRouteStopInput(route: 216_000_102, stop: 216_000_077, limit: 1),
            BusRouteStopInput(route: 216_000_016, stop: 216_000_074, limit: 1),
            BusRouteStopInput(route: 216_000_082, stop: 217_000_140, limit: 1),
            BusRouteStopInput(route: 216_000_102, stop: 217_000_140, limit: 1),
            BusRouteStopInput(route: 216_000_016, stop: 217_000_264, limit: 1)
        ]
    }

    private func buildMealSections(
        _ cafeterias: [HomePageQuery.Data.Cafeterium],
        mealPeriod: HomeMealPeriod
    ) -> [HomeMealSection] {
        let marker = mealPeriod.marker
        return cafeterias
            .sorted { $0.seq < $1.seq }
            .compactMap { cafeteria in
                let items = cafeteria.menus
                    .filter { $0.type.contains(marker) }
                    .compactMap { menu -> HomeMealItem? in
                        let menuText = representativeMenuText(menu.food)
                        guard !menuText.isEmpty else { return nil }
                        return HomeMealItem(
                            menu: menuText,
                            price: menu.price
                        )
                    }
                guard !items.isEmpty else { return nil }
                return HomeMealSection(
                    cafeteria: cafeteriaName(seq: cafeteria.seq),
                    runningTime: runningTime(for: cafeteria, mealPeriod: mealPeriod),
                    items: items
                )
            }
    }

    private func representativeMenuText(_ text: String) -> String {
        let menuText = localizedMenuText(menuTextRemovingLeadingDescriptors(text))
        guard !menuText.isEmpty else { return "" }
        return menuText
            .components(separatedBy: .whitespacesAndNewlines)
            .first(where: { !$0.isEmpty }) ?? menuText
    }

    private func menuTextRemovingLeadingDescriptors(_ text: String) -> String {
        var result = text
        [
            #"^\s*\[[^\]]+\]\s*"#,
            #"^\s*<[^>]+>\s*"#,
            #"^\s*[\w가-힣]+\)\s*"#
        ].forEach {
            result = result.replacingOccurrences(of: $0, with: "", options: .regularExpression)
        }
        return result
    }

    private func makeTransitRow(_ option: HomeTransitOption, emphasized: Bool) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        row.isLayoutMarginsRelativeArrangement = true
        row.backgroundColor = emphasized ? option.tintColor.withAlphaComponent(0.10) : .tertiarySystemGroupedBackground
        row.layer.cornerRadius = 8

        let badge = HomePaddedLabel()
        badge.text = option.badge
        badge.font = .godo(size: 12, weight: .bold)
        badge.textColor = .white
        badge.textAlignment = .center
        badge.backgroundColor = option.tintColor
        badge.contentInsets = UIEdgeInsets(top: 5, left: 14, bottom: 5, right: 14)
        badge.layer.cornerRadius = 13
        badge.clipsToBounds = true
        badge.adjustsFontSizeToFitWidth = true
        badge.minimumScaleFactor = 0.75
        badge.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(48)
            make.width.lessThanOrEqualTo(82)
            make.height.equalTo(26)
        }
        badge.setContentHuggingPriority(.required, for: .horizontal)
        badge.setContentCompressionResistancePriority(.required, for: .horizontal)

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 4
        let title = UILabel()
        title.text = option.title
        title.font = .godo(size: emphasized ? 17 : 15, weight: .bold)
        title.textColor = .label
        title.numberOfLines = 1
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.75
        let subtitle = UILabel()
        subtitle.text = option.subtitle
        subtitle.font = .godo(size: 13, weight: .regular)
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 2
        textStack.addArrangedSubview(title)
        textStack.addArrangedSubview(subtitle)

        let minutes = UILabel()
        minutes.text = option.minutes.map { String(format: String(localized: "home.minutes"), $0) } ?? String(localized: "home.check")
        minutes.font = .godo(size: emphasized ? 20 : 17, weight: .bold)
        minutes.textColor = option.tintColor
        minutes.textAlignment = .right
        minutes.adjustsFontSizeToFitWidth = true
        minutes.minimumScaleFactor = 0.85
        minutes.setContentCompressionResistancePriority(.required, for: .horizontal)

        row.addArrangedSubview(badge)
        row.addArrangedSubview(textStack)
        row.addArrangedSubview(minutes)
        return row
    }

    private func shuttleTransferPairViews(for options: [HomeTransitOption]) -> [UIView] {
        options.enumerated().map { index, option in
            guard let firstConnection = option.connections.first else {
                return makeTransitRow(option, emphasized: true)
            }
            let nextConnection = options.indices.contains(index + 1) ? options[index + 1].connections.first : nil
            if let nextConnection,
               abs(nextConnection.arrivalDate.timeIntervalSince(firstConnection.arrivalDate)) < 60
            {
                return makeTransitRow(option, emphasized: true)
            }
            return makeShuttleTransferPair(option)
        }
    }

    private func makeShuttleTransferPair(_ option: HomeTransitOption) -> UIView {
        guard !option.connections.isEmpty else {
            return makeTransitRow(option, emphasized: true)
        }

        let container = UIView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8

        let shuttleRow = makeTransitRow(option, emphasized: true)
        let transferRows = option.connections.enumerated().map { index, connection in
            makeTransferConnectionRow(
                connection,
                hasFollowingConnection: option.connections.indices.contains(index + 1)
            )
        }

        container.addSubview(stack)
        stack.addArrangedSubview(shuttleRow)
        transferRows.forEach(stack.addArrangedSubview)

        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        let linkUpperRows = [shuttleRow] + Array(transferRows.dropLast())
        for (upperRow, connection) in zip(linkUpperRows, option.connections) {
            let linkBadge = HomeTransferConnectorView(
                title: connection.connectorTitle,
                travelMinutes: connection.connectorTravelMinutes,
                tintColor: connection.tintColor
            )

            container.addSubview(linkBadge)
            linkBadge.snp.makeConstraints { make in
                make.height.equalTo(24)
                make.centerX.equalToSuperview()
                make.centerY.equalTo(upperRow.snp.bottom).offset(4)
            }
        }
        return container
    }

    private func makeTransferConnectionRow(
        _ connection: HomeTransferConnection,
        hasFollowingConnection: Bool
    ) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        row.layoutMargins = UIEdgeInsets(
            top: 14,
            left: 12,
            bottom: hasFollowingConnection ? 14 : 8,
            right: 12
        )
        row.isLayoutMarginsRelativeArrangement = true
        row.backgroundColor = connection.tintColor.withAlphaComponent(0.08)
        row.layer.cornerRadius = 8
        row.layer.borderWidth = 1
        row.layer.borderColor = connection.tintColor.withAlphaComponent(0.12).cgColor

        let badge = HomePaddedLabel()
        badge.text = connection.badge
        badge.font = .godo(size: 12, weight: .bold)
        badge.textColor = .white
        badge.textAlignment = .center
        badge.backgroundColor = connection.tintColor
        badge.contentInsets = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
        badge.layer.cornerRadius = 13
        badge.clipsToBounds = true
        badge.adjustsFontSizeToFitWidth = true
        badge.minimumScaleFactor = 0.75
        badge.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(48)
            make.width.lessThanOrEqualTo(72)
            make.height.equalTo(26)
        }
        badge.setContentHuggingPriority(.required, for: .horizontal)
        badge.setContentCompressionResistancePriority(.required, for: .horizontal)

        let title = UILabel()
        title.text = connection.title
        title.font = .godo(size: 15, weight: .bold)
        title.textColor = .label
        title.numberOfLines = 1
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.75

        let subtitle = UILabel()
        subtitle.text = connection.subtitle
        subtitle.font = .godo(size: 12, weight: .regular)
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 1
        subtitle.adjustsFontSizeToFitWidth = true
        subtitle.minimumScaleFactor = 0.75

        let textStack = UIStackView(arrangedSubviews: [title, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 2

        let trailing = UILabel()
        trailing.text = connection.trailing
        trailing.font = .godo(size: 15, weight: .bold)
        trailing.textColor = connection.tintColor
        trailing.textAlignment = .right
        trailing.adjustsFontSizeToFitWidth = true
        trailing.minimumScaleFactor = 0.75
        trailing.setContentCompressionResistancePriority(.required, for: .horizontal)

        row.addArrangedSubview(badge)
        row.addArrangedSubview(textStack)
        row.addArrangedSubview(trailing)
        return row
    }

    private func makeMealSection(_ section: HomeMealSection) -> UIView {
        let sectionStack = UIStackView()
        sectionStack.axis = .vertical
        sectionStack.spacing = 10
        sectionStack.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        sectionStack.isLayoutMarginsRelativeArrangement = true
        sectionStack.backgroundColor = .tertiarySystemGroupedBackground
        sectionStack.layer.cornerRadius = 8

        let header = UIStackView()
        header.axis = .vertical
        header.spacing = 3

        let title = UILabel()
        title.text = section.cafeteria
        title.font = .godo(size: 16, weight: .bold)
        title.textColor = .label

        header.addArrangedSubview(title)
        if let runningTime = section.runningTime, !runningTime.isEmpty {
            let time = UILabel()
            time.text = runningTime
            time.font = .godo(size: 12, weight: .regular)
            time.textColor = .tertiaryLabel
            header.addArrangedSubview(time)
        }
        sectionStack.addArrangedSubview(header)

        for (index, item) in section.items.enumerated() {
            if index > 0 {
                let separator = UIView()
                separator.backgroundColor = .separator.withAlphaComponent(0.35)
                separator.snp.makeConstraints { make in
                    make.height.equalTo(1 / UIScreen.main.scale)
                }
                sectionStack.addArrangedSubview(separator)
            }
            sectionStack.addArrangedSubview(makeMealMenuRow(item))
        }
        return sectionStack
    }

    private func makeMealMenuRow(_ item: HomeMealItem) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 8

        let menu = UILabel()
        menu.setKoreanTranslatedText(item.menu)
        menu.font = .godo(size: 14, weight: .regular)
        menu.textColor = .secondaryLabel
        menu.numberOfLines = 1
        menu.adjustsFontSizeToFitWidth = true
        menu.minimumScaleFactor = 0.8

        let price = UILabel()
        price.text = item.price
        price.font = .godo(size: 14, weight: .bold)
        price.textColor = .plainButtonText
        price.textAlignment = .right
        price.setContentCompressionResistancePriority(.required, for: .horizontal)

        row.addArrangedSubview(menu)
        row.addArrangedSubview(price)
        return row
    }

    private func makeEmptyView(title: String, message: String) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.layoutMargins = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.backgroundColor = .tertiarySystemGroupedBackground
        stack.layer.cornerRadius = 8

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .godo(size: 15, weight: .bold)
        titleLabel.textColor = .label
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = .godo(size: 13, weight: .regular)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(messageLabel)
        return stack
    }

    private func makeSkeletonRow(widthRatio: CGFloat) -> UIView {
        let view = UIView()
        view.backgroundColor = .tertiarySystemGroupedBackground
        view.layer.cornerRadius = 8
        view.snp.makeConstraints { make in
            make.height.equalTo(52)
        }

        let bar = UIView()
        bar.backgroundColor = .separator.withAlphaComponent(0.45)
        bar.layer.cornerRadius = 5
        view.addSubview(bar)
        bar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(widthRatio)
            make.height.equalTo(10)
        }
        return view
    }

    private func replaceSubviews(in stack: UIStackView, with views: [UIView]) {
        for arrangedSubview in stack.arrangedSubviews {
            stack.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }
        views.forEach(stack.addArrangedSubview)
    }

    private func observeApplicationActivation() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    private func updateDepartureSelector() {
        let displayedTitle = selectedDeparture.title
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .label
        configuration.image = UIImage(systemName: "chevron.down")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        )
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 5
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 2)
        configuration.attributedTitle = AttributedString(displayedTitle, attributes: AttributeContainer([
            .font: UIFont.godo(size: Self.selectorTitleFontSize, weight: .bold)
        ]))
        departureSelectorButton.configuration = configuration
        departureSelectorButton.accessibilityValue = displayedTitle
        departureSelectorButton.menu = UIMenu(
            options: .singleSelection,
            children: HomeDeparture.allCases.map { departure in
                UIAction(
                    title: departure.title,
                    state: departure == selectedDeparture ? .on : .off
                ) { [weak self] _ in
                    self?.selectDepartureManually(departure)
                }
            }
        )
    }

    private func updateMealPeriodSelector() {
        let selectedPeriod = activeMealPeriod()
        cafeteriaIconView.image = UIImage(systemName: selectedPeriod.iconName)
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .label
        configuration.image = UIImage(systemName: "chevron.down")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        )
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 5
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 2)
        configuration.attributedTitle = AttributedString(selectedPeriod.title, attributes: AttributeContainer([
            .font: UIFont.godo(size: Self.selectorTitleFontSize, weight: .bold)
        ]))
        cafeteriaPeriodSelectorButton.configuration = configuration
        cafeteriaPeriodSelectorButton.accessibilityValue = selectedPeriod.title
        cafeteriaPeriodSelectorButton.menu = UIMenu(
            options: .singleSelection,
            children: mealPeriods(for: selectedPeriod.queryDate).map { period in
                UIAction(
                    title: period.title,
                    state: period.mealIndex == selectedPeriod.mealIndex ? .on : .off
                ) { [weak self] _ in
                    self?.selectMealPeriodManually(period)
                }
            }
        )
    }

    private func selectMealPeriodManually(_ mealPeriod: HomeMealPeriod) {
        isMealPeriodManuallySelected = true
        displayedMealPeriod = mealPeriod
        if let cafeterias = shuttleData?.cafeteria {
            mealSections = buildMealSections(cafeterias, mealPeriod: mealPeriod)
        }
        renderMeals()
    }

    private func updateDestinationControl() {
        destinationControl.removeAllSegments()
        for (index, destination) in availableDestinations.enumerated() {
            destinationControl.insertSegment(withTitle: destination.title, at: index, animated: false)
        }
        if !availableDestinations.contains(selectedDestination) {
            selectedDestination = availableDestinations.first ?? .station
        }
        destinationControl.selectedSegmentIndex = availableDestinations.firstIndex(of: selectedDestination) ?? 0
    }

    private func updateDeparture(_ departure: HomeDeparture) {
        guard selectedDeparture != departure else { return }
        selectedDeparture = departure
        updateDestinationControl()
        renderMovement()
        refreshPresenceStatus()
    }

    private func selectDepartureManually(_ departure: HomeDeparture) {
        isDepartureManuallySelected = true
        shouldRestoreAutomaticDepartureOnActivation = false
        hasResolvedInitialDepartureLocation = true
        guard selectedDeparture != departure else {
            updateDepartureSelector()
            return
        }
        updateDeparture(departure)
    }

    @objc private func applicationDidEnterBackground() {
        shouldRestoreAutomaticDepartureOnActivation = isDepartureManuallySelected
    }

    @objc private func applicationDidBecomeActive() {
        guard shouldRestoreAutomaticDepartureOnActivation else { return }
        shouldRestoreAutomaticDepartureOnActivation = false
        isDepartureManuallySelected = false
        hasResolvedInitialDepartureLocation = false
        #if DEBUG
            guard !usesDebugDeparture else { return }
        #endif
        requestDepartureLocation()
    }

    private func requestDepartureLocation() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    @objc private func destinationChanged() {
        guard availableDestinations.indices.contains(destinationControl.selectedSegmentIndex) else { return }
        let destination = availableDestinations[destinationControl.selectedSegmentIndex]
        selectedDestination = destination
        AnalyticsManager.logSelect(
            .homeSelectDestination,
            type: .tab,
            name: destination.analyticsValue,
            destinationID: destination.analyticsValue
        )
        renderMovement()
        refreshPresenceStatus()
    }

    @objc private func refresh() {
        AnalyticsManager.logSelect(.homeRefresh)
        refreshHomeContext()
    }

    @objc private func openQuickSettings() {
        let vc = HomeQuickSettingsVC(
            showPresenceStatus: ShuttlePresenceSettings.showsStatus,
            showBus50Transfer: HomeSettings.showBus50Transfer,
            showSubwayTransfer: HomeSettings.showSubwayTransfer,
            subwayTransferDestination: HomeSettings.subwayTransferDestination
        )
        vc.openLegacyShuttle = { [weak self] in
            self?.openLegacyShuttle()
        }
        vc.updateShowPresenceStatus = { [weak self] isOn in
            self?.applyShowPresenceStatus(isOn)
        }
        vc.updateShowBus50Transfer = { [weak self] isOn in
            HomeSettings.showBus50Transfer = isOn
            self?.renderMovement()
        }
        vc.updateShowSubwayTransfer = { [weak self] isOn in
            HomeSettings.showSubwayTransfer = isOn
            self?.renderMovement()
        }
        vc.updateSubwayTransferDestination = { [weak self] destination in
            HomeSettings.subwayTransferDestination = destination
            self?.renderMovement()
        }
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom { context in
                min(vc.preferredSheetHeight, context.maximumDetentValue)
            }]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }

    @objc private func openLegacyShuttle() {
        AnalyticsManager.logSelect(.homeOpenLegacyShuttle)
        (navigationController as? ShuttleNC)?.showLegacyShuttle()
    }

    @objc private func openShuttleTimetable() {
        AnalyticsManager.logSelect(.homeOpenShuttleTimetable)
        (navigationController as? ShuttleNC)?.showShuttleTimetableFromHome(
            stopID: selectedDeparture.timetableStart(for: selectedDestination),
            destination: selectedDestination.timetableDestination
        )
    }

    @objc private func openCafeteria() {
        AnalyticsManager.logSelect(.homeOpenCafeteria)
        if let root = tabBarController as? RootVC {
            let mealPeriod = activeMealPeriod()
            root.selectedViewController = root.cafeteriaNC
            root.cafeteriaNC.showMeal(date: mealPeriod.queryDate, mealIndex: mealPeriod.mealIndex)
        }
    }

    private func minutesUntil(_ time: LocalTime) -> Int? {
        guard let date = time.toLocalTimeOrNil() else { return nil }
        return max(0, Int(ceil(date.timeIntervalSince(Foundation.Date.now) / 60)))
    }

    private func compactTime(_ time: LocalTime) -> String {
        String(time.prefix(5))
    }

    private func compactTime(_ date: Foundation.Date) -> String {
        let formatter = DateFormatter().then {
            $0.calendar = Calendar(identifier: .iso8601)
            $0.locale = Locale(identifier: "en_US_POSIX")
            $0.timeZone = TimeZone(identifier: "Asia/Seoul")
            $0.dateFormat = "HH:mm"
        }
        return formatter.string(from: date)
    }

    private func currentSubwayWeekday() -> String {
        let component = Calendar.current.component(.weekday, from: Foundation.Date.now)
        return (component == 1 || component == 7) ? "weekends" : "weekdays"
    }

    private func localizedSubwayStationName(_ stationID: String, fallback: String) -> String {
        switch stationID {
        case "K405": return String(localized: "subway.station.k405")
        case "K409": return String(localized: "subway.station.k409")
        case "K411": return String(localized: "subway.station.k411")
        case "K419": return String(localized: "subway.station.k419")
        case "K433": return String(localized: "subway.station.k433")
        case "K443": return String(localized: "subway.station.k443")
        case "K444": return String(localized: "subway.station.k444")
        case "K453": return String(localized: "subway.station.k453")
        case "K456": return String(localized: "subway.station.k456")
        case "K209": return String(localized: "subway.station.k209")
        case "K210": return String(localized: "subway.station.k210")
        case "K233": return String(localized: "subway.station.k233")
        case "K246": return String(localized: "subway.station.k246")
        case "K258": return String(localized: "subway.station.k258")
        case "K272": return String(localized: "subway.station.k272")
        default:
            let key = "subway.station.\(stationID.lowercased())"
            let localized = String(localized: String.LocalizationValue(stringLiteral: key))
            return localized == key ? fallback : localized
        }
    }

    private func currentMealPeriod() -> HomeMealPeriod {
        let hour = Calendar.current.component(.hour, from: Foundation.Date.now)
        let date: Foundation.Date
        let mealIndex: Int
        if hour < 10 {
            date = Foundation.Date.now
            mealIndex = 0
        } else if hour < 15 {
            date = Foundation.Date.now
            mealIndex = 1
        } else if hour < 20 {
            date = Foundation.Date.now
            mealIndex = 2
        } else {
            date = Calendar.current.date(
                byAdding: .day,
                value: 1,
                to: Foundation.Date.now
            ) ?? Foundation.Date.now
            mealIndex = 0
        }
        return mealPeriods(for: date)[mealIndex]
    }

    private func mealPeriods(for date: Foundation.Date) -> [HomeMealPeriod] {
        let isTomorrow = Calendar.current.isDateInTomorrow(date)
        let periods = [
            (
                marker: "조식",
                title: String(localized: "home.meal.breakfast"),
                iconName: "sunrise.fill"
            ),
            (
                marker: "중식",
                title: String(localized: "home.meal.lunch"),
                iconName: "sun.max.fill"
            ),
            (
                marker: "석식",
                title: String(localized: "home.meal.dinner"),
                iconName: "moon.fill"
            )
        ]
        return periods.enumerated().map { index, period in
            let title = isTomorrow
                ? String(format: String(localized: "home.meal.tomorrow.format"), period.title)
                : period.title
            return HomeMealPeriod(
                marker: period.marker,
                title: title,
                queryDate: date,
                iconName: period.iconName,
                mealIndex: index
            )
        }
    }

    private func currentMealTitle() -> String {
        activeMealPeriod().title
    }

    private func activeMealPeriod() -> HomeMealPeriod {
        displayedMealPeriod ?? currentMealPeriod()
    }

    private func runningTime(
        for cafeteria: HomePageQuery.Data.Cafeterium,
        mealPeriod: HomeMealPeriod
    ) -> String? {
        switch mealPeriod.marker {
        case "조식": cafeteria.runningTime.breakfast
        case "중식": cafeteria.runningTime.lunch
        default: cafeteria.runningTime.dinner
        }
    }

    private func cafeteriaName(seq: Int) -> String {
        switch seq {
        case 1:
            String(localized: "cafeteria.title.1")
        case 2:
            String(localized: "cafeteria.title.2")
        case 4:
            String(localized: "cafeteria.title.4")
        case 6:
            String(localized: "cafeteria.title.6")
        case 7:
            String(localized: "cafeteria.title.7")
        case 8:
            String(localized: "cafeteria.title.8")
        case 11:
            String(localized: "cafeteria.title.11")
        case 12:
            String(localized: "cafeteria.title.12")
        case 13:
            String(localized: "cafeteria.title.13")
        case 14:
            String(localized: "cafeteria.title.14")
        case 15:
            String(localized: "cafeteria.title.15")
        default:
            String(localized: "cafeteria.title.1")
        }
    }

    private func localizedMenuText(_ text: String) -> String {
        let cleaned = text.replacingOccurrences(of: "\"", with: "")
        let isKorean = (Locale.current.language.languageCode?.identifier ?? "ko").hasPrefix("ko")
        let tokens = cleaned.components(separatedBy: .whitespacesAndNewlines)
        let pattern = isKorean ? #"\p{Hangul}"# : #"[A-Za-z]"#
        let hasEnglish = cleaned.range(of: #"[A-Za-z]"#, options: .regularExpression) != nil
        let shouldFilter = isKorean || hasEnglish
        let filteredTokens = shouldFilter ? tokens.filter {
            $0.range(of: pattern, options: .regularExpression) != nil
        } : tokens
        let displayTokens = filteredTokens.isEmpty ? tokens : filteredTokens
        return displayTokens
            .joined(separator: " ")
            .replacingOccurrences(of: "\n", with: " · ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func formattedToday() -> String {
        DateFormatter().then {
            $0.locale = .current
            $0.setLocalizedDateFormatFromTemplate("MdEEEE")
        }.string(from: Foundation.Date.now)
    }
}

extension TodayHomeVC: @preconcurrency CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !isDepartureManuallySelected,
              let location = locations.last,
              let nearestDeparture = HomeDeparture.allCases.min(by: {
                  $0.location.distance(from: location) < $1.location.distance(from: location)
              })
        else { return }
        let shouldApplyHysteresis = hasResolvedInitialDepartureLocation
        hasResolvedInitialDepartureLocation = true
        let currentDistance = selectedDeparture.location.distance(from: location)
        let nearestDistance = nearestDeparture.location.distance(from: location)
        guard nearestDeparture != selectedDeparture else { return }
        guard !shouldApplyHysteresis ||
            nearestDistance + Self.departureSwitchHysteresisMeters < currentDistance
        else { return }
        updateDeparture(nearestDeparture)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {}

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        requestDepartureLocation()
    }
} // swiftlint:disable:this file_length
