import UIKit
import QueryAPI
import RxSwift

class BusRealtimeCellView: UITableViewCell {
    static let reuseIdentifier = "BusRealtimeCellView"
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
    var item: ShuttleRealtimePageQuery.Data.Shuttle.Timetable?
    
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
        self.contentView.addSubview(self.shuttleRemainingTimeLabel)
        self.selectionStyle = .none
        self.contentView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longTouch)))
        self.shuttleTypeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        self.shuttleTimeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        self.shuttleRemainingTimeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }
    
    func setupUI(stopID: ShuttleStopEnum, indexPath: IndexPath, item: ShuttleRealtimePageQuery.Data.Shuttle.Timetable) {
        if (stopID == .dormiotryOut || stopID == .shuttlecockOut) {
            if indexPath.section == 0 {
                if item.tag == "DH" || item.tag == "DJ" {
                    self.shuttleTypeLabel.text = String(localized: "shuttle.type.direct")
                    self.shuttleTypeLabel.textColor = .busRed
                }
                else if item.tag == "C" {
                    self.shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
                    self.shuttleTypeLabel.textColor = .busBlue
                }
            } else if indexPath.section == 1 {
                if item.tag == "DY" {
                    self.shuttleTypeLabel.text = String(localized: "shuttle.type.direct")
                    self.shuttleTypeLabel.textColor = .busRed
                }
                else if item.tag == "C" {
                    self.shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
                    self.shuttleTypeLabel.textColor = .busBlue
                }
            } else if indexPath.section == 2 {
                self.shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
                self.shuttleTypeLabel.textColor = .hanyangGreen
            }
        } else if (stopID == .station) {
            if indexPath.section == 0 {
                if item.tag == "DH" {
                    self.shuttleTypeLabel.text = String(localized: "shuttle.type.direct")
                    self.shuttleTypeLabel.textColor = .busRed
                } else if item.tag == "DJ" {
                    self.shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
                    self.shuttleTypeLabel.textColor = .hanyangGreen
                } else if item.tag == "C" {
                    self.shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
                    self.shuttleTypeLabel.textColor = .busBlue
                }
            } else if indexPath.section == 1 {
                self.shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
                self.shuttleTypeLabel.textColor = .busBlue
            } else if indexPath.section == 2 {
                self.shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
                self.shuttleTypeLabel.textColor = .hanyangGreen
            }
        } else if (stopID == .terminal || stopID == .jungangStation || stopID == .shuttlecockIn) {
            if (item.route.hasSuffix("S")) {
                self.shuttleTypeLabel.text = String(localized: "shuttle.type.shuttlecock")
            } else if (item.route.hasSuffix("D")) {
                self.shuttleTypeLabel.text = String(localized: "shuttle.type.dormitory")
            }
        }
        self.item = item
        self.setUITimeLabel(item: item)
    }
    
    func setUITimeLabel(item: ShuttleRealtimePageQuery.Data.Shuttle.Timetable) {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let departureTime = dateFormatter.date(from: item.time)
        let hour = calendar.component(.hour, from: departureTime!)
        let minute = calendar.component(.minute, from: departureTime!)
        let second = calendar.component(.second, from: departureTime!)
        self.shuttleTimeLabel.text = String(localized: "shuttle.time.\(hour).\(minute)")
        let remainingTime = (hour * 3600 + minute * 60 + second) - (calendar.component(.hour, from: Date.now) * 3600 + calendar.component(.minute, from: Date.now) * 60 + calendar.component(.second, from: Date.now)) // in seconds
        self.shuttleRemainingTimeLabel.text = String(localized: "shuttle.time.remaining.\(remainingTime / 60)")
    }
    
    @objc func longTouch(_ recognizer: UILongPressGestureRecognizer) {
        if (recognizer.state == .began) {
            ShuttleRealtimeData.shared.showRemainingTime.onNext(true)
        } else if (recognizer.state == .ended) {
            ShuttleRealtimeData.shared.showRemainingTime.onNext(false)
        }
    }
        
    
    func observeSubjects() {
        ShuttleRealtimeData.shared.showRemainingTime.subscribe(onNext: { [weak self] showRemainingTime in
            self?.shuttleTimeLabel.isHidden = !showRemainingTime
            self?.shuttleRemainingTimeLabel.isHidden = showRemainingTime
        }).disposed(by: self.disposeBag)
    }
}
