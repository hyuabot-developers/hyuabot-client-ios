import UIKit
import QueryAPI

class ShuttleTimetableCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleTimetableCellView"
    var item: ShuttleTimetablePageQuery.Data.Shuttle.Timetable?
    private let shuttleTypeLabel = UILabel().then{
        $0.font = .godo(size: 16, weight: .regular)
    }
    private let shuttleTimeLabel = UILabel().then{
        $0.font = .godo(size: 16, weight: .regular)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.contentView.addSubview(shuttleTypeLabel)
        self.contentView.addSubview(shuttleTimeLabel)
        self.selectionStyle = .none
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
    
    func setupUI(option: ShuttleTimetableOptions, item: ShuttleTimetablePageQuery.Data.Shuttle.Timetable) {
        if (option.start == "shuttle.stop.dormitory.out" || option.start == "shuttle.stop.shuttlecock.out") {
            if option.end == "shuttle.destination.shorten.station" {
                if item.tag == "DH" || item.tag == "DJ" {
                    self.shuttleTypeLabel.text = String(localized: "shuttle.type.direct")
                    self.shuttleTypeLabel.textColor = .busRed
                }
                else if item.tag == "C" {
                    self.shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
                    self.shuttleTypeLabel.textColor = .busBlue
                }
            } else if option.end == "shuttle.destination.shorten.terminal" {
                if item.tag == "DY" {
                    self.shuttleTypeLabel.text = String(localized: "shuttle.type.direct")
                    self.shuttleTypeLabel.textColor = .busRed
                }
                else if item.tag == "C" {
                    self.shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
                    self.shuttleTypeLabel.textColor = .busBlue
                }
            } else if option.end == "shuttle.destination.shorten.jungang_station" {
                self.shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
                self.shuttleTypeLabel.textColor = .hanyangGreen
            }
        } else if (option.start == "shuttle.stop.station") {
            if option.end == "shuttle.destination.shorten.campus" {
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
            } else if option.end == "shuttle.destination.shorten.terminal" {
                self.shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
                self.shuttleTypeLabel.textColor = .busBlue
            } else if option.end == "shuttle.destination.shorten.jungang_station" {
                self.shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
                self.shuttleTypeLabel.textColor = .hanyangGreen
            }
        } else if (option.start == "shuttle.stop.terminal" || option.start == "shuttle.stop.jungang.station" || option.start == "shuttle.stop.shuttlecock.in") {
            self.shuttleTypeLabel.textColor = .label
            if (item.route.hasSuffix("S")) {
                self.shuttleTypeLabel.text = String(localized: "shuttle.type.shuttlecock")
            } else if (item.route.hasSuffix("D")) {
                self.shuttleTypeLabel.text = String(localized: "shuttle.type.dormitory")
            }
        }
        self.item = item
        self.shuttleTimeLabel.text = String(localized: "shuttle.time.\(item.hour).\(item.minute)")
    }
}
