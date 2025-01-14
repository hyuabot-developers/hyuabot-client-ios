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
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                else { return }
        if windowScene.traitCollection.userInterfaceStyle == .dark {
            $0.tintColor = .white
        }
        conf.attributedTitle = title
        $0.configuration = conf
    }
    private let showDeparuteLogButton = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString.init(String(localized: "bus.show.departure.log"))
        title.font = .godo(size: 16, weight: .medium)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                else { return }
        if windowScene.traitCollection.userInterfaceStyle == .dark {
            $0.tintColor = .white
        }
        conf.attributedTitle = title
        $0.configuration = conf
    }
    private lazy var buttonStackView: UIStackView = {
        let separator = UIView().then {
            $0.backgroundColor = .gray
        }
        separator.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(20)
        }
        let stackView = UIStackView(arrangedSubviews: [showEntireTimeTableButton, separator, showDeparuteLogButton])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 16
        return stackView
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
