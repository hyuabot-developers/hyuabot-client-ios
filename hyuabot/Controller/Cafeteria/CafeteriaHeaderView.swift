import UIKit

class CafeteriaHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "CafeteriaHeaderView"
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.textColor = .white
        $0.textAlignment = .center
    }
    private let runningTimeLabel = UILabel().then {
        $0.font = .godo(size: 12, weight: .regular)
        $0.textColor = .white
        $0.textAlignment = .center
    }
    private var showCafeteriaInfoVC: () -> () = {}
    lazy var infoButton = UIButton().then {
        $0.setImage(UIImage(systemName: "info.circle"), for: .normal)
        $0.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        $0.tintColor = .white
    }
    private lazy var nameStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [titleLabel, runningTimeLabel]).then {
            $0.axis = .vertical
            $0.spacing = 5
        }
        return view
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI(id: Int, runningTime: String?, hasMenu: Bool = true, showCafeteriaInfoVC: @escaping () -> ()) {
        var title = ""
        switch id {
        case 1:
            title = String(localized: "cafeteria.title.1")
        case 2:
            title = String(localized: "cafeteria.title.2")
        case 4:
            title = String(localized: "cafeteria.title.4")
        case 6:
            title = String(localized: "cafeteria.title.6")
        case 7:
            title = String(localized: "cafeteria.title.7")
        case 8:
            title = String(localized: "cafeteria.title.8")
        case 11:
            title = String(localized: "cafeteria.title.11")
        case 12:
            title = String(localized: "cafeteria.title.12")
        case 13:
            title = String(localized: "cafeteria.title.13")
        case 14:
            title = String(localized: "cafeteria.title.14")
        case 15:
            title = String(localized: "cafeteria.title.15")
        default:
            title = String(localized: "cafeteria.title.1")
        }
        self.titleLabel.text = title
        self.showCafeteriaInfoVC = showCafeteriaInfoVC
        self.contentView.addSubview(nameStackView)
        self.contentView.addSubview(infoButton)
        self.contentView.backgroundColor = .hanyangBlue
        if let runningTime {
            if let status = cafeteriaStatusText(runningTime: runningTime, hasMenu: hasMenu) {
                self.runningTimeLabel.text = String(
                    format: String(localized: "cafeteria.running.time.status.%@.%@"),
                    runningTime,
                    status
                )
            } else {
                self.runningTimeLabel.text = String(format: String(localized: "cafeteria.running.time.%@"), runningTime)
            }
        } else {
            self.runningTimeLabel.text = String(localized: "cafeteria.running.time")
        }
        self.nameStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }
        self.infoButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(45)
        }
    }
    
    @objc private func infoButtonTapped() {
        AnalyticsManager.logSelect(.cafeteriaInfoButton)
        self.showCafeteriaInfoVC()
    }

    private func cafeteriaStatusText(runningTime: String, hasMenu: Bool) -> String? {
        if !hasMenu { return String(localized: "cafeteria.status.no.menu") }
        let times = runningTime.matches(of: /\d{1,2}:\d{2}/)
            .prefix(2)
            .compactMap { match -> Date? in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return formatter.date(from: String(match.output))
            }
        guard times.count == 2 else {
            return nil
        }
        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.hour, .minute], from: Date())
        let startComponents = calendar.dateComponents([.hour, .minute], from: times[0])
        let endComponents = calendar.dateComponents([.hour, .minute], from: times[1])
        let nowMinutes = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        if nowMinutes < startMinutes { return String(localized: "cafeteria.status.soon") }
        if nowMinutes > endMinutes { return String(localized: "cafeteria.status.closed") }
        return String(localized: "cafeteria.status.open")
    }
}
