import UIKit

class ContentViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var content: UIView? {
        didSet {
            setupUI()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.subviews.forEach { $0.removeFromSuperview() }
        content = nil
    }

    private func setupUI() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        guard let content else { return }
        contentView.addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
