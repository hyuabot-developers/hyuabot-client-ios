//
//  BusLogCell.swift
//  hyuabot
//

import UIKit

class BusLogCell: UITableViewCell {
    static let reuseIdentifier = "BusLogCell"
    private let busTimeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(busTimeLabel)
        busTimeLabel.textAlignment = .center
        busTimeLabel.layer.cornerRadius = 8
        busTimeLabel.clipsToBounds = true
        busTimeLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(4)
            make.verticalEdges.equalToSuperview().inset(2)
        }
        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ row: BusDepartureLogRowModel) {
        backgroundColor = .clear
        busTimeLabel.text = row.time
        busTimeLabel.font = SettingsStyle.monospacedDigitFont(17, bold: !row.isPast)
        busTimeLabel.textColor = row.isNext ? SettingsStyle.Color.accent
            : row.isPast ? SettingsStyle.Color.secondaryText : SettingsStyle.Color.text
        busTimeLabel.backgroundColor = row.isNext ? SettingsStyle.Color.accentFill : .clear
        accessibilityLabel = row.isNext
            ? String(format: String(localized: "bus.log.next.%@"), row.time) : row.time
        accessibilityIdentifier = row.isNext ? "bus.log.next" : "bus.log.time"
    }
}
