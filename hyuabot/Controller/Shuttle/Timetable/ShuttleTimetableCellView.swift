import Api
import UIKit

class ShuttleTimetableCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleTimetableCellView"
    var item: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order?
    private let routeMarkerView = UIView().then { $0.layer.cornerRadius = 2 }
    private let shuttleTypeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
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

    private func setupUI() {
        contentView.addSubview(routeMarkerView)
        contentView.addSubview(shuttleTypeLabel)
        contentView.addSubview(shuttleTimeLabel)
        selectionStyle = .none
        routeMarkerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.equalTo(4)
            make.height.equalTo(24)
        }
        shuttleTypeLabel.snp.makeConstraints { make in
            make.leading.equalTo(routeMarkerView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        shuttleTimeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }

    // swiftlint:disable:next function_body_length
    func setupUI(option: ShuttleTimetableOptions, item: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order) {
        if option.start == "shuttle.stop.dormitory.out" || option.start == "shuttle.stop.shuttlecock.out" {
            if option.end == "shuttle.destination.shorten.station" {
                if item.route.tag == "DH" || item.route.tag == "DJ" {
                    shuttleTypeLabel.text = String(localized: "shuttle.type.direct")
                    shuttleTypeLabel.textColor = .busRed
                } else if item.route.tag == "C" {
                    shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
                    if UITraitCollection.current.userInterfaceStyle == .light {
                        shuttleTypeLabel.textColor = .busBlue
                    } else {
                        shuttleTypeLabel.textColor = .white
                    }
                }
            } else if option.end == "shuttle.destination.shorten.terminal" {
                if item.route.tag == "DY" {
                    shuttleTypeLabel.text = String(localized: "shuttle.type.direct")
                    shuttleTypeLabel.textColor = .busRed
                } else if item.route.tag == "C" {
                    shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
                    if UITraitCollection.current.userInterfaceStyle == .light {
                        shuttleTypeLabel.textColor = .busBlue
                    } else {
                        shuttleTypeLabel.textColor = .white
                    }
                }
            } else if option.end == "shuttle.destination.shorten.jungang_station" {
                shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
                shuttleTypeLabel.textColor = .hanyangGreen
            }
        } else if option.start == "shuttle.stop.station" {
            if option.end == "shuttle.destination.shorten.campus" {
                if item.route.tag == "DH" {
                    shuttleTypeLabel.text = String(localized: "shuttle.type.direct")
                    shuttleTypeLabel.textColor = .busRed
                } else if item.route.tag == "DJ" {
                    shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
                    shuttleTypeLabel.textColor = .hanyangGreen
                } else if item.route.tag == "C" {
                    shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
                    if UITraitCollection.current.userInterfaceStyle == .light {
                        shuttleTypeLabel.textColor = .busBlue
                    } else {
                        shuttleTypeLabel.textColor = .white
                    }
                }
            } else if option.end == "shuttle.destination.shorten.terminal" {
                shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
                if UITraitCollection.current.userInterfaceStyle == .light {
                    shuttleTypeLabel.textColor = .busBlue
                } else {
                    shuttleTypeLabel.textColor = .white
                }
            } else if option.end == "shuttle.destination.shorten.jungang_station" {
                shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
                shuttleTypeLabel.textColor = .hanyangGreen
            }
        } else if option.start == "shuttle.stop.terminal" || option.start == "shuttle.stop.jungang.station" || option
            .start == "shuttle.stop.shuttlecock.in"
        {
            shuttleTypeLabel.textColor = .label
            if item.route.name.hasSuffix("S") {
                shuttleTypeLabel.text = String(localized: "shuttle.type.shuttlecock")
            } else if item.route.name.hasSuffix("D") {
                shuttleTypeLabel.text = String(localized: "shuttle.type.dormitory")
            }
        }
        shuttleTypeLabel.textColor = .label
        routeMarkerView.backgroundColor = item.route.tag == "DJ" ? .hanyangGreen
            : (item.route.tag == "C" || item.route.name.hasSuffix("D") ? .busBlue : .busRed)
        self.item = item
        let components = Calendar.current.dateComponents([.hour, .minute], from: item.time.toLocalTime())
        shuttleTimeLabel.text = String(
            format: String(localized: "shuttle.time.%lld.%lld"),
            components.hour!,
            components.minute!
        )
    }
}
