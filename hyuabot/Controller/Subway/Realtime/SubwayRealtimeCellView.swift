import UIKit
import QueryAPI
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
    
    func setupUI(tabType: SubwayTabType, item: SubwayRealtimeItem) {
        // Set destination label color
        if tabType == .line4 { self.destinationLabel.textColor = .subwaySkyblue }
        else if tabType == .lineSuin { self.destinationLabel.textColor = .subwayYellow }
        // Set text
        if (item.realtimeUp != nil) {
            self.destinationLabel.text = String(localized: "subway.terminal.\(getDestinationLabelText(item.realtimeUp!.terminal.id))")
            if (item.realtimeUp!.last) {
                self.setRealtimeAttributedText(String(
                    localized: getRealtimeLabelText(
                        item.realtimeUp!.time,
                        item.realtimeUp!.location,
                        item.realtimeUp!.status,
                        item.realtimeUp!.last
                    )
                ))
            } else {
                self.setRealtimeAttributedText(String(
                    localized: getRealtimeLabelText(
                        item.realtimeUp!.time,
                        item.realtimeUp!.location,
                        item.realtimeUp!.status,
                        item.realtimeUp!.last
                    )
                ))
            }
        } else if (item.realtimeDown != nil) {
            self.destinationLabel.text = String(localized: "subway.terminal.\(getDestinationLabelText(item.realtimeDown!.terminal.id))")
            if (item.realtimeDown!.last) {
                self.setRealtimeAttributedText(String(
                    localized: getRealtimeLabelText(
                        item.realtimeDown!.time,
                        item.realtimeDown!.location,
                        item.realtimeDown!.status,
                        item.realtimeDown!.last
                    )
                ))
            } else {
                self.setRealtimeAttributedText(String(
                    localized: getRealtimeLabelText(
                        item.realtimeDown!.time,
                        item.realtimeDown!.location,
                        item.realtimeDown!.status,
                        item.realtimeDown!.last
                    )
                ))
            }
        } else if (item.timetableUp != nil) {
            self.destinationLabel.text = String(localized: "subway.terminal.\(getDestinationLabelText(item.timetableUp!.terminal.id))")
            self.subwayTimeLabel.text = String(localized: getTimetableLabelText(item.timetableUp!.time))
        } else if (item.timetableDown != nil) {
            self.destinationLabel.text = String(localized: "subway.terminal.\(getDestinationLabelText(item.timetableDown!.terminal.id))")
            self.subwayTimeLabel.text = String(localized: getTimetableLabelText(item.timetableDown!.time))
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
    
    private func getRealtimeLabelText(_ time: Double, _ location: String, _ status: Int, _ last: Bool) -> String.LocalizationValue {
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
        return "subway.realtime.\(Int(time)).\(location)"
    }
    
    private func getTimetableLabelText(_ departureTime: String) -> String.LocalizationValue {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let departureTime = dateFormatter.date(from: departureTime)
        let hour = calendar.component(.hour, from: departureTime!)
        let minute = calendar.component(.minute, from: departureTime!)
        return "subway.time.\(hour).\(minute)"
    }
    
    private func setRealtimeAttributedText(_ text: String) {
        let attributeString = NSMutableAttributedString(string: text)
        attributeString.addAttribute(
            .foregroundColor,
            value: UIColor.red, range: NSRange(
                location: 0,
                length: text.distance(from: text.startIndex, to: text.firstIndex(of: "(")!) - 1
            )
        )
        self.subwayTimeLabel.attributedText = attributeString
    }
}
