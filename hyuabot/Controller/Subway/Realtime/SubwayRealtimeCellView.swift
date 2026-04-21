import UIKit
import Api
import RxSwift

class SubwayRealtimeCellView: UITableViewCell {
    static let reuseIdentifier = "SubwayRealtimeCellView"
    private let destinationLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
    }
    private let subwayTimeLabel = UILabel().then {
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
        self.contentView.addSubview(self.destinationLabel)
        self.contentView.addSubview(self.subwayTimeLabel)
        self.selectionStyle = .none
        self.destinationLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        self.subwayTimeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }
    
    func setupUI(tabType: SubwayTabType, item: SubwayRealtimePageQuery.Data.Subway.Arrival.Entry) {
        // Set destination label color
        if tabType == .line4 { self.destinationLabel.textColor = .subwaySkyblue }
        else if tabType == .lineSuin { self.destinationLabel.textColor = .subwayYellow }
        if (item.isRealtime) {
            self.destinationLabel.text = String(localized: "subway.terminal.\(getDestinationLabelText(item.terminal.stationID))")
            if (item.isLast!) {
                self.setRealtimeAttributedText(String(
                    localized: getRealtimeLabelText(
                        item.minutes,
                        item.location!,
                        item.status!,
                        item.isLast!
                    )
                ))
            } else {
                self.setRealtimeAttributedText(String(
                    localized: getRealtimeLabelText(
                        item.minutes,
                        item.location!,
                        item.status!,
                        item.isLast!
                    )
                ))
            }
        } else {
            self.destinationLabel.text = String(localized: "subway.terminal.\(getDestinationLabelText(item.terminal.stationID))")
            self.subwayTimeLabel.text = String(localized: getTimetableLabelText(item.minutes))
        }
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
    
    private func getRealtimeLabelText(_ time: Int, _ location: String, _ status: Int, _ last: Bool) -> String.LocalizationValue {
        if (time < 2) {
            return "subway.realtime.now"
        }
        if (last) {
            if (status == 0) {
                return "subway.realtime.last.entering.\(Int(time)).\(location)"
            } else if (status == 1) {
                return "subway.realtime.last.arrived.\(Int(time)).\(location)"
            } else if (status == 2) {
                return "subway.realtime.last.departed.\(Int(time)).\(location)"
            } else if (status == 3) {
                return "subway.realtime.last.almost.\(Int(time)).\(location)"
            }
        } else {
            if (status == 0) {
                return "subway.realtime.entering.\(Int(time)).\(location)"
            } else if (status == 1) {
                return "subway.realtime.arrived.\(Int(time)).\(location)"
            } else if (status == 2) {
                return "subway.realtime.departed.\(Int(time)).\(location)"
            } else if (status == 3) {
                return "subway.realtime.almost.\(Int(time)).\(location)"
            }
        }
        return "subway.realtime.\(time).\(location)"
    }
    
    private func getTimetableLabelText(_ minutes: Int) -> String.LocalizationValue {
        return "subway.time.\(minutes)"
    }
    
    private func setRealtimeAttributedText(_ text: String) {
        let attributeString = NSMutableAttributedString(string: text)
        if text.contains("(") && !text.contains("(s)") {
            attributeString.addAttribute(
                .foregroundColor,
                value: UIColor.red, range: NSRange(
                    location: 0,
                    length: text.distance(from: text.startIndex, to: text.firstIndex(of: "(")!) - 1
                )
            )
        }
        self.subwayTimeLabel.attributedText = attributeString
    }
}
