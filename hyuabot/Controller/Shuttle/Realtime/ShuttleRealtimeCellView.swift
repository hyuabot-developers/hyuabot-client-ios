import UIKit
import Api
import RxSwift

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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
        self.observeSubjects()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.contentView.addSubview(self.shuttleTypeLabel)
        self.contentView.addSubview(self.shuttleTimeLabel)
        self.contentView.addSubview(self.shuttleAlertView)
        self.contentView.addSubview(self.shuttleRemainingTimeLabel)
        self.contentView.addSubview(self.alarmButton)
        self.selectionStyle = .none
        self.alarmButton.addTarget(self, action: #selector(alarmButtonTapped), for: .touchUpInside)
        self.shuttleAlertLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
        self.shuttleTypeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        self.shuttleAlertView.snp.makeConstraints { make in
            make.leading.equalTo(self.shuttleTypeLabel.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }
        self.shuttleTimeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(self.alarmButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
        self.shuttleRemainingTimeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(self.alarmButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
        self.alarmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        if (UITraitCollection.current.userInterfaceStyle == .dark) {
            self.alarmButton.tintColor = .white
        } else {
            self.alarmButton.tintColor = .hanyangBlue
        }
    }
    
    func setupUI(stopID: ShuttleStopEnum, indexPath: IndexPath, item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order, showAlarm: @escaping () -> Void) {
        self.shuttleAlertView.isHidden = true
        self.itemByDestination = nil
        self.showAlarm = showAlarm
        self.setTypeText(stopID: stopID, item: item)
        self.itemByOrder = item
        self.setUITimeLabel(time: item.time)
    }
    
    func setupUI(stopID: ShuttleStopEnum, indexPath: IndexPath, item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry, showAlarm: @escaping () -> Void) {
        self.shuttleAlertView.isHidden = true
        self.itemByOrder = nil
        self.showAlarm = showAlarm
        if (stopID == .dormiotryOut || stopID == .shuttlecockOut) {
            if indexPath.section == 0 {
                if item.route.tag == "DH" || item.route.tag == "DJ" {
                    self.shuttleTypeLabel.text = String(localized: "shuttle.type.direct")
                    self.shuttleTypeLabel.textColor = .busRed
                }
                else if item.route.tag == "C" {
                    self.shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
                    // Check dark mode
                    if UITraitCollection.current.userInterfaceStyle == .light {
                        self.shuttleTypeLabel.textColor = .busBlue
                    } else {
                        self.shuttleTypeLabel.textColor = .white
                    }
                }
            } else if indexPath.section == 1 {
                if item.route.tag == "DY" {
                    self.shuttleTypeLabel.text = String(localized: "shuttle.type.direct")
                    self.shuttleTypeLabel.textColor = .busRed
                }
                else if item.route.tag == "C" {
                    self.shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
                    if UITraitCollection.current.userInterfaceStyle == .light {
                        self.shuttleTypeLabel.textColor = .busBlue
                    } else {
                        self.shuttleTypeLabel.textColor = .white
                    }
                }
            } else if indexPath.section == 2 {
                self.shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
                self.shuttleTypeLabel.textColor = .hanyangGreen
            }
        } else if (stopID == .station) {
            if indexPath.section == 0 {
                if item.route.tag == "DH" {
                    if item.route.name.hasSuffix("D") {
                        self.shuttleTypeLabel.text = String(localized: "shuttle.type.direct.dormitory")
                    } else if item.route.name.hasSuffix("S") {
                        self.shuttleTypeLabel.text = String(localized: "shuttle.type.direct.shuttlecock")
                    }
                    self.shuttleTypeLabel.textColor = .busRed
                } else if item.route.tag == "DJ" {
                    self.shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
                    self.shuttleTypeLabel.textColor = .hanyangGreen
                } else if item.route.tag == "C" {
                    if item.route.name.hasSuffix("D") {
                        self.shuttleTypeLabel.text = String(localized: "shuttle.type.circular.dormitory")
                    } else if item.route.name.hasSuffix("S") {
                        self.shuttleTypeLabel.text = String(localized: "shuttle.type.circular.shuttlecock")
                    }
                    if UITraitCollection.current.userInterfaceStyle == .light {
                        self.shuttleTypeLabel.textColor = .busBlue
                    } else {
                        self.shuttleTypeLabel.textColor = .white
                    }
                }
            } else if indexPath.section == 1 {
                if item.route.name.hasSuffix("D") {
                    self.shuttleTypeLabel.text = String(localized: "shuttle.type.circular.dormitory")
                } else if item.route.name.hasSuffix("S") {
                    self.shuttleTypeLabel.text = String(localized: "shuttle.type.circular.shuttlecock")
                }
                if UITraitCollection.current.userInterfaceStyle == .light {
                    self.shuttleTypeLabel.textColor = .busBlue
                } else {
                    self.shuttleTypeLabel.textColor = .white
                }
            } else if indexPath.section == 2 {
                self.shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
                self.shuttleTypeLabel.textColor = .hanyangGreen
            }
        } else if (stopID == .terminal || stopID == .jungangStation || stopID == .shuttlecockIn) {
            if (item.route.name.hasSuffix("S")) {
                self.shuttleTypeLabel.text = String(localized: "shuttle.type.shuttlecock")
            } else if (item.route.name.hasSuffix("D")) {
                self.shuttleTypeLabel.text = String(localized: "shuttle.type.dormitory")
            }
        }
        self.itemByDestination = item
        self.setUITimeLabel(time: item.time)
    }
    
    func setUITimeLabel(time: LocalTime) {
        guard let date = time.toLocalTimeOrNil() else {
            self.shuttleTimeLabel.text = time.substring(from: 0, to: 4)
            self.shuttleRemainingTimeLabel.text = String(localized: "shuttle.time.remaining.0")
            return
        }
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        guard let hour = components.hour,
              let minute = components.minute else {
            self.shuttleTimeLabel.text = time.substring(from: 0, to: 4)
            self.shuttleRemainingTimeLabel.text = String(localized: "shuttle.time.remaining.0")
            return
        }
        self.shuttleTimeLabel.text = String(localized: "shuttle.time.\(hour).\(minute)")
        let remainingTime = Int(date.timeIntervalSince(Foundation.Date.now))
        self.shuttleRemainingTimeLabel.text = String(localized: "shuttle.time.remaining.\(remainingTime / 60)")
    }
    
    private func setTypeText(stopID: ShuttleStopEnum, item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) {
        if (stopID == .dormiotryOut || stopID == .shuttlecockOut) {
            if (item.route.tag == "DH") {
                self.shuttleTypeLabel.text = String(localized: "shuttle_type_school_station")
                self.shuttleTypeLabel.textColor = .busRed
            } else if (item.route.tag == "DY") {
                self.shuttleTypeLabel.text = String(localized: "shuttle_type_school_terminal")
                self.shuttleTypeLabel.textColor = .hanyangOrange
                self.shuttleAlertView.isHidden = false
            } else if (item.route.tag == "DJ") {
                self.shuttleTypeLabel.text = String(localized: "shuttle_type_school_jungang_station")
                self.shuttleTypeLabel.textColor = .hanyangGreen
            } else if (item.route.tag == "C") {
                self.shuttleTypeLabel.text = String(localized: "shuttle_type_school_circular")
            }
        }
        else if (stopID == .station) {
            if (item.route.tag == "DH") {
                if (item.route.name.hasSuffix("S")) {
                    self.shuttleTypeLabel.text = String(localized: "shuttle_type_shuttlecock")
                    self.shuttleTypeLabel.textColor = .busRed
                } else if (item.route.name.hasSuffix("D")) {
                    self.shuttleTypeLabel.text = String(localized: "shuttle_type_dormitory")
                    self.shuttleTypeLabel.textColor = .hanyangBlue
                }
            } else if (item.route.tag == "DJ") {
                self.shuttleTypeLabel.text = String(localized: "shuttle_type_jungang_station")
                self.shuttleTypeLabel.textColor = .hanyangGreen
            } else if (item.route.tag == "C") {
                if (item.route.name.hasSuffix("S")) {
                    self.shuttleTypeLabel.text = String(localized: "shuttle_type_station_circular_shuttlecock")
                } else if (item.route.name.hasSuffix("D")) {
                    self.shuttleTypeLabel.text = String(localized: "shuttle_type_station_circular_dormitory")
                }
            }
        }
        else if (stopID == .terminal) {
            if (item.route.name.hasSuffix("S")) {
                self.shuttleTypeLabel.text = String(localized: "shuttle_type_shuttlecock")
            } else if (item.route.name.hasSuffix("D")) {
                self.shuttleTypeLabel.text = String(localized: "shuttle_type_dormitory")
            }
        }
        else if (stopID == .jungangStation) {
            self.shuttleTypeLabel.text = String(localized: "shuttle_type_dormitory")
        }
        else if (stopID == .shuttlecockIn) {
            if (item.route.name.hasSuffix("S")) {
                self.shuttleTypeLabel.text = String(localized: "shuttle_type_shuttlecock_finishing")
            } else if (item.route.name.hasSuffix("D")) {
                self.shuttleTypeLabel.text = String(localized: "shuttle_type_dormitory")
            }
        }
    }
        
    
    func observeSubjects() {
        ShuttleRealtimeData.shared.showRemainingTime.subscribe(onNext: { [weak self] showRemainingTime in
            self?.shuttleTimeLabel.isHidden = !showRemainingTime
            self?.shuttleRemainingTimeLabel.isHidden = showRemainingTime
        }).disposed(by: self.disposeBag)
    }

    @objc private func alarmButtonTapped() {
        self.showAlarm?()
    }
}
