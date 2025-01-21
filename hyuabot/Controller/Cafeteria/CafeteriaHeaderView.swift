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
    private lazy var infoButton = UIButton().then {
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
    
    func setupUI(id: Int, runningTime: String?, showCafeteriaInfoVC: @escaping () -> ()) {
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
        self.runningTimeLabel.text = String(localized: "cafeteria.running.time.\(runningTime ?? "")")
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
        self.showCafeteriaInfoVC()
    }
}
