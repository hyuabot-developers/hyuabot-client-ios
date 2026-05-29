import UIKit
import SnapKit

// MARK: - Line Colors

private extension UIColor {
    static let line4Color = UIColor(red: 0, green: 160/255, blue: 233/255, alpha: 1)
    static let suinColor  = UIColor(red: 250/255, green: 190/255, blue: 0, alpha: 1)
    static let busColor   = UIColor(named: "busGreen") ?? .systemGreen
}

// MARK: - Data Models

private struct SubwayTransferData: Decodable {
    let subway: [Station]
    struct Station: Decodable {
        let stationID: String
        let arrival: [ArrivalGroup]
        struct ArrivalGroup: Decodable {
            let direction: String
            let entries: [Entry]
            struct Entry: Decodable {
                let minutes: Int
                let isRealtime: Bool
                let terminal: Terminal
                struct Terminal: Decodable { let stationID: String; let name: String }
            }
        }
    }
}

private struct BusTransferData: Decodable {
    let bus: [BusRoute]
    struct BusRoute: Decodable {
        let route: Route
        let arrival: [Arrival]
        struct Route: Decodable { let seq: Int; let name: String }
        struct Arrival: Decodable {
            let minutes: Int?
            let stops: Int?
            let isRealtime: Bool
            let time: String?
        }
    }
}

// MARK: - Transfer Row View

private class TransferRowView: UIView {
    private let nameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .bold)
        $0.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
    private let timesLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .right
    }

    init(name: String, times: String, nameColor: UIColor = .label) {
        super.init(frame: .zero)
        nameLabel.text = name
        nameLabel.textColor = nameColor
        timesLabel.text = times
        addSubview(nameLabel)
        addSubview(timesLabel)
        nameLabel.snp.makeConstraints { $0.leading.centerY.equalToSuperview() }
        timesLabel.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(nameLabel.snp.trailing).offset(8)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Transfer Info View

class ShuttleTransferInfoView: UIView {
    private let stopID: ShuttleStopEnum

    private let separatorLine = UIView().then { $0.backgroundColor = .separator }
    private let iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .secondaryLabel
    }
    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .semibold)
        $0.textColor = .secondaryLabel
    }
    private let staticInfoLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 11)
        $0.textColor = .tertiaryLabel
        $0.numberOfLines = 2
    }
    private let rowStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 6
        $0.setContentHuggingPriority(.required, for: .vertical)
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    private let loadingIndicator = UIActivityIndicatorView(style: .medium).then {
        $0.hidesWhenStopped = true
    }

    init(stopID: ShuttleStopEnum) {
        self.stopID = stopID
        super.init(frame: .zero)
        setupUI()
        configure()
        Task { await loadData() }
    }
    required init?(coder: NSCoder) { fatalError() }

    private func configure() {
        switch stopID {
        case .dormiotryOut, .shuttlecockOut:
            iconImageView.image = UIImage(systemName: "arrow.triangle.swap")
            titleLabel.text = String(localized: "shuttle.transfer.section.title")
            staticInfoLabel.text = String(localized: "shuttle.transfer.dormitory.info")
        case .terminal:
            iconImageView.image = UIImage(systemName: "bus.doubledecker.fill")
            titleLabel.text = String(localized: "shuttle.transfer.bus50.title")
            staticInfoLabel.text = String(localized: "shuttle.transfer.terminal.info")
        default:
            break
        }
    }

    private func setupUI() {
        backgroundColor = .systemBackground
        addSubview(separatorLine)
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(rowStackView)
        addSubview(staticInfoLabel)
        addSubview(loadingIndicator)

        separatorLine.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(0.5)
        }
        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.top.equalTo(separatorLine.snp.bottom).offset(10)
            $0.width.height.equalTo(14)
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(6)
            $0.centerY.equalTo(iconImageView)
        }
        rowStackView.snp.makeConstraints {
            $0.top.equalTo(iconImageView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        staticInfoLabel.snp.makeConstraints {
            $0.top.equalTo(rowStackView.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(10)
        }
        loadingIndicator.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(rowStackView).offset(-10)
        }
        loadingIndicator.startAnimating()
    }

    private func loadData() async {
        do {
            switch stopID {
            case .dormiotryOut, .shuttlecockOut:
                async let subwayTask: SubwayTransferData = fetchTransferData(
                    query: subwayQuery(stationIDs: ["K449", "K251"]),
                    variables: ["weekday": currentWeekdayString()]
                )
                async let busTask: BusTransferData = fetchTransferData(query: kwangmyeongBusQuery)
                let (subwayData, busData) = try await (subwayTask, busTask)
                await MainActor.run {
                    renderSubwayByLine(data: subwayData.subway)
                    renderBus(data: busData.bus, label: String(localized: "shuttle.transfer.bus50.to.kwangmyeong"), color: .busColor)
                }
            case .terminal:
                let data: BusTransferData = try await fetchTransferData(query: ansanBusQuery)
                await MainActor.run { renderBus(data: data.bus, label: String(localized: "shuttle.transfer.bus50.to.ansan"), color: .busColor) }
            default:
                await MainActor.run { loadingIndicator.stopAnimating() }
            }
        } catch {
            await MainActor.run { loadingIndicator.stopAnimating() }
        }
    }

    @MainActor
    private func renderSubwayByLine(data: [SubwayTransferData.Station]) {
        loadingIndicator.stopAnimating()
        let lineMap: [String: (name: String, color: UIColor)] = [
            "K449": (String(localized: "subway.line4"), .line4Color),
            "K251": (String(localized: "subway.suin"), .suinColor)
        ]
        for stationID in ["K449", "K251"] {
            guard let station = data.first(where: { $0.stationID == stationID }) else { continue }
            guard let info = lineMap[stationID] else { continue }
            var parts: [String] = []
            if let upEntry = station.arrival.first(where: { $0.direction == "up" })?.entries.first {
                let label = appBoundLabel(stationID: upEntry.terminal.stationID, fallback: upEntry.terminal.name)
                parts.append("\(label) \(upEntry.minutes)분")
            }
            if let downEntry = station.arrival.first(where: { $0.direction == "down" })?.entries.first {
                let label = appBoundLabel(stationID: downEntry.terminal.stationID, fallback: downEntry.terminal.name)
                parts.append("\(label) \(downEntry.minutes)분")
            }
            guard !parts.isEmpty else { continue }
            let row = TransferRowView(name: info.name, times: parts.joined(separator: "  "), nameColor: info.color)
            rowStackView.addArrangedSubview(row)
            row.snp.makeConstraints { $0.height.equalTo(20) }
        }
    }

    private func appBoundLabel(stationID: String, fallback: String) -> String {
        let nameKey = "subway.station.\(stationID.lowercased())"
        let localizedName = String(localized: String.LocalizationValue(stringLiteral: nameKey))
        let stationName = (localizedName == nameKey) ? fallback : localizedName
        return String(format: String(localized: "subway.terminal.%@"), stationName)
    }

    @MainActor
    private func renderBus(data: [BusTransferData.BusRoute], label: String, color: UIColor) {
        loadingIndicator.stopAnimating()
        let timeStrings = data.flatMap { $0.arrival }.prefix(2).compactMap { arrival -> String? in
            var result: String
            if let m = arrival.minutes {
                result = "\(m)분"
                if let s = arrival.stops, s > 0 { result += "(\(s)전 정류장)" }
                return result
            }
            if let t = arrival.time {
                let parts = t.split(separator: ":")
                return parts.count >= 2 ? "\(parts[0]):\(parts[1])" : nil
            }
            return nil
        }
        guard !timeStrings.isEmpty else { return }
        let row = TransferRowView(name: label, times: timeStrings.joined(separator: "  "), nameColor: color)
        rowStackView.addArrangedSubview(row)
        row.snp.makeConstraints { $0.height.equalTo(20) }
    }
}

// MARK: - Queries

private func subwayQuery(stationIDs: [String]) -> String {
    let keys = stationIDs.map {
        "{ stationID: \"\($0)\", direction: [\"up\", \"down\"], weekdays: [$weekday], limit: 1 }"
    }.joined(separator: ", ")
    return """
    query($weekday: String!) {
        subway(input: { keys: [\(keys)] }) {
            stationID
            arrival {
                direction
                entries { minutes isRealtime terminal { stationID name } }
            }
        }
    }
    """
}

private let kwangmyeongBusQuery = """
query {
    bus(input: [{ route: 200000015, stop: 216000070, limit: 2 }]) {
        route { seq name }
        arrival { minutes stops isRealtime time }
    }
}
"""

private let ansanBusQuery = """
query {
    bus(input: [{ route: 216000104, stop: 216000117, limit: 2 }]) {
        route { seq name }
        arrival { minutes stops isRealtime time }
    }
}
"""
