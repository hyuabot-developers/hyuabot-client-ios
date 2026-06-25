import UIKit

protocol TabItemProtocol {
    func onSelected()
    func onDeselected()
}

class TabCell: UICollectionViewCell {
    let identifier: String = "TabCell"
    var leftConstraint = NSLayoutConstraint()
    var rightConstraint = NSLayoutConstraint()
    var topConstraint = NSLayoutConstraint()
    var bottomConstraint = NSLayoutConstraint()
    var contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
        didSet {
            leftConstraint.constant = contentInset.left
            rightConstraint.constant = contentInset.right
            topConstraint.constant = contentInset.top
            bottomConstraint.constant = contentInset.bottom
            contentView.layoutIfNeeded()
        }
    }

    var tabItem: TabItemProtocol? {
        didSet {
            setupUI()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.subviews.forEach { $0.removeFromSuperview() }
        tabItem = nil
    }

    private func setupUI() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        guard let itemView = tabItem as? UIView else { return }
        contentView.addSubview(itemView)
        itemView.translatesAutoresizingMaskIntoConstraints = false
        leftConstraint = itemView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        rightConstraint = itemView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        topConstraint = itemView.topAnchor.constraint(equalTo: contentView.topAnchor)
        bottomConstraint = itemView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        NSLayoutConstraint.activate([leftConstraint, rightConstraint, topConstraint, bottomConstraint])
    }
}
