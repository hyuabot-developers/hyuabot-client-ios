import UIKit

class BusRealtimeHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "BusRealtimeHeaderView"
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.textColor = .white
        $0.textAlignment = .center
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI(title: String) {
        self.contentView.backgroundColor = .hanyangBlue
        self.contentView.addSubview(titleLabel)
        self.titleLabel.text = title
        self.titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
