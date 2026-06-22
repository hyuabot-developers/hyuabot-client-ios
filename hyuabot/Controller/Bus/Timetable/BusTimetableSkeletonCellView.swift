import UIKit

final class BusTimetableSkeletonCellView: UITableViewCell {
    static let reuseIdentifier = "BusTimetableSkeletonCellView"

    private let routePlaceholder = UIView()
    private let timePlaceholder = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        startAnimating()
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .systemBackground

        [routePlaceholder, timePlaceholder].forEach { view in
            view.backgroundColor = .secondarySystemFill
            view.layer.cornerRadius = 4
            view.layer.masksToBounds = true
            contentView.addSubview(view)
        }

        routePlaceholder.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.equalTo(74)
            make.height.equalTo(18)
            make.verticalEdges.equalToSuperview().inset(15)
        }
        timePlaceholder.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.equalTo(64)
            make.height.equalTo(18)
        }

        startAnimating()
    }

    private func startAnimating() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.45
        animation.toValue = 1.0
        animation.duration = 0.9
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        [routePlaceholder, timePlaceholder].forEach { view in
            view.layer.removeAnimation(forKey: "busTimetableSkeletonOpacity")
            view.layer.add(animation, forKey: "busTimetableSkeletonOpacity")
        }
    }
}
