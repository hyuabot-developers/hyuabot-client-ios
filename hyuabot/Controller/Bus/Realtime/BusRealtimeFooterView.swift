import UIKit

class BusRealtimeFooterView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "BusRealtimeFooterView"
    private var showEntireTimetable: ((_ stopID: Int32, _ routes: [Int32], _ title: String.LocalizationValue) -> Void)?
    private var showDepartureLog: ((_ stopID: Int32, _ routes: [Int32]) -> Void)?
    private var stopID: Int32?
    private var routes: [Int32] = []
    private var title: String.LocalizationValue?
    private let showEntireTimeTableButton = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString.init(String(localized: "bus.show.entire.timetable"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        $0.configuration = conf
        $0.tintColor = .plainButtonText
    }
    private let showDeparuteLogButton = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString.init(String(localized: "bus.show.departure.log"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        $0.configuration = conf
        $0.tintColor = .plainButtonText
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
        self.contentView.addSubview(buttonStackView)
        self.showEntireTimeTableButton.addTarget(self, action: #selector(entireTimetableButtonTapped), for: .touchUpInside)
        self.showDeparuteLogButton.addTarget(self, action: #selector(departureLogButtonTapped), for: .touchUpInside)
        self.buttonStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc func entireTimetableButtonTapped() {
        guard let stopID = self.stopID, let title = self.title else { return }
        self.showEntireTimetable?(stopID, routes, title)
    }
    
    @objc func departureLogButtonTapped() {
        guard let stopID = self.stopID else { return }
        self.showDepartureLog?(stopID, routes)
    }
}
