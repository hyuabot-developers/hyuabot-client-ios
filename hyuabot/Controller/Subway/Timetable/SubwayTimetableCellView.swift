import UIKit
import QueryAPI

class SubwayTimetableCellView: UITableViewCell {
    static let reuseIdentifier = "SubwayTimetableCellView"
    private let destinationLabel = UILabel().then{
        $0.font = .godo(size: 16, weight: .regular)
    }
    private let departureTimeLabel = UILabel().then{
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
        self.contentView.addSubview(destinationLabel)
        self.contentView.addSubview(departureTimeLabel)
        self.selectionStyle = .none
        self.destinationLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        self.departureTimeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }
    
    func setupUI(
        up: SubwayTimetablePageUpQuery.Data.Subway.Timetable.Up? = nil,
        down: SubwayTimetablePageDownQuery.Data.Subway.Timetable.Down? = nil
    ) {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        
        self.destinationLabel.text = getDestinationLabelText(up?.terminal.id ?? down?.terminal.id ?? "")
        self.setUITimeLabel(dateFormatter.string(from: Date.now), up, down)
    }
    
    func getDestinationLabelText(_ stationID: String) -> String {
        var stationName = ""
        switch stationID {
            case "K209" : stationName = String(localized: "subway.station.k209")
            case "K210" : stationName = String(localized: "subway.station.k210")
            case "K233" : stationName = String(localized: "subway.station.k233")
            case "K246" : stationName = String(localized: "subway.station.k246")
            case "K258" : stationName = String(localized: "subway.station.k258")
            case "K272" : stationName = String(localized: "subway.station.k272")
            case "K409" : stationName = String(localized: "subway.station.k409")
            case "K411" : stationName = String(localized: "subway.station.k411")
            case "K419" : stationName = String(localized: "subway.station.k419")
            case "K433" : stationName = String(localized: "subway.station.k433")
            case "K443" : stationName = String(localized: "subway.station.k443")
            case "K444" : stationName = String(localized: "subway.station.k444")
            case "K453" : stationName = String(localized: "subway.station.k453")
            case "K456" : stationName = String(localized: "subway.station.k456")
            default: return String(localized: "subway.station.\(stationID)")
        }
        return stationName
    }
    
    func setUITimeLabel(
        _ currentTime: String,
        _ up: SubwayTimetablePageUpQuery.Data.Subway.Timetable.Up? = nil,
        _ down: SubwayTimetablePageDownQuery.Data.Subway.Timetable.Down? = nil
    ) {
        if (up != nil) {
            if currentTime > up!.time {
                self.departureTimeLabel.textColor = .gray
            } else {
                self.departureTimeLabel.textColor = .label
            }
            var hour = up!.hour
            if hour < 4 {
                hour += 24
            }
            self.departureTimeLabel.text = String(localized: "subway.time.\(hour).\(up!.minute)")
        } else {
            var hour = down!.hour
            if hour < 4 {
                hour += 24
            }
            if currentTime > down!.time {
                self.departureTimeLabel.textColor = .gray
            } else {
                self.departureTimeLabel.textColor = .label
            }
            self.departureTimeLabel.text = String(localized: "subway.time.\(hour).\(down!.minute)")
        }
    }
}
