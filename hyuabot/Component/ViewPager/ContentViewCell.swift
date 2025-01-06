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
    
    private func setupUI() {
        guard let content = self.content else { return }
        self.contentView.addSubview(content)
        self.contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
