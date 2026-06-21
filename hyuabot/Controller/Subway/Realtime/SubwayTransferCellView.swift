import UIKit
import Api
import RxSwift

class SubwayTransferCellView: UITableViewCell {
    static let reuseIdentifier = "SubwayTransferCellView"
    private let fromLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
    }
    private let arrowLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.text = "→"
        $0.isHidden = true
    }
    private let toLabel = UILabel().then {
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
        self.contentView.addSubview(self.fromLabel)
        self.contentView.addSubview(self.arrowLabel)
        self.contentView.addSubview(self.toLabel)
        self.selectionStyle = .none
        self.fromLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        self.toLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        self.arrowLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    
    func setupUI(item: SubwayTransferItem, direction: String) {
        if let transfer = item.transfer {
            self.arrowLabel.isHidden = false
            self.fromLabel.text = takeLabelText(item.take, direction: direction)
            self.toLabel.text = String(
                localized: "subway.transfer.timetable.\(getDestinationLabelText(transfer.terminal.stationID)).\(getTimetableLabelText(transfer.minutes))"
            )
        } else {
            self.arrowLabel.isHidden = true
            self.toLabel.text = ""
            self.fromLabel.text = takeLabelText(item.take, direction: direction)
        }
    }

    private func takeLabelText(_ entry: SubwayRealtimePageQuery.Data.Subway.Arrival.Entry, direction: String) -> String {
        let destination = getDestinationLabelText(entry.terminal.stationID)
        let arrivalText: String
        if direction == "up" {
            arrivalText = entry.location ?? getTimetableLabelText(entry.minutes)
        } else if let location = entry.location {
            arrivalText = getRealtimeLabelText(entry.minutes, location)
        } else {
            arrivalText = getTimetableLabelText(entry.minutes)
        }
        if direction == "up" {
            return String(localized: "subway.transfer.up.\(destination).\(arrivalText)")
        }
        return String(localized: "subway.transfer.down.\(destination).\(arrivalText)")
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
    
    private func getRealtimeLabelText(_ time: Int, _ location: String) -> String {
        return String(localized: "subway.realtime.\(Int(time)).\(location)")
    }
    
    private func getRealtimeLabelTextWithoutTime(_ location: String, _ status: Int? = nil) -> String {
        if (status == 0) {
            return String(localized: "subway.transfer.entering.\(location)")
        } else if (status == 1) {
            return String(localized: "subway.transfer.arrived.\(location)")
        } else if (status == 2) {
            return String(localized: "subway.transfer.departed.\(location)")
        } else if (status == 3) {
            return String(localized: "subway.transfer.almost.\(location)")
        }
        return ""
    }
    
    private func getTimetableLabelText(_ minutes: Int) -> String {
        return String(localized: "subway.time.\(minutes)")
    }
}
