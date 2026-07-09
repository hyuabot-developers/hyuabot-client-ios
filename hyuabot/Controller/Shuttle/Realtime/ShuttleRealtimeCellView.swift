import Api
import RxSwift
import UIKit

private final class ExtendedHitAreaButton: UIButton {
    var minimumHitArea = CGSize(width: 44, height: 44)

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let widthInset = min(0, bounds.width - minimumHitArea.width) / 2
        let heightInset = min(0, bounds.height - minimumHitArea.height) / 2
        return bounds.insetBy(dx: widthInset, dy: heightInset).contains(point)
    }
}

class ShuttleRealtimeCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleRealtimeCellView"
    private let disposeBag = DisposeBag()
    private let shuttleTypeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
    }

    private let shuttleTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
    }

    private let shuttleRemainingTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
    }

    private let shuttleAlertLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textColor = .hanyangOrange
        $0.text = String(localized: "shuttle.location.alert")
    }

    private lazy var shuttleAlertView = UIView().then {
        $0.layer.cornerRadius = 4
        $0.layer.masksToBounds = true
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.hanyangOrange.cgColor
        $0.isHidden = true
        $0.addSubview(self.shuttleAlertLabel)
    }

    private let lastRunLabel = UILabel().then {
        $0.font = .godo(size: 12, weight: .bold)
        $0.textColor = .white
        $0.text = String(localized: "shuttle.last_run")
        $0.textAlignment = .center
    }

    private lazy var lastRunView = UIView().then {
        $0.backgroundColor = .hanyangBlue
        $0.isHidden = true
        $0.isAccessibilityElement = true
        $0.accessibilityLabel = self.lastRunLabel.text
        $0.addSubview(self.lastRunLabel)
    }

    private let alarmButton = ExtendedHitAreaButton(type: .system).then {
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        $0.setImage(UIImage(systemName: "bell", withConfiguration: symbolConfiguration), for: .normal)
        if UITraitCollection.current.userInterfaceStyle == .light {
            $0.tintColor = .hanyangBlue
        } else {
            $0.tintColor = .white
        }
        $0.accessibilityLabel = String(localized: "shuttle.alarm.button.description")
    }

    var itemByOrder: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order?
    var itemByDestination: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry?
    private var showAlarm: (() -> Void)?
    private var isBoardingAlarmActive = false {
        didSet {
            updateAlarmButtonAppearance()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        observeSubjects()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        backgroundColor = .systemBackground
        contentView.backgroundColor = .systemBackground
        contentView.addSubview(shuttleTypeLabel)
        contentView.addSubview(shuttleTimeLabel)
        contentView.addSubview(shuttleAlertView)
        contentView.addSubview(lastRunView)
        contentView.addSubview(shuttleRemainingTimeLabel)
        contentView.addSubview(alarmButton)
        selectionStyle = .none
        alarmButton.addTarget(self, action: #selector(alarmButtonTapped), for: .touchUpInside)
        shuttleAlertLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
        lastRunView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(36)
        }
        lastRunLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        shuttleTypeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        shuttleAlertView.snp.makeConstraints { make in
            make.leading.equalTo(self.shuttleTypeLabel.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }
        shuttleTimeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(self.alarmButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
        shuttleRemainingTimeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(self.alarmButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
        alarmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        if UITraitCollection.current.userInterfaceStyle == .dark {
            alarmButton.tintColor = .white
        } else {
            alarmButton.tintColor = .hanyangBlue
        }
        updateAlarmButtonAppearance()
    }

    func setupUI(
        stopID: ShuttleStopEnum,
        indexPath: IndexPath,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order,
        isBoardingAlarmActive: Bool = false,
        showAlarm: @escaping () -> Void
    ) {
        shuttleAlertView.isHidden = true
        setLastRunVisible(isLastRun(stopID: stopID, indexPath: indexPath, item: item))
        itemByDestination = nil
        self.showAlarm = showAlarm
        self.isBoardingAlarmActive = isBoardingAlarmActive
        setTypeText(stopID: stopID, item: item)
        itemByOrder = item
        setUITimeLabel(time: item.time)
    }

    func setupUI(
        stopID: ShuttleStopEnum,
        indexPath: IndexPath,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry,
        isBoardingAlarmActive: Bool = false,
        showAlarm: @escaping () -> Void
    ) {
        shuttleAlertView.isHidden = true
        setLastRunVisible(isLastRun(stopID: stopID, indexPath: indexPath, item: item))
        itemByOrder = nil
        self.showAlarm = showAlarm
        self.isBoardingAlarmActive = isBoardingAlarmActive
        setTypeText(stopID: stopID, indexPath: indexPath, item: item)
        itemByDestination = item
        setUITimeLabel(time: item.time)
    }

    private func setLastRunVisible(_ isVisible: Bool) {
        lastRunView.isHidden = !isVisible
        shuttleTypeLabel.snp.remakeConstraints { make in
            if isVisible {
                make.leading.equalTo(self.lastRunView.snp.trailing).offset(12)
            } else {
                make.leading.equalToSuperview().inset(20)
            }
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
    }

    func setUITimeLabel(time: LocalTime) {
        guard let date = time.toLocalTimeOrNil() else {
            shuttleTimeLabel.text = time.substring(from: 0, to: 4)
            shuttleRemainingTimeLabel.text = String(localized: "shuttle.time.remaining.0")
            return
        }
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        guard let hour = components.hour,
              let minute = components.minute
        else {
            shuttleTimeLabel.text = time.substring(from: 0, to: 4)
            shuttleRemainingTimeLabel.text = String(localized: "shuttle.time.remaining.0")
            return
        }
        shuttleTimeLabel.text = String(format: String(localized: "shuttle.time.%lld.%lld"), hour, minute)
        let remainingTime = Int(date.timeIntervalSince(Foundation.Date.now))
        shuttleRemainingTimeLabel.text = String(format: String(localized: "shuttle.time.remaining.%lld"), remainingTime / 60)
    }

    private func setTypeText(stopID: ShuttleStopEnum, item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) {
        if stopID == .dormiotryOut || stopID == .shuttlecockOut {
            if item.route.tag == "DH" {
                shuttleTypeLabel.text = String(localized: "shuttle_type_school_station")
                shuttleTypeLabel.textColor = .busRed
            } else if item.route.tag == "DY" {
                shuttleTypeLabel.text = String(localized: "shuttle_type_school_terminal")
                shuttleTypeLabel.textColor = .hanyangOrange
                shuttleAlertView.isHidden = false
            } else if item.route.tag == "DJ" {
                shuttleTypeLabel.text = String(localized: "shuttle_type_school_jungang_station")
                shuttleTypeLabel.textColor = .hanyangGreen
            } else if item.route.tag == "C" {
                shuttleTypeLabel.text = String(localized: "shuttle_type_school_circular")
            }
        } else if stopID == .station {
            if item.route.tag == "DH" {
                if item.route.name.hasSuffix("S") {
                    shuttleTypeLabel.text = String(localized: "shuttle_type_shuttlecock")
                    shuttleTypeLabel.textColor = .busRed
                } else if item.route.name.hasSuffix("D") {
                    shuttleTypeLabel.text = String(localized: "shuttle_type_dormitory")
                    shuttleTypeLabel.textColor = .hanyangBlue
                }
            } else if item.route.tag == "DJ" {
                shuttleTypeLabel.text = String(localized: "shuttle_type_jungang_station")
                shuttleTypeLabel.textColor = .hanyangGreen
            } else if item.route.tag == "C" {
                if item.route.name.hasSuffix("S") {
                    shuttleTypeLabel.text = String(localized: "shuttle_type_station_circular_shuttlecock")
                } else if item.route.name.hasSuffix("D") {
                    shuttleTypeLabel.text = String(localized: "shuttle_type_station_circular_dormitory")
                }
            }
        } else if stopID == .terminal {
            if item.route.name.hasSuffix("S") {
                shuttleTypeLabel.text = String(localized: "shuttle_type_shuttlecock")
            } else if item.route.name.hasSuffix("D") {
                shuttleTypeLabel.text = String(localized: "shuttle_type_dormitory")
            }
        } else if stopID == .jungangStation {
            shuttleTypeLabel.text = String(localized: "shuttle_type_dormitory")
        } else if stopID == .shuttlecockIn {
            if item.route.name.hasSuffix("S") {
                shuttleTypeLabel.text = String(localized: "shuttle_type_shuttlecock_finishing")
            } else if item.route.name.hasSuffix("D") {
                shuttleTypeLabel.text = String(localized: "shuttle_type_dormitory")
            }
        }
    }

    func observeSubjects() {
        ShuttleRealtimeData.shared.showRemainingTime.subscribe(onNext: { [weak self] showRemainingTime in
            self?.shuttleTimeLabel.isHidden = !showRemainingTime
            self?.shuttleRemainingTimeLabel.isHidden = showRemainingTime
        }).disposed(by: disposeBag)
    }

    @objc private func alarmButtonTapped() {
        showAlarm?()
    }

    private func updateAlarmButtonAppearance() {
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        let imageName = isBoardingAlarmActive ? "bell.fill" : "bell"
        alarmButton.setImage(UIImage(systemName: imageName, withConfiguration: symbolConfiguration), for: .normal)
        alarmButton.accessibilityValue = isBoardingAlarmActive ? String(localized: "shuttle.alarm.cancel") : nil
    }
}

extension ShuttleRealtimeCellView {
    private func setTypeText(
        stopID: ShuttleStopEnum,
        indexPath: IndexPath,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry
    ) {
        if stopID == .dormiotryOut || stopID == .shuttlecockOut {
            setCampusDepartureTypeText(section: indexPath.section, item: item)
        } else if stopID == .station {
            setStationDepartureTypeText(section: indexPath.section, item: item)
        } else if stopID == .terminal || stopID == .jungangStation || stopID == .shuttlecockIn {
            setCampusBoundTypeText(item: item)
        }
    }

    private func setCampusDepartureTypeText(
        section: Int,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry
    ) {
        if section == 0 {
            if item.route.tag == "DH" || item.route.tag == "DJ" {
                shuttleTypeLabel.text = String(localized: "shuttle.type.direct")
                shuttleTypeLabel.textColor = .busRed
            } else if item.route.tag == "C" {
                shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
                shuttleTypeLabel.textColor = circularTextColor
            }
        } else if section == 1 {
            if item.route.tag == "DY" {
                shuttleTypeLabel.text = String(localized: "shuttle.type.direct")
                shuttleTypeLabel.textColor = .busRed
            } else if item.route.tag == "C" {
                shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
                shuttleTypeLabel.textColor = circularTextColor
            }
        } else if section == 2 {
            shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
            shuttleTypeLabel.textColor = .hanyangGreen
        }
    }

    private func setStationDepartureTypeText(
        section: Int,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry
    ) {
        if section == 0 {
            setStationCampusRouteTypeText(item: item)
        } else if section == 1 {
            setStationTerminalRouteTypeText(item: item)
        } else if section == 2 {
            shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
            shuttleTypeLabel.textColor = .hanyangGreen
        }
    }

    private func setStationCampusRouteTypeText(item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) {
        if item.route.tag == "DH" {
            if item.route.name.hasSuffix("D") {
                shuttleTypeLabel.text = String(localized: "shuttle.type.direct.dormitory")
            } else if item.route.name.hasSuffix("S") {
                shuttleTypeLabel.text = String(localized: "shuttle.type.direct.shuttlecock")
            }
            shuttleTypeLabel.textColor = .busRed
        } else if item.route.tag == "DJ" {
            shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
            shuttleTypeLabel.textColor = .hanyangGreen
        } else if item.route.tag == "C" {
            if item.route.name.hasSuffix("D") {
                shuttleTypeLabel.text = String(localized: "shuttle.type.circular.dormitory")
            } else if item.route.name.hasSuffix("S") {
                shuttleTypeLabel.text = String(localized: "shuttle.type.circular.shuttlecock")
            }
            shuttleTypeLabel.textColor = circularTextColor
        }
    }

    private func setStationTerminalRouteTypeText(item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) {
        if item.route.name.hasSuffix("D") {
            shuttleTypeLabel.text = String(localized: "shuttle.type.circular.dormitory")
        } else if item.route.name.hasSuffix("S") {
            shuttleTypeLabel.text = String(localized: "shuttle.type.circular.shuttlecock")
        }
        shuttleTypeLabel.textColor = circularTextColor
    }

    private func setCampusBoundTypeText(item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) {
        if item.route.name.hasSuffix("S") {
            shuttleTypeLabel.text = String(localized: "shuttle.type.shuttlecock")
        } else if item.route.name.hasSuffix("D") {
            shuttleTypeLabel.text = String(localized: "shuttle.type.dormitory")
        }
    }

    private var circularTextColor: UIColor {
        UITraitCollection.current.userInterfaceStyle == .light ? .busBlue : .white
    }

    private func isLastRun(
        stopID: ShuttleStopEnum,
        indexPath _: IndexPath,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order
    ) -> Bool {
        let data: [ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]? = switch stopID {
        case .dormiotryOut:
            try? ShuttleRealtimeData.shared.shuttleDormitoryData.value()
        case .shuttlecockOut:
            try? ShuttleRealtimeData.shared.shuttleShuttlecockData.value()
        case .station:
            try? ShuttleRealtimeData.shared.shuttleStationData.value()
        case .terminal:
            try? ShuttleRealtimeData.shared.shuttleTerminalData.value()
        case .jungangStation:
            try? ShuttleRealtimeData.shared.shuttleJungangStationData.value()
        case .shuttlecockIn:
            try? ShuttleRealtimeData.shared.shuttleShuttlecockInData.value()
        }
        return data?.last?.seq == item.seq
    }

    private func isLastRun(
        stopID: ShuttleStopEnum,
        indexPath: IndexPath,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry
    ) -> Bool {
        let data: [ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]? = switch (stopID, indexPath.section) {
        case (.dormiotryOut, 0):
            try? ShuttleRealtimeData.shared.shuttleDormitoryToStationData.value()
        case (.dormiotryOut, 1):
            try? ShuttleRealtimeData.shared.shuttleDormitoryToTerminalData.value()
        case (.dormiotryOut, 2):
            try? ShuttleRealtimeData.shared.shuttleDormitoryToJungangStationData.value()
        case (.shuttlecockOut, 0):
            try? ShuttleRealtimeData.shared.shuttleShuttlecockToStationData.value()
        case (.shuttlecockOut, 1):
            try? ShuttleRealtimeData.shared.shuttleShuttlecockToTerminalData.value()
        case (.shuttlecockOut, 2):
            try? ShuttleRealtimeData.shared.shuttleShuttlecockToJungangStationData.value()
        case (.station, 0):
            try? ShuttleRealtimeData.shared.shuttleStationToCampusData.value()
        case (.station, 1):
            try? ShuttleRealtimeData.shared.shuttleStationToTerminalData.value()
        case (.station, 2):
            try? ShuttleRealtimeData.shared.shuttleStationToJungangStationData.value()
        case (.terminal, 0):
            try? ShuttleRealtimeData.shared.shuttleTerminalToCampusData.value()
        case (.jungangStation, 0):
            try? ShuttleRealtimeData.shared.shuttleJungangStationToCampusData.value()
        case (.shuttlecockIn, 0):
            try? ShuttleRealtimeData.shared.shuttleShuttlecockInToDormitoryData.value()
        default:
            nil
        }
        return data?.last?.seq == item.seq
    }
}
