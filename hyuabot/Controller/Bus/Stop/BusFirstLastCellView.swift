//
//  BusFirstLastCellView.swift
//  hyuabot
//

import Api
import UIKit

class BusFirstLastCellView: UITableViewCell {
    static let reuseIdentifier = "BusFirstLastCellView"
    private let card = UIView()
    private let routeBadge = BusRouteBadgeView(size: .small)
    private let upDestination = UILabel()
    private let downDestination = UILabel()
    private let upTime = UILabel()
    private let downTime = UILabel()
    private let noTimetableLabel = UILabel()
    private let directions = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        card.backgroundColor = SettingsStyle.Color.card
        card.layer.cornerRadius = 16
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.horizontalEdges.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(10)
        }
        directions.axis = .vertical
        directions.spacing = 6
        directions.addArrangedSubview(directionRow(destination: upDestination, time: upTime))
        directions.addArrangedSubview(directionRow(destination: downDestination, time: downTime))
        noTimetableLabel.text = String(localized: "bus.stop.no_timetable")
        noTimetableLabel.font = SettingsStyle.font(14)
        noTimetableLabel.textColor = SettingsStyle.Color.secondaryText
        noTimetableLabel.numberOfLines = 0
        let details = UIStackView(arrangedSubviews: [directions, noTimetableLabel])
        details.axis = .vertical
        let stack = UIStackView(arrangedSubviews: [routeBadge, details])
        stack.alignment = .top
        stack.spacing = 8
        card.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(14)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        accessibilityIdentifier = "bus.stop.route_timetable"
    }

    private func directionRow(destination: UILabel, time: UILabel) -> UIStackView {
        destination.font = SettingsStyle.font(14)
        destination.textColor = SettingsStyle.Color.secondaryText
        destination.numberOfLines = 1
        destination.lineBreakMode = .byTruncatingTail
        destination.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        time.font = .monospacedDigitSystemFont(ofSize: 15, weight: .bold)
        time.textColor = SettingsStyle.Color.text
        time.setContentCompressionResistancePriority(.required, for: .horizontal)
        time.textAlignment = .right
        time.setContentHuggingPriority(.required, for: .horizontal)
        let row = UIStackView(arrangedSubviews: [destination, time])
        row.alignment = .center
        row.spacing = 6
        return row
    }

    private func setDestination(_ name: String, on label: UILabel) {
        let format = String(localized: "bus.stop.destination_format")
        let text = String(format: format, name)
        label.text = text
        Task { [weak label] in
            let translated = await KoreanTextTranslator.shared.translate(name)
            guard let label, label.text == text else { return }
            label.text = String(format: format, translated)
        }
    }

    func setupUI(item: BusStopDialogQuery.Data.Bus) {
        routeBadge.configure(route: item.route.name)
        setDestination(item.route.runningTime.up.terminal.name, on: upDestination)
        setDestination(item.route.runningTime.down.terminal.name, on: downDestination)
        let times = [item.route.runningTime.up.first, item.route.runningTime.up.last,
                     item.route.runningTime.down.first, item.route.runningTime.down.last].map(BusDisplayLogic.clockText)
        upTime.text = "\(times[0])–\(times[1])"
        downTime.text = "\(times[2])–\(times[3])"
        directions.isHidden = times.allSatisfy { $0 == "—" }
        noTimetableLabel.isHidden = !directions.isHidden
    }
}
