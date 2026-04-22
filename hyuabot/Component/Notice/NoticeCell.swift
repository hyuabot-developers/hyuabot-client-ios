import UIKit

class NoticeCell: UICollectionViewCell {
    static let reuseIdentifier = "NoticeCell"
    
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 14, weight: .medium)
        $0.textAlignment = .center
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }
    
    var onTap: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        self.contentView.addGestureRecognizer(tapGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI(with notice: Notice) {
        self.titleLabel.text = String(localized: "notice.title.\(notice.title)")
        self.contentView.isUserInteractionEnabled = notice.url != nil
    }
    
    @objc private func didTap() {
        self.onTap?()
    }
}
