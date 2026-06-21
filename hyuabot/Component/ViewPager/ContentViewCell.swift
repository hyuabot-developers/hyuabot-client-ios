import UIKit

class ContentViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    var content: UIView? {
        didSet {
            self.setupUI()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.contentView.subviews.forEach { $0.removeFromSuperview() }
        self.content = nil
    }
    
    private func setupUI() {
        self.contentView.subviews.forEach { $0.removeFromSuperview() }
        guard let content = self.content else { return }
        self.contentView.addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
