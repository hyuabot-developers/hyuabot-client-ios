import UIKit

class BusRealtimeFooterView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "BusRealtimeFooterView"
    private var showEntireTimetable: ((_ stopID: Int32, _ routes: [Int32], _ title: String.LocalizationValue) -> Void)?
    private var showDepartureLog: ((_ stopID: Int32, _ routes: [Int32]) -> Void)?
    private var stopID: Int32?
    private var routes: [Int32] = []
    private var title: String.LocalizationValue?
    let showEntireTimeTableButton = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString(String(localized: "bus.show.entire.timetable"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        conf.titleLineBreakMode = .byTruncatingTail
        $0.configuration = conf
        $0.tintColor = .plainButtonText
        $0.titleLabel?.adjustsFontSizeToFitWidth = true
        $0.titleLabel?.minimumScaleFactor = 0.6
    }

    let showDeparuteLogButton = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString(String(localized: "bus.show.departure.log"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        conf.titleLineBreakMode = .byTruncatingTail
        $0.configuration = conf
        $0.tintColor = .plainButtonText
        $0.titleLabel?.adjustsFontSizeToFitWidth = true
        $0.titleLabel?.minimumScaleFactor = 0.6
    }

    private lazy var buttonStackView: UIView = {
        let view = UIView()
        let separator = UIView().then {
            $0.backgroundColor = .gray
        }
        view.addSubview(showEntireTimeTableButton)
        view.addSubview(separator)
        view.addSubview(showDeparuteLogButton)

        separator.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(20)
            make.center.equalToSuperview()
        }
        showEntireTimeTableButton.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalToSuperview().dividedBy(2)
        }
        showDeparuteLogButton.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.width.equalToSuperview().dividedBy(2)
        }
        return view
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI(
        stopID: Int32,
        routes: [Int32],
        title: String.LocalizationValue,
        showEntireTimetable: @escaping (_ stop: Int32, _ routes: [Int32], _ title: String.LocalizationValue) -> Void,
        showDepartureLog: @escaping (_ stop: Int32, _ routes: [Int32]) -> Void
    ) {
        self.stopID = stopID
        self.routes = routes
        self.title = title
        self.showEntireTimetable = showEntireTimetable
        self.showDepartureLog = showDepartureLog
        contentView.addSubview(buttonStackView)
        showEntireTimeTableButton.addTarget(self, action: #selector(entireTimetableButtonTapped), for: .touchUpInside)
        showDeparuteLogButton.addTarget(self, action: #selector(departureLogButtonTapped), for: .touchUpInside)
        buttonStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc func entireTimetableButtonTapped() {
        AnalyticsManager.logSelect(.busShowEntireTimetable)
        guard let stopID, let title else { return }
        showEntireTimetable?(stopID, routes, title)
    }

    @objc func departureLogButtonTapped() {
        AnalyticsManager.logSelect(.busShowDepartureLog)
        guard let stopID else { return }
        showDepartureLog?(stopID, routes)
    }
}
