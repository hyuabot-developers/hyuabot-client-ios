import UIKit

class BusRealtimeFooterView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "BusRealtimeFooterView"
    private var showEntireTimetable: ((_ stopID: Int, _ routes: [Int]) -> Void)?
    private var showDepartureLog: ((_ stopID: Int, _ routes: [Int]) -> Void)?
    private var stopID: Int?
    private var routes: [Int] = []
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
        stopID: Int,
        routes: [Int],
        showEntireTimetable: @escaping (_ stop: Int, _ routes: [Int]) -> Void,
        showDepartureLog: @escaping (_ stop: Int, _ routes: [Int]) -> Void
    ) {
        self.stopID = stopID
        self.routes = routes
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
        guard let stopID = self.stopID else { return }
        self.showEntireTimetable?(stopID, routes)
    }
    
    @objc func departureLogButtonTapped() {
        guard let stopID = self.stopID else { return }
        self.showDepartureLog?(stopID, routes)
    }
}
