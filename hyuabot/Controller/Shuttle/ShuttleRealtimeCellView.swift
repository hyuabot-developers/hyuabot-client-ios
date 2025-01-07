import UIKit
import QueryAPI

class ShuttleRealtimeCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleRealtimeCellView"
    private let shuttleTypeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
    }
    private let shuttleTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.contentView.addSubview(self.shuttleTypeLabel)
        self.contentView.addSubview(self.shuttleTimeLabel)
        self.shuttleTypeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        self.shuttleTimeLabel.snp.makeConstraints { make in
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
                }
            } else if indexPath.section == 1 {
                self.shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
            } else if indexPath.section == 2 {
                self.shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
            }
        } else if (stopID == .terminal || stopID == .jungangStation || stopID == .shuttlecockIn) {
            if (item.route.hasSuffix("S")) {
                self.shuttleTypeLabel.text = String(localized: "shuttle.type.shuttlecock")
            } else if (item.route.hasSuffix("D")) {
                self.shuttleTypeLabel.text = String(localized: "shuttle.type.dormitory")
            }
        }
        self.setUITimeLabel(item: item)
    }
    
    func setUITimeLabel(item: ShuttleRealtimePageQuery.Data.Shuttle.Timetable) {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let departureTime = dateFormatter.date(from: item.time)
        let hour = calendar.component(.hour, from: departureTime!)
        let minute = calendar.component(.minute, from: departureTime!)
        self.shuttleTimeLabel.text = String(localized: "shuttle.time.\(hour).\(minute)")
    }
}
