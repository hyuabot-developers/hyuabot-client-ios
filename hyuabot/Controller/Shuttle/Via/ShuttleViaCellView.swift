//
//  ShuttleViaCellView.swift
//  hyuabot
//

import Api
import RxSwift
import UIKit

class ShuttleViaCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleViaCellView"
    private let timeline = UIView()
    private let timelineLine = UIView()
    private let timelineDot = UIView()
    private let shuttleStopLabel = UILabel()
    private let shuttleTimeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        shuttleStopLabel.textColor = SettingsStyle.Color.text
        shuttleTimeLabel.textColor = SettingsStyle.Color.text
        shuttleStopLabel.font = SettingsStyle.font(15)
        shuttleTimeLabel.font = SettingsStyle.monospacedDigitFont(15)
        timelineLine.isHidden = false
        timelineDot.backgroundColor = SettingsStyle.Color.commuterFaint
    }

    func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        shuttleStopLabel.font = SettingsStyle.font(15)
        shuttleStopLabel.textColor = SettingsStyle.Color.text
        shuttleStopLabel.numberOfLines = 1
        shuttleStopLabel.lineBreakMode = .byTruncatingTail
        shuttleTimeLabel.font = SettingsStyle.monospacedDigitFont(15)
        shuttleTimeLabel.textColor = SettingsStyle.Color.text
        shuttleTimeLabel.textAlignment = .right
        timelineLine.backgroundColor = SettingsStyle.Color.separator
        timelineDot.layer.cornerRadius = 4
        timelineDot.backgroundColor = SettingsStyle.Color.commuterFaint
        [timelineLine, timelineDot].forEach(timeline.addSubview)
        [timeline, shuttleStopLabel, shuttleTimeLabel].forEach(contentView.addSubview)
        timeline.snp.makeConstraints { $0.leading.equalToSuperview().offset(16); $0.width.equalTo(12); $0.top.bottom.equalToSuperview() }
        timelineLine.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.width.equalTo(2); $0.top.bottom.equalToSuperview() }
        timelineDot.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(8) }
        shuttleTimeLabel.setContentHuggingPriority(.required, for: .horizontal)
        shuttleTimeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        shuttleStopLabel.snp.makeConstraints { make in
            make.leading.equalTo(timeline.snp.trailing).offset(12)
            make.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualTo(shuttleTimeLabel.snp.leading).offset(-8)
        }
        shuttleTimeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }

    func setTimelinePosition(isFirst: Bool, isLast: Bool) {
        timelineLine.snp.remakeConstraints { make in
            make.centerX.equalToSuperview(); make.width.equalTo(2)
            make.top.equalToSuperview().offset(isFirst ? 22 : 0)
            make.bottom.equalToSuperview().inset(isLast ? 22 : 0)
        }
    }

    /// Stops already passed stay grey; the stop the shuttle departs from now is emphasised in blue.
    private func applyCurrentStopStyle() {
        timelineDot.backgroundColor = SettingsStyle.Color.accent
        shuttleStopLabel.font = SettingsStyle.font(15, bold: true)
        shuttleStopLabel.textColor = SettingsStyle.Color.link
        shuttleTimeLabel.font = SettingsStyle.monospacedDigitFont(15, bold: true)
        shuttleTimeLabel.textColor = SettingsStyle.Color.link
    }

    func setupUI(
        startStop: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order.Stop
    ) {
        if item.stop == "dormitory_o" {
            shuttleStopLabel.text = String(localized: "shuttle.stop.dormitory.out")
        } else if item.stop == "shuttlecock_o" {
            shuttleStopLabel.text = String(localized: "shuttle.stop.shuttlecock.out")
        } else if item.stop == "station" {
            shuttleStopLabel.text = String(localized: "shuttle.stop.station")
        } else if item.stop == "terminal" {
            shuttleStopLabel.text = String(localized: "shuttle.stop.terminal")
        } else if item.stop == "jungang_stn" {
            shuttleStopLabel.text = String(localized: "shuttle.stop.jungang.station")
        } else if item.stop == "shuttlecock_i" {
            shuttleStopLabel.text = String(localized: "shuttle.stop.shuttlecock.in")
        } else {
            shuttleStopLabel.text = String(localized: "shuttle.stop.dormitory.out")
        }
        shuttleTimeLabel.text = formatTime(item.time)
        if startStop.time > item.time {
            shuttleStopLabel.textColor = SettingsStyle.Color.subwayPast
            shuttleTimeLabel.textColor = SettingsStyle.Color.subwayPast
        } else if startStop.time == item.time {
            applyCurrentStopStyle()
        }
    }

    func setupUI(
        startStop: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry.Stop
    ) {
        if item.stop == "dormitory_o" {
            shuttleStopLabel.text = String(localized: "shuttle.stop.dormitory.out")
        } else if item.stop == "shuttlecock_o" {
            shuttleStopLabel.text = String(localized: "shuttle.stop.shuttlecock.out")
        } else if item.stop == "station" {
            shuttleStopLabel.text = String(localized: "shuttle.stop.station")
        } else if item.stop == "terminal" {
            shuttleStopLabel.text = String(localized: "shuttle.stop.terminal")
        } else if item.stop == "jungang_stn" {
            shuttleStopLabel.text = String(localized: "shuttle.stop.jungang.station")
        } else if item.stop == "shuttlecock_i" {
            shuttleStopLabel.text = String(localized: "shuttle.stop.shuttlecock.in")
        } else {
            shuttleStopLabel.text = String(localized: "shuttle.stop.dormitory.out")
        }
        shuttleTimeLabel.text = formatTime(item.time)
        if startStop.time > item.time {
            shuttleStopLabel.textColor = SettingsStyle.Color.subwayPast
            shuttleTimeLabel.textColor = SettingsStyle.Color.subwayPast
        } else if startStop.time == item.time {
            applyCurrentStopStyle()
        }
    }

    func setupUI(
        startStop: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order,
        item: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order.Stop
    ) {
        if item.stop == "dormitory_o" {
            shuttleStopLabel.text = String(localized: "shuttle.stop.dormitory.out")
        } else if item.stop == "shuttlecock_o" {
            shuttleStopLabel.text = String(localized: "shuttle.stop.shuttlecock.out")
        } else if item.stop == "station" {
            shuttleStopLabel.text = String(localized: "shuttle.stop.station")
        } else if item.stop == "terminal" {
            shuttleStopLabel.text = String(localized: "shuttle.stop.terminal")
        } else if item.stop == "jungang_stn" {
            shuttleStopLabel.text = String(localized: "shuttle.stop.jungang.station")
        } else if item.stop == "shuttlecock_i" {
            shuttleStopLabel.text = String(localized: "shuttle.stop.shuttlecock.in")
        } else {
            shuttleStopLabel.text = String(localized: "shuttle.stop.dormitory.out")
        }
        shuttleTimeLabel.text = formatTime(item.time)
        if startStop.time > item.time {
            shuttleStopLabel.textColor = SettingsStyle.Color.subwayPast
            shuttleTimeLabel.textColor = SettingsStyle.Color.subwayPast
        } else if startStop.time == item.time {
            applyCurrentStopStyle()
        }
    }

    private func formatTime(_ time: String) -> String {
        guard let date = time.toLocalTimeOrNil() else {
            return time.substring(from: 0, to: 4)
        }
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour,
              let minute = components.minute
        else {
            return time.substring(from: 0, to: 4)
        }
        return String(format: String(localized: "shuttle.shorten.time.%lld.%lld"), hour, minute)
    }
}
