import UIKit

class ShuttleRealtimeFooterView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "ShuttleRealtimeFooterView"
    private var stopID: String?
    private var destination: String?
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
    
    func setupUI(stopID: String, destination: String) {
        self.stopID = stopID
        self.destination = destination
        self.contentView.addSubview(showEntireTimeTableButton)
        self.showEntireTimeTableButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
