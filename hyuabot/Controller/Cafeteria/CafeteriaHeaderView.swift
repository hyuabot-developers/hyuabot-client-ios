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

    private var showCafeteriaInfoVC: () -> Void = {}
    lazy var infoButton = UIButton().then {
        $0.setImage(UIImage(systemName: "info.circle"), for: .normal)
        $0.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        $0.tintColor = .white
    }

    private lazy var nameStackView: UIStackView = .init(arrangedSubviews: [titleLabel, runningTimeLabel]).then {
        $0.axis = .vertical
        $0.spacing = 5
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI(id: Int, runningTime: String?, hasMenu: Bool = true, showCafeteriaInfoVC: @escaping () -> Void) {
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
        titleLabel.text = title
        self.showCafeteriaInfoVC = showCafeteriaInfoVC
        contentView.addSubview(nameStackView)
        contentView.addSubview(infoButton)
        contentView.backgroundColor = .hanyangBlue
        if let runningTime {
            if let status = cafeteriaStatusText(runningTime: runningTime, hasMenu: hasMenu) {
                runningTimeLabel.text = String(
                    format: String(localized: "cafeteria.running.time.status.%@.%@"),
                    runningTime,
                    status
                )
            } else {
                runningTimeLabel.text = String(format: String(localized: "cafeteria.running.time.%@"), runningTime)
            }
        } else {
            runningTimeLabel.text = String(localized: "cafeteria.running.time")
        }
        nameStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }
        infoButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(45)
        }
    }

    @objc private func infoButtonTapped() {
        AnalyticsManager.logSelect(.cafeteriaInfoButton)
        showCafeteriaInfoVC()
    }

    private func cafeteriaStatusText(runningTime: String, hasMenu: Bool) -> String? {
        guard let status = CafeteriaStatusResolver.status(runningTime: runningTime, hasMenu: hasMenu) else { return nil }
        return String(localized: status.localizationKey)
    }
}
