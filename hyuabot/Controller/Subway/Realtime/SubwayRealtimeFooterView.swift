import UIKit

class SubwayRealtimeFooterView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "SubwayRealtimeFooterView"
    private var showEntireTimetable: () -> Void = {}
    private let showEntireTimeTableButton = UIButton().then {
        var conf = UIButton.Configuration.plain()
        var title = AttributedString(String(localized: "subway.show.entire.timetable"))
        title.font = .godo(size: 16, weight: .medium)
        conf.attributedTitle = title
        $0.configuration = conf
        $0.tintColor = .plainButtonText
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundView = UIView().then {
            $0.backgroundColor = .systemBackground
        }
        contentView.backgroundColor = .systemBackground
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI(tabType: SubwayTabType, showEntireTimetable: @escaping () -> Void) {
        showEntireTimeTableButton.isEnabled = tabType != .transfer
        self.showEntireTimetable = showEntireTimetable
        contentView.backgroundColor = .systemBackground
        contentView.addSubview(showEntireTimeTableButton)
        showEntireTimeTableButton.addTarget(self, action: #selector(showEntireTimeTable), for: .touchUpInside)
        showEntireTimeTableButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc func showEntireTimeTable() {
        AnalyticsManager.logSelect(.subwayShowEntireTimetable)
        showEntireTimetable()
    }
}
