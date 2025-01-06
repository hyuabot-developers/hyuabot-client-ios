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
            self.leftConstraint.constant = contentInset.left
            self.rightConstraint.constant = contentInset.right
            self.topConstraint.constant = contentInset.top
            self.bottomConstraint.constant = contentInset.bottom
            self.contentView.layoutIfNeeded()
        }
    }
    var tabItem: TabItemProtocol? {
        didSet {
            self.setupUI()
        }
    }
    
    override init(frame: CGRect) { super.init(frame: frame) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    private func setupUI() {
        guard let itemView = self.tabItem as? UIView else { return }
        self.contentView.addSubview(itemView)
        itemView.translatesAutoresizingMaskIntoConstraints = false
        leftConstraint = itemView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor)
        rightConstraint = itemView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor)
        topConstraint = itemView.topAnchor.constraint(equalTo: self.contentView.topAnchor)
        bottomConstraint = itemView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        NSLayoutConstraint.activate([leftConstraint, rightConstraint, topConstraint, bottomConstraint])
    }
}
