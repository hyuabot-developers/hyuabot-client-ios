import UIKit
import Api
import RxSwift

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
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.contentView.addSubview(self.busRouteLabel)
        self.contentView.addSubview(self.busTimeStackView)
        self.selectionStyle = .none
        self.busRouteLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        self.busTimeStackView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }
    
    func setupUI(item: BusStopDialogQuery.Data.Bus) {
        self.busRouteLabel.text = item.route.name
        self.setRouteColor(routeName: item.route.name)
        self.setUITimeLabel(item: item)
    }
    
    func setRouteColor(routeName: String) {
        if routeName == "10-1" || routeName == "50" {
            self.busRouteLabel.textColor = .busGreen
        } else {
            self.busRouteLabel.textColor = .busRed
        }
    }
    
    func setUITimeLabel(item: BusStopDialogQuery.Data.Bus) {
        let upFirst = item.route.runningTime.up.first.substring(from: 0, to: 4)
        let upLast = item.route.runningTime.up.last.substring(from: 0, to: 4)
        let downFirst = item.route.runningTime.down.first.substring(from: 0, to: 4)
        let downLast = item.route.runningTime.down.last.substring(from: 0, to: 4)
        
        self.busUpTimeLabel.text = String(localized: "bus.first.last.\(item.route.runningTime.up.terminal.name).\(upFirst).\(upLast)")
        self.busDownTimeLabel.text = String(localized: "bus.first.last.\(item.route.runningTime.down.terminal.name).\(downFirst).\(downLast)")
    }
}
