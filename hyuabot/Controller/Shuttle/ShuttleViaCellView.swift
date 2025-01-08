import UIKit
import QueryAPI
import RxSwift

class ShuttleViaCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleViaCellView"
    private let shuttleStopLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
    }
    private let shuttleTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
    }
    var item: ShuttleRealtimePageQuery.Data.Shuttle.Timetable.Vium?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.contentView.addSubview(self.shuttleStopLabel)
        self.contentView.addSubview(self.shuttleTimeLabel)
        self.selectionStyle = .none
        self.shuttleStopLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        self.shuttleTimeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }
    
    func setupUI(startStop: ShuttleRealtimePageQuery.Data.Shuttle.Timetable, item: ShuttleRealtimePageQuery.Data.Shuttle.Timetable.Vium) {
        if item.stop == "dormitory_o" {
            self.shuttleStopLabel.text = String(localized: "shuttle.stop.dormitory.out")
        } else if item.stop == "shuttlecock_o" {
            self.shuttleStopLabel.text = String(localized: "shuttle.stop.shuttlecock.out")
        } else if item.stop == "station" {
            self.shuttleStopLabel.text = String(localized: "shuttle.stop.station")
        } else if item.stop == "terminal" {
            self.shuttleStopLabel.text = String(localized: "shuttle.stop.terminal")
        } else if item.stop == "jungang_stn" {
            self.shuttleStopLabel.text = String(localized: "shuttle.stop.jungang.station")
        } else if item.stop == "shuttlecock_i" {
            self.shuttleStopLabel.text = String(localized: "shuttle.stop.shuttlecock.in")
        } else {
            self.shuttleStopLabel.text = String(localized: "shuttle.stop.dormitory.out")
        }
        self.setUITimeLabel(item: item)
        if (startStop.time > item.time) {
            self.shuttleStopLabel.textColor = .gray
            self.shuttleTimeLabel.textColor = .gray
        }
    }
    
    func setUITimeLabel(item: ShuttleRealtimePageQuery.Data.Shuttle.Timetable.Vium) {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let departureTime = dateFormatter.date(from: item.time)
        let hour = calendar.component(.hour, from: departureTime!)
        let minute = calendar.component(.minute, from: departureTime!)
        self.shuttleTimeLabel.text = String(localized: "shuttle.shorten.time.\(hour).\(minute)")
    }
}
