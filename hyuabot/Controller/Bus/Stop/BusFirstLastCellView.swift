import Api
import RxSwift
import UIKit

class BusFirstLastCellView: UITableViewCell {
    static let reuseIdentifier = "BusFirstLastCellView"
    private let busRouteLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
    }

    private let busUpTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
    }

    private let busDownTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
    }

    private lazy var busTimeStackView = UIStackView().then {
        $0.addArrangedSubview(self.busUpTimeLabel)
        $0.addArrangedSubview(self.busDownTimeLabel)
        $0.axis = .vertical
        $0.alignment = .trailing
        $0.spacing = 10
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
        contentView.addSubview(busRouteLabel)
        contentView.addSubview(busTimeStackView)
        selectionStyle = .none
        busRouteLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        busTimeStackView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }

    func setupUI(item: BusStopDialogQuery.Data.Bus) {
        busRouteLabel.text = item.route.name
        setRouteColor(routeName: item.route.name)
        setUITimeLabel(item: item)
    }

    func setRouteColor(routeName: String) {
        if routeName == "10-1" || routeName == "50" {
            busRouteLabel.textColor = .busGreen
        } else {
            busRouteLabel.textColor = .busRed
        }
    }

    func setUITimeLabel(item: BusStopDialogQuery.Data.Bus) {
        let upFirst = item.route.runningTime.up.first.substring(from: 0, to: 4)
        let upLast = item.route.runningTime.up.last.substring(from: 0, to: 4)
        let downFirst = item.route.runningTime.down.first.substring(from: 0, to: 4)
        let downLast = item.route.runningTime.down.last.substring(from: 0, to: 4)

        busUpTimeLabel.setKoreanTranslatedText(String(
            format: String(localized: "bus.first.last.%@.%@.%@"),
            item.route.runningTime.up.terminal.name,
            upFirst,
            upLast
        ))
        busDownTimeLabel.setKoreanTranslatedText(String(
            format: String(localized: "bus.first.last.%@.%@.%@"),
            item.route.runningTime.down.terminal.name,
            downFirst,
            downLast
        ))
    }
}
