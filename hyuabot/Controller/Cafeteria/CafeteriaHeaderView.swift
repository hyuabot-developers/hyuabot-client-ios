import UIKit

class CafeteriaHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "CafeteriaHeaderView"
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.textColor = .white
        $0.textAlignment = .center
    }
    private var showCafeteriaInfoVC: () -> () = {}
    private lazy var infoButton = UIButton().then {
        $0.setImage(UIImage(systemName: "info.circle"), for: .normal)
        $0.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        $0.tintColor = .white
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI(title: String, runningTime: String?, showCafeteriaInfoVC: @escaping () -> ()) {
        self.showCafeteriaInfoVC = showCafeteriaInfoVC
        self.contentView.backgroundColor = .hanyangBlue
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(infoButton)
        self.titleLabel.text = title
        self.titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.infoButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(30)
        }
    }
    
    @objc private func infoButtonTapped() {
        self.showCafeteriaInfoVC()
    }
}
