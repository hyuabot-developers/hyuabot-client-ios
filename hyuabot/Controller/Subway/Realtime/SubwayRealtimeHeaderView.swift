import UIKit

class SubwayRealtimeHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "SubwayRealtimeHeaderView"
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.textColor = .white
        $0.textAlignment = .center
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI(title: String) {
        contentView.backgroundColor = .hanyangBlue
        contentView.addSubview(titleLabel)
        titleLabel.text = title
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
