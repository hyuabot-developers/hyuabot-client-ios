import UIKit
import Then
import SnapKit

class ShuttleRealtimeFooterView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "ShuttleRealtimeFooterView"
    private var showEntireTimetable: ((_ stop: ShuttleStopEnum, _ section: Int) -> Void)?
    private var stopID: ShuttleStopEnum?
    private var section: Int?

    let busAlternativeContainer = UIView()
    private let busAlternativeStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
        $0.alignment = .fill
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
        busAlternativeContainer.addSubview(busAlternativeStackView)
        busAlternativeStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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

    func setupUI(stopID: ShuttleStopEnum, section: Int, busAlternatives: [ShuttleBusAlternativeDisplayData], forceShow: Bool = false, showEntireTimetable: @escaping (_ stop: ShuttleStopEnum, _ section: Int) -> Void) {
        self.stopID = stopID
        self.section = section
        self.showEntireTimetable = showEntireTimetable

        busAlternativeStackView.arrangedSubviews.forEach {
            busAlternativeStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let alternatives = forceShow && busAlternatives.isEmpty
            ? [ShuttleBusAlternativeDisplayData(
                routeName: String(localized: String.LocalizationValue(stopID == .station ? "shuttle.bus.alternative.route.campus" : "shuttle.bus.alternative.route")),
                minutes: nil,
                color: .busGreen
            )]
            : busAlternatives

        guard !alternatives.isEmpty else {
            busAlternativeContainer.isHidden = true
            return
        }

        alternatives.forEach { alternative in
            let row = makeAlternativeRow(alternative: alternative)
            busAlternativeStackView.addArrangedSubview(row)
            row.snp.makeConstraints { make in
                make.height.equalTo(50)
            }
        }
        busAlternativeContainer.isHidden = false
    }

    private func makeAlternativeRow(alternative: ShuttleBusAlternativeDisplayData) -> UIView {
        let row = UIView()
        let accent = UIView().then {
            $0.backgroundColor = alternative.color
        }
        let route = UILabel().then {
            $0.font = .godo(size: 16, weight: .bold)
            $0.textColor = alternative.color
            $0.text = alternative.routeName
            $0.adjustsFontSizeToFitWidth = true
            $0.minimumScaleFactor = 0.75
        }
        let time = UILabel().then {
            $0.font = .godo(size: 16, weight: .medium)
            $0.textAlignment = .right
            if let minutes = alternative.minutes {
                $0.text = String(localized: "shuttle.bus.alternative.time.\(minutes)")
            } else {
                $0.text = String(localized: "shuttle.bus.alternative.no.data")
            }
        }

        row.addSubview(accent)
        row.addSubview(route)
        row.addSubview(time)
        accent.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(4)
        }
        route.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        time.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(route.snp.trailing).offset(8)
        }
        return row
    }

    @objc func showEntireTimeTable() {
        AnalyticsManager.logSelect(.shuttleShowEntireTimetable)
        guard let stopID = self.stopID, let section = self.section else { return }
        self.showEntireTimetable?(stopID, section)
    }
}
