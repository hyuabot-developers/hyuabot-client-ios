import UIKit

class TabItem: UIView, TabItemProtocol {
    let title: String
    private lazy var titleLabel = UILabel().then {
        $0.font = .godo(size: 18, weight: .medium)
        $0.text = title
        $0.textColor = .white
        $0.textAlignment = .center
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.6
        $0.lineBreakMode = .byTruncatingTail
    }

    private let indicatorView = UIView().then {
        $0.backgroundColor = .white
    }

    init(title: String) {
        self.title = title
        super.init(frame: .zero)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func onSelected() {
        titleLabel.font = .godo(size: 18, weight: .bold)
        if indicatorView.superview == nil {
            addSubview(indicatorView)
            indicatorView.snp.makeConstraints {
                $0.leading.trailing.bottom.equalToSuperview()
                $0.height.equalTo(3)
            }
        }
    }

    func onDeselected() {
        titleLabel.font = .godo(size: 18, weight: .medium)
        layer.shadowOpacity = 0
        indicatorView.removeFromSuperview()
    }

    func setupUI() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}
