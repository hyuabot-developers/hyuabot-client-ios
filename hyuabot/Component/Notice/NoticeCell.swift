//
//  NoticeCell.swift
//  hyuabot
//

import UIKit

struct NoticeTitleStyle: Equatable {
    let font: UIFont
    let alignment: NSTextAlignment
    let horizontalInset: CGFloat
    let lineHeight: CGFloat?
    let shrinksToFit: Bool

    static let standard = NoticeTitleStyle(
        font: .godo(size: 14, weight: .medium),
        alignment: .center,
        horizontalInset: 12,
        lineHeight: nil,
        shrinksToFit: true
    )
}

class NoticeCell: UICollectionViewCell {
    static let reuseIdentifier = "NoticeCell"

    private let titleLabel = UILabel().then {
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
        $0.adjustsFontForContentSizeCategory = true
    }

    var onTap: (() -> Void)?
    var titleColor: UIColor = .label {
        didSet {
            titleLabel.textColor = titleColor
        }
    }
    var titleStyle: NoticeTitleStyle = .standard {
        didSet {
            applyTitleStyle()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        applyTitleStyle()
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        contentView.addGestureRecognizer(tapGesture)
    }

    private func applyTitleStyle() {
        titleLabel.font = titleStyle.font
        titleLabel.textAlignment = titleStyle.alignment
        titleLabel.adjustsFontSizeToFitWidth = titleStyle.shrinksToFit
        titleLabel.minimumScaleFactor = titleStyle.shrinksToFit ? 0.82 : 1
        titleLabel.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(titleStyle.horizontalInset)
            if let lineHeight = titleStyle.lineHeight {
                make.centerY.equalToSuperview()
                make.height.equalTo(lineHeight)
            } else {
                make.top.bottom.equalToSuperview()
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI(with notice: Notice) {
        titleLabel.textColor = titleColor
        titleLabel.setKoreanTranslatedText(notice.title)
        contentView.isUserInteractionEnabled = notice.url != nil
    }

    @objc
    private func didTap() {
        onTap?()
    }
}
