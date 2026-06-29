import Api
import RxSwift
import UIKit

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
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        contentView.addSubview(destinationLabel)
        contentView.addSubview(subwayTimeLabel)
        selectionStyle = .none
        destinationLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        subwayTimeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }

    func setupUI(tabType: SubwayTabType, item: SubwayRealtimePageQuery.Data.Subway.Arrival.Entry) {
        // Set destination label color
        if tabType == .line4 { destinationLabel.textColor = .subwaySkyblue }
        else if tabType == .lineSuin { destinationLabel.textColor = .subwayYellow }
        let destination = getDestinationLabelText(item.terminal.stationID, fallback: item.terminal.name)
        let destinationText = String(format: String(localized: "subway.terminal.%@"), destination)
        if item.isRealtime {
            destinationLabel.setKoreanTranslatedText(destinationText)
            setRealtimeAttributedText(getRealtimeLabelText(item))
        } else {
            destinationLabel.setKoreanTranslatedText(destinationText)
            subwayTimeLabel.attributedText = nil
            subwayTimeLabel.text = getTimetableLabelText(item.minutes)
        }
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

    private func getRealtimeLabelText(_ item: SubwayRealtimePageQuery.Data.Subway.Arrival.Entry) -> String {
        guard isKoreanAppLanguage else {
            return appendStopsText(getTimetableLabelText(item.minutes), stops: item.stops, compact: true)
        }
        guard let location = item.location,
              let status = item.status
        else {
            return getTimetableLabelText(item.minutes)
        }
        return getRealtimeLabelText(item.minutes, location, status, item.isLast ?? false)
    }

    private func getRealtimeLabelText(_ time: Int, _ location: String, _ status: Int, _ last: Bool) -> String {
        if time < 2 {
            return String(localized: "subway.realtime.now")
        }
        if last {
            if status == 0 {
                return String(format: String(localized: "subway.realtime.last.entering.%lld.%@"), time, location)
            } else if status == 1 {
                return String(format: String(localized: "subway.realtime.last.arrived.%lld.%@"), time, location)
            } else if status == 2 {
                return String(format: String(localized: "subway.realtime.last.departed.%lld.%@"), time, location)
            } else if status == 3 {
                return String(format: String(localized: "subway.realtime.last.almost.%lld.%@"), time, location)
            }
        } else {
            if status == 0 {
                return String(format: String(localized: "subway.realtime.entering.%lld.%@"), time, location)
            } else if status == 1 {
                return String(format: String(localized: "subway.realtime.arrived.%lld.%@"), time, location)
            } else if status == 2 {
                return String(format: String(localized: "subway.realtime.departed.%lld.%@"), time, location)
            } else if status == 3 {
                return String(format: String(localized: "subway.realtime.almost.%lld.%@"), time, location)
            }
        }
        return String(format: String(localized: "subway.realtime.%lld.%@"), time, location)
    }

    private func getTimetableLabelText(_ minutes: Int) -> String {
        String(format: String(localized: "subway.time.%lld"), minutes)
    }

    private var isKoreanAppLanguage: Bool {
        (Locale.current.language.languageCode?.identifier ?? "ko").hasPrefix("ko")
    }

    private func appendStopsText(_ text: String, stops: Int?, compact: Bool = false) -> String {
        guard let stops, stops > 0 else { return text }
        let stopsText = stopCountText(stops, compact: compact)
        return "\(text) \(stopsText)"
    }

    private func stopCountText(_ stops: Int, compact: Bool) -> String {
        let text = String(format: String(localized: "subway.realtime.stops.suffix.%lld"), stops)
        guard compact else { return text }
        return text.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
    }

    private func setRealtimeAttributedText(_ text: String) {
        let attributeString = NSMutableAttributedString(string: text)
        if text.contains("("), !text.contains("(s)") {
            attributeString.addAttribute(
                .foregroundColor,
                value: UIColor.red, range: NSRange(
                    location: 0,
                    length: text.distance(from: text.startIndex, to: text.firstIndex(of: "(")!) - 1
                )
            )
        }
        subwayTimeLabel.attributedText = attributeString
    }
}
