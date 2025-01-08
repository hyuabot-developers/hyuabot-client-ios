import UIKit

class ShuttleRealtimeFooterView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "ShuttleRealtimeFooterView"
    private var showEntireTimetable: ((_ stop: ShuttleStopEnum, _ section: Int) -> Void)?
    private var stopID: ShuttleStopEnum?
    private var section: Int?
    private let showEntireTimeTableButton = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString.init(String(localized: "shuttle.show.entire.timetable"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        $0.configuration = conf
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI(stopID: ShuttleStopEnum, section: Int, showEntireTimetable: @escaping (_ stop: ShuttleStopEnum, _ section: Int) -> Void) {
        self.stopID = stopID
        self.section = section
        self.showEntireTimetable = showEntireTimetable
        self.contentView.addSubview(showEntireTimeTableButton)
        self.showEntireTimeTableButton.addTarget(self, action: #selector(showEntireTimeTable), for: .touchUpInside)
        self.showEntireTimeTableButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc func showEntireTimeTable() {
        guard let stopID = self.stopID, let section = self.section else { return }
        self.showEntireTimetable?(stopID, section)
    }
}
