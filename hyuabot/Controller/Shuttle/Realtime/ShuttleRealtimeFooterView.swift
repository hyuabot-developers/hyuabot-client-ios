import UIKit
import Then
import SnapKit

class ShuttleRealtimeFooterView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "ShuttleRealtimeFooterView"
    private var showEntireTimetable: ((_ stop: ShuttleStopEnum, _ section: Int) -> Void)?
    private var stopID: ShuttleStopEnum?
    private var section: Int?

    private let busAlternativeContainer = UIView()
    private let busRouteLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.textColor = .busGreen
    }
    private let busTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .medium)
        $0.textAlignment = .right
    }
    let showEntireTimeTableButton = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString.init(String(localized: "shuttle.show.entire.timetable"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        $0.configuration = conf
        $0.tintColor = .plainButtonText
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        busAlternativeContainer.addSubview(busRouteLabel)
        busAlternativeContainer.addSubview(busTimeLabel)
        busRouteLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        busTimeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(busRouteLabel.snp.trailing).offset(8)
        }
        busAlternativeContainer.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        showEntireTimeTableButton.snp.makeConstraints { make in
            make.height.equalTo(50)
        }

        let stackView = UIStackView(arrangedSubviews: [busAlternativeContainer, showEntireTimeTableButton]).then {
            $0.axis = .vertical
            $0.spacing = 0
            $0.alignment = .fill
        }
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        showEntireTimeTableButton.addTarget(self, action: #selector(showEntireTimeTable), for: .touchUpInside)
        busAlternativeContainer.isHidden = true
    }

    func setupUI(stopID: ShuttleStopEnum, section: Int, busMinutes: Int?, showEntireTimetable: @escaping (_ stop: ShuttleStopEnum, _ section: Int) -> Void) {
        self.stopID = stopID
        self.section = section
        self.showEntireTimetable = showEntireTimetable
        if let minutes = busMinutes {
            busRouteLabel.text = String(localized: "shuttle.bus.alternative.route")
            busTimeLabel.text = String(localized: "shuttle.bus.alternative.time.\(minutes)")
            busAlternativeContainer.isHidden = false
        } else {
            busAlternativeContainer.isHidden = true
        }
    }

    @objc func showEntireTimeTable() {
        AnalyticsManager.logSelect(.shuttleShowEntireTimetable)
        guard let stopID = self.stopID, let section = self.section else { return }
        self.showEntireTimetable?(stopID, section)
    }
}
