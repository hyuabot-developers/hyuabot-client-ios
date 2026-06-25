import Api
import RxSwift
import UIKit

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

    private let alarmButton = UIButton(type: .system).then {
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
        contentView.addSubview(shuttleTypeLabel)
        contentView.addSubview(shuttleTimeLabel)
        contentView.addSubview(shuttleAlertView)
        contentView.addSubview(shuttleRemainingTimeLabel)
        contentView.addSubview(alarmButton)
        selectionStyle = .none
        alarmButton.addTarget(self, action: #selector(alarmButtonTapped), for: .touchUpInside)
        shuttleAlertLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
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
        itemByOrder = nil
        self.showAlarm = showAlarm
        self.isBoardingAlarmActive = isBoardingAlarmActive
        if stopID == .dormiotryOut || stopID == .shuttlecockOut {
            if indexPath.section == 0 {
                if item.route.tag == "DH" || item.route.tag == "DJ" {
                    shuttleTypeLabel.text = String(localized: "shuttle.type.direct")
                    shuttleTypeLabel.textColor = .busRed
                } else if item.route.tag == "C" {
                    shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
                    // Check dark mode
                    if UITraitCollection.current.userInterfaceStyle == .light {
                        shuttleTypeLabel.textColor = .busBlue
                    } else {
                        shuttleTypeLabel.textColor = .white
                    }
                }
            } else if indexPath.section == 1 {
                if item.route.tag == "DY" {
                    shuttleTypeLabel.text = String(localized: "shuttle.type.direct")
                    shuttleTypeLabel.textColor = .busRed
                } else if item.route.tag == "C" {
                    shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
                    if UITraitCollection.current.userInterfaceStyle == .light {
                        shuttleTypeLabel.textColor = .busBlue
                    } else {
                        shuttleTypeLabel.textColor = .white
                    }
                }
            } else if indexPath.section == 2 {
                shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
                shuttleTypeLabel.textColor = .hanyangGreen
            }
        } else if stopID == .station {
            if indexPath.section == 0 {
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
                    if UITraitCollection.current.userInterfaceStyle == .light {
                        shuttleTypeLabel.textColor = .busBlue
                    } else {
                        shuttleTypeLabel.textColor = .white
                    }
                }
            } else if indexPath.section == 1 {
                if item.route.name.hasSuffix("D") {
                    shuttleTypeLabel.text = String(localized: "shuttle.type.circular.dormitory")
                } else if item.route.name.hasSuffix("S") {
                    shuttleTypeLabel.text = String(localized: "shuttle.type.circular.shuttlecock")
                }
                if UITraitCollection.current.userInterfaceStyle == .light {
                    shuttleTypeLabel.textColor = .busBlue
                } else {
                    shuttleTypeLabel.textColor = .white
                }
            } else if indexPath.section == 2 {
                shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
                shuttleTypeLabel.textColor = .hanyangGreen
            }
        } else if stopID == .terminal || stopID == .jungangStation || stopID == .shuttlecockIn {
            if item.route.name.hasSuffix("S") {
                shuttleTypeLabel.text = String(localized: "shuttle.type.shuttlecock")
            } else if item.route.name.hasSuffix("D") {
                shuttleTypeLabel.text = String(localized: "shuttle.type.dormitory")
            }
        }
        itemByDestination = item
        setUITimeLabel(time: item.time)
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
