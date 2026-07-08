import UIKit

class NoticeCell: UICollectionViewCell {
    static let reuseIdentifier = "NoticeCell"

    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 14, weight: .medium)
        $0.textAlignment = .center
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.82
    }

    var onTap: (() -> Void)?
    var titleColor: UIColor = .label {
        didSet {
            titleLabel.textColor = titleColor
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
        }
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        contentView.addGestureRecognizer(tapGesture)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI(with notice: Notice) {
        titleLabel.textColor = titleColor
        if notice.title.hasPrefix("[") {
            titleLabel.setKoreanTranslatedText(notice.title)
        } else {
            titleLabel.setKoreanTranslatedText(String(format: String(localized: "notice.title.%@"), notice.title))
        }
        contentView.isUserInteractionEnabled = notice.url != nil
    }

    @objc private func didTap() {
        onTap?()
    }
}
