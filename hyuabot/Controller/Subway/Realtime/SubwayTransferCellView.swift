import Api
import RxSwift
import UIKit

private extension UIColor {
    static let transferLine4 = UIColor(red: 0, green: 160 / 255, blue: 233 / 255, alpha: 1)
    static let transferSuin = UIColor(red: 250 / 255, green: 190 / 255, blue: 0, alpha: 1)
    static let transferSeohae = UIColor(red: 0.56, green: 0.76, blue: 0.12, alpha: 1.00)
}

class SubwayTransferCellView: UITableViewCell {
    static let reuseIdentifier = "SubwayTransferCellView"
    private let contentStack = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .fill
        $0.spacing = 10
    }
    private let firstRow = UIView()
    private let firstDot = UIView()
    private let firstDestinationLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.textColor = .label
        $0.lineBreakMode = .byTruncatingTail
    }
    private let firstTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.textColor = .label
        $0.lineBreakMode = .byTruncatingTail
        $0.textAlignment = .right
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    private let firstMetaLabel = UILabel().then {
        $0.font = .godo(size: 13, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.lineBreakMode = .byTruncatingTail
        $0.text = " "
    }
    private let transferRow = UIView()
    private let transferLine = UIView().then {
        $0.backgroundColor = .separator
    }
    private let transferStationLabel = UILabel().then {
        $0.font = .godo(size: 14, weight: .bold)
        $0.textColor = .secondaryLabel
        $0.lineBreakMode = .byTruncatingTail
    }
    private let transferWaitLabel = UILabel().then {
        $0.font = .godo(size: 13, weight: .bold)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .right
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    private let secondRow = UIView()
    private let secondDot = UIView()
    private let secondDestinationLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.textColor = .label
        $0.lineBreakMode = .byTruncatingTail
    }
    private let secondTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.textColor = .label
        $0.textAlignment = .right
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
        selectionStyle = .none
        contentView.addSubview(contentStack)

        firstDot.layer.cornerRadius = 4
        secondDot.layer.cornerRadius = 4
        firstDot.snp.makeConstraints { make in
            make.size.equalTo(8)
        }
        secondDot.snp.makeConstraints { make in
            make.size.equalTo(8)
        }
        transferLine.snp.makeConstraints { make in
            make.width.equalTo(2)
            make.height.equalTo(24)
        }

        firstDestinationLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        transferStationLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        secondDestinationLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        contentView.addSubview(firstDestinationLabel)
        contentView.addSubview(firstTimeLabel)
        contentView.addSubview(transferStationLabel)
        contentView.addSubview(transferWaitLabel)
        contentView.addSubview(secondDestinationLabel)
        contentView.addSubview(secondTimeLabel)
        contentView.addSubview(firstDot)
        contentView.addSubview(secondDot)
        contentView.addSubview(transferLine)
        contentStack.addArrangedSubview(firstRow)
        contentStack.addArrangedSubview(firstMetaLabel)
        contentStack.addArrangedSubview(transferRow)
        contentStack.addArrangedSubview(secondRow)
        contentStack.setCustomSpacing(6, after: firstRow)
        contentStack.setCustomSpacing(12, after: firstMetaLabel)
        firstRow.snp.makeConstraints { make in
            make.width.equalTo(contentStack)
            make.height.equalTo(24)
        }
        transferRow.snp.makeConstraints { make in
            make.width.equalTo(contentStack)
            make.height.equalTo(18)
        }
        secondRow.snp.makeConstraints { make in
            make.width.equalTo(contentStack)
            make.height.equalTo(24)
        }

        contentStack.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.verticalEdges.greaterThanOrEqualToSuperview().inset(15)
            make.centerY.equalToSuperview()
        }
        firstDestinationLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView).inset(40)
            make.centerY.equalTo(firstRow)
            make.trailing.lessThanOrEqualTo(firstTimeLabel.snp.leading).offset(-12)
        }
        firstTimeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(contentView).inset(20)
            make.centerY.equalTo(firstRow)
        }
        transferStationLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView).inset(40)
            make.centerY.equalTo(transferRow)
            make.trailing.lessThanOrEqualTo(transferWaitLabel.snp.leading).offset(-12)
        }
        transferWaitLabel.snp.makeConstraints { make in
            make.trailing.equalTo(contentView).inset(20)
            make.centerY.equalTo(transferRow)
        }
        secondDestinationLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView).inset(40)
            make.centerY.equalTo(secondRow)
            make.trailing.lessThanOrEqualTo(secondTimeLabel.snp.leading).offset(-12)
        }
        secondTimeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(contentView).inset(20)
            make.centerY.equalTo(secondRow)
        }
        firstMetaLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
        }
        firstDot.snp.remakeConstraints { make in
            make.size.equalTo(8)
            make.leading.equalTo(contentView).inset(20)
            make.centerY.equalTo(firstDestinationLabel)
        }
        transferLine.snp.remakeConstraints { make in
            make.width.equalTo(2)
            make.height.equalTo(24)
            make.centerX.equalTo(firstDot)
            make.centerY.equalTo(transferRow)
        }
        secondDot.snp.remakeConstraints { make in
            make.size.equalTo(8)
            make.leading.equalTo(contentView).inset(20)
            make.centerY.equalTo(secondDestinationLabel)
        }
    }

    func setupUI(item: SubwayTransferItem, direction: String) {
        firstDot.backgroundColor = lineColor(stationID: item.take.terminal.stationID)
        firstDestinationLabel.text = destinationText(item.take)
        firstTimeLabel.attributedText = arrivalText(item.take, includesLocation: item.transfer == nil && direction == "down")

        firstMetaLabel.isHidden = true

        guard let transfer = item.transfer else {
            transferRow.isHidden = true
            secondRow.isHidden = true
            transferLine.isHidden = true
            secondDot.isHidden = true
            transferStationLabel.isHidden = true
            transferWaitLabel.isHidden = true
            secondDestinationLabel.isHidden = true
            secondTimeLabel.isHidden = true
            return
        }

        transferRow.isHidden = false
        secondRow.isHidden = false
        transferLine.isHidden = false
        secondDot.isHidden = false
        transferStationLabel.isHidden = false
        transferWaitLabel.isHidden = false
        secondDestinationLabel.isHidden = false
        secondTimeLabel.isHidden = false
        transferStationLabel.text = String(
            format: String(localized: "subway.transfer.station.%@"),
            transferStationText(direction: direction)
        )
        transferWaitLabel.text = waitText(item.transferWaitMinutes ?? transfer.minutes - item.take.minutes)
        secondDot.backgroundColor = lineColor(stationID: transfer.terminal.stationID)
        secondDestinationLabel.text = destinationText(transfer)
        secondTimeLabel.attributedText = arrivalText(transfer, includesLocation: false)
    }

    private func destinationText(_ entry: SubwayRealtimePageQuery.Data.Subway.Arrival.Entry) -> String {
        let destination = getDestinationLabelText(entry.terminal.stationID, fallback: entry.terminal.name)
        return String(format: String(localized: "subway.transfer.destination.%@"), destination)
    }

    private func minutesText(_ minutes: Int) -> String {
        String(format: String(localized: "subway.transfer.minutes.%lld"), minutes)
    }

    private func arrivalText(
        _ entry: SubwayRealtimePageQuery.Data.Subway.Arrival.Entry,
        includesLocation: Bool
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(
            string: minutesText(entry.minutes),
            attributes: [
                .font: UIFont.godo(size: 16, weight: .bold),
                .foregroundColor: UIColor.label
            ]
        )
        guard includesLocation, let location = entry.location, !location.isEmpty else {
            return result
        }
        result.append(NSAttributedString(
            string: " \(location)",
            attributes: [
                .font: UIFont.godo(size: 13, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
        ))
        return result
    }

    private func waitText(_ minutes: Int) -> String {
        String(format: String(localized: "subway.transfer.wait.%lld"), minutes)
    }

    private func transferStationText(direction: String) -> String {
        direction == "choji" ? String(localized: "subway.station.choji") : String(localized: "subway.station.k258")
    }

    private func lineColor(stationID: String) -> UIColor {
        if stationID.hasPrefix("K4") {
            return .transferLine4
        } else if stationID.hasPrefix("S") {
            return .transferSeohae
        } else if stationID.hasPrefix("K2") {
            return .transferSuin
        }
        return .hanyangBlue
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
        case "S07": stationName = String(localized: "subway.station.s07")
        case "S11": stationName = String(localized: "subway.station.s11")
        case "S16": stationName = String(localized: "subway.station.s16")
        default:
            let key = "subway.station.\(stationID.lowercased())"
            let localized = String(localized: String.LocalizationValue(stringLiteral: key))
            return localized == key ? fallback : localized
        }
        return stationName
    }
}
