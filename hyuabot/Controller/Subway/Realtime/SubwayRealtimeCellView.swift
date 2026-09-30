import Api
import RxSwift
import UIKit

class SubwayRealtimeCellView: UITableViewCell {
    static let reuseIdentifier = "SubwayRealtimeCellView"
    private let lineIndicator = UIView().then { $0.layer.cornerRadius = 2 }
    private let destinationLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.textColor = .label
        $0.numberOfLines = 0
        $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private let subwayTimeLabel = UILabel().then {
        $0.font = .godo(size: 15, weight: .regular)
        $0.textAlignment = .right
        $0.numberOfLines = 0
        $0.textColor = .label
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
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
        contentView.addSubview(lineIndicator)
        contentView.addSubview(destinationLabel)
        contentView.addSubview(subwayTimeLabel)
        selectionStyle = .none
        lineIndicator.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.width.equalTo(4)
            make.height.equalTo(24)
        }
        destinationLabel.snp.makeConstraints { make in
            make.leading.equalTo(lineIndicator.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(12)
            make.trailing.lessThanOrEqualTo(self.subwayTimeLabel.snp.leading).offset(-12)
        }
        subwayTimeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().inset(12)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
        }
    }

    func setupUI(tabType: SubwayTabType, item: SubwayRealtimePageQuery.Data.Subway.Arrival.Entry) {
        // Set destination label color
        if tabType == .line4 {
            lineIndicator.backgroundColor = .subwaySkyblue
        } else if tabType == .lineSuin {
            lineIndicator.backgroundColor = .subwayYellow
        } else {
            lineIndicator.backgroundColor = .hanyangBlue
        }
        let destination = getDestinationLabelText(item.terminal.stationID, fallback: item.terminal.name)
        let destinationText = String(format: String(localized: "subway.terminal.%@"), destination)
        if item.isRealtime {
            destinationLabel.setKoreanTranslatedText(destinationText)
            setRealtimeAttributedText(getRealtimeLabelText(item))
        } else {
            destinationLabel.setKoreanTranslatedText(destinationText)
            subwayTimeLabel.attributedText = nil
            subwayTimeLabel.text = getTimetableLabelText(item.minutes) + " " + String(localized: "transit.scheduled")
        }
    }

    func getDestinationLabelText(_ stationID: String, fallback: String) -> String {
        fallback
    }

    private func getRealtimeLabelText(_ item: SubwayRealtimePageQuery.Data.Subway.Arrival.Entry) -> String {
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
        subwayTimeLabel.text = text
    }
}
