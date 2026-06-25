import Api
import RxSwift
import UIKit

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
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        contentView.addSubview(fromLabel)
        contentView.addSubview(arrowLabel)
        contentView.addSubview(toLabel)
        selectionStyle = .none
        fromLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        toLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        arrowLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    func setupUI(item: SubwayTransferItem, direction: String) {
        if let transfer = item.transfer {
            arrowLabel.isHidden = false
            fromLabel.text = takeLabelText(item.take, direction: direction)
            toLabel.text = String(
                format: String(localized: "subway.transfer.timetable.%@.%@"),
                getDestinationLabelText(transfer.terminal.stationID, fallback: transfer.terminal.name),
                getTimetableLabelText(transfer.minutes)
            )
        } else {
            arrowLabel.isHidden = true
            toLabel.text = ""
            fromLabel.text = takeLabelText(item.take, direction: direction)
        }
    }

    private func takeLabelText(_ entry: SubwayRealtimePageQuery.Data.Subway.Arrival.Entry, direction: String) -> String {
        let destination = getDestinationLabelText(entry.terminal.stationID, fallback: entry.terminal.name)
        let arrivalText: String = if direction == "up" {
            entry.location ?? getTimetableLabelText(entry.minutes)
        } else if let location = entry.location {
            getRealtimeLabelText(entry.minutes, location)
        } else {
            getTimetableLabelText(entry.minutes)
        }
        if direction == "up" {
            return String(format: String(localized: "subway.transfer.up.%@.%@"), destination, arrivalText)
        }
        return String(format: String(localized: "subway.transfer.down.%@.%@"), destination, arrivalText)
    }

    func getDestinationLabelText(_ stationID: String, fallback: String) -> String {
        var stationName = ""
        switch stationID {
        case "K209": stationName = String(localized: "subway.station.k209")
        case "K210": stationName = String(localized: "subway.station.k210")
        case "K233": stationName = String(localized: "subway.station.k233")
        case "K246": stationName = String(localized: "subway.station.k246")
        case "K258": stationName = String(localized: "subway.station.k258")
        case "K272": stationName = String(localized: "subway.station.k272")
        case "K409": stationName = String(localized: "subway.station.k409")
        case "K411": stationName = String(localized: "subway.station.k411")
        case "K419": stationName = String(localized: "subway.station.k419")
        case "K433": stationName = String(localized: "subway.station.k433")
        case "K443": stationName = String(localized: "subway.station.k443")
        case "K444": stationName = String(localized: "subway.station.k444")
        case "K453": stationName = String(localized: "subway.station.k453")
        case "K456": stationName = String(localized: "subway.station.k456")
        default:
            let key = "subway.station.\(stationID.lowercased())"
            let localized = String(localized: String.LocalizationValue(stringLiteral: key))
            return localized == key ? fallback : localized
        }
        return stationName
    }

    private func getRealtimeLabelText(_ time: Int, _ location: String) -> String {
        String(format: String(localized: "subway.realtime.%lld.%@"), time, location)
    }

    private func getRealtimeLabelTextWithoutTime(_ location: String, _ status: Int? = nil) -> String {
        if status == 0 {
            return String(format: String(localized: "subway.transfer.entering.%@"), location)
        } else if status == 1 {
            return String(format: String(localized: "subway.transfer.arrived.%@"), location)
        } else if status == 2 {
            return String(format: String(localized: "subway.transfer.departed.%@"), location)
        } else if status == 3 {
            return String(format: String(localized: "subway.transfer.almost.%@"), location)
        }
        return ""
    }

    private func getTimetableLabelText(_ minutes: Int) -> String {
        String(format: String(localized: "subway.time.%lld"), minutes)
    }
}
