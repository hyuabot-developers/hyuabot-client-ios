import Api
import RxSwift
import UIKit

class ShuttleViaCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleViaCellView"
    private let shuttleStopLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
    }

    private let shuttleTimeLabel = UILabel().then {
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

    override func prepareForReuse() {
        super.prepareForReuse()
        shuttleStopLabel.textColor = .label
        shuttleTimeLabel.textColor = .label
    }

    func setupUI() {
        contentView.addSubview(shuttleStopLabel)
        contentView.addSubview(shuttleTimeLabel)
        selectionStyle = .none
        shuttleStopLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        shuttleTimeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
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
            shuttleStopLabel.textColor = .gray
            shuttleTimeLabel.textColor = .gray
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
            shuttleStopLabel.textColor = .gray
            shuttleTimeLabel.textColor = .gray
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
            shuttleStopLabel.textColor = .gray
            shuttleTimeLabel.textColor = .gray
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
