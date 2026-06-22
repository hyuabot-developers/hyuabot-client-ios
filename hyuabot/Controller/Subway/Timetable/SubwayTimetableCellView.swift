import UIKit
import Api

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
    
    func setupUI(item: SubwayTimetablePageQuery.Data.Subway.Timetable) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        
        self.destinationLabel.text = getDestinationLabelText(item.terminal.stationID, fallback: item.terminal.name)
        self.setUITimeLabel(dateFormatter.string(from: Date.now), item)
    }
    
    func getDestinationLabelText(_ stationID: String, fallback: String) -> String {
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
            default:
                let key = "subway.station.\(stationID.lowercased())"
                let localized = String(localized: String.LocalizationValue(stringLiteral: key))
                return localized == key ? fallback : localized
        }
        return stationName
    }
    
    func setUITimeLabel(
        _ currentTime: String,
        _ item: SubwayTimetablePageQuery.Data.Subway.Timetable,
    ) {
        guard let timetableTime = item.time.toLocalTimeOrNil(),
              let currentDepartureTime = convertDepartureTime(currentTime),
              let timetableDepartureTime = convertDepartureTime(item.time) else {
            self.departureTimeLabel.textColor = .label
            self.departureTimeLabel.text = item.time
            return
        }

        let component = Calendar.current.dateComponents([.hour, .minute], from: timetableTime)
        if currentDepartureTime > timetableDepartureTime {
            self.departureTimeLabel.textColor = .gray
        } else {
            self.departureTimeLabel.textColor = .label
        }
        guard var hour = component.hour,
              let minute = component.minute else {
            self.departureTimeLabel.text = item.time
            return
        }
        if hour < 4 {
            hour += 24
        }
        self.departureTimeLabel.text = String(format: String(localized: "subway.time.%lld.%lld"), hour, minute)
    }
    
    private func convertDepartureTime(_ time: String) -> String? {
        guard let date = time.toLocalTimeOrNil() else { return nil }
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour,
              let minute = components.minute else { return nil }
        if hour < 4 {
            return String(format: "%02d:%02d", hour + 24, minute)
        }
        return String(format: "%02d:%02d", hour, minute)
    }
}
