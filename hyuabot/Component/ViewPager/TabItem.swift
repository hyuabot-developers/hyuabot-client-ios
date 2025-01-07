import UIKit

class TabItem: UIView, TabItemProtocol {
    private let title: String
    private lazy var titleLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .medium)
        $0.text = title
        $0.textColor = .white
        $0.textAlignment = .center
    }
    private let indicatorView = UIView().then {
        $0.backgroundColor = .white
    }
    
    init(title: String) {
        self.title = title
        super.init(frame: .zero)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func onSelected() {
        self.titleLabel.font = .godo(size: 18, weight: .bold)
        if self.indicatorView.superview == nil {
            self.addSubview(self.indicatorView)
            self.indicatorView.snp.makeConstraints {
                $0.leading.trailing.bottom.equalToSuperview()
                $0.height.equalTo(3)
            }
        }
    }
    
    func onDeselected() {
        self.titleLabel.font = .godo(size: 16, weight: .medium)
        self.layer.shadowOpacity = 0
        self.indicatorView.removeFromSuperview()
    }
    
    func setupUI() {
        self.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}
