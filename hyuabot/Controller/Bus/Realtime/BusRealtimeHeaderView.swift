import UIKit

class BusRealtimeHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "BusRealtimeHeaderView"
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.textColor = .white
        $0.textAlignment = .center
    }
    private var showStopVC: () -> () = {}
    private lazy var locationButton = UIButton().then {
        $0.setImage(UIImage(systemName: "location.magnifyingglass"), for: .normal)
        $0.addTarget(self, action: #selector(stopButtonTapped), for: .touchUpInside)
        $0.tintColor = .white
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI(title: String, showStopVC: @escaping () -> ()) {
        self.showStopVC = showStopVC
        self.contentView.backgroundColor = .hanyangBlue
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(locationButton)
        self.titleLabel.text = title
        self.titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.locationButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(30)
        }
    }
    
    @objc private func stopButtonTapped() {
        self.showStopVC()
    }
}
