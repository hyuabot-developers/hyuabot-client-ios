import UIKit

final class CafeteriaSkeletonHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "CafeteriaSkeletonHeaderView"

    private let titlePlaceholder = UIView()
    private let timePlaceholder = UIView()
    private let infoPlaceholder = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        startAnimating()
    }

    private func setupUI() {
        contentView.backgroundColor = .hanyangBlue
        for view in [titlePlaceholder, timePlaceholder, infoPlaceholder] {
            view.backgroundColor = UIColor.white.withAlphaComponent(0.36)
            view.layer.cornerRadius = 4
            view.layer.masksToBounds = true
            contentView.addSubview(view)
        }

        titlePlaceholder.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(14)
            make.width.equalTo(120)
            make.height.equalTo(16)
        }
        timePlaceholder.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(titlePlaceholder.snp.bottom).offset(8)
            make.width.equalTo(180)
            make.height.equalTo(12)
        }
        infoPlaceholder.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
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

        for view in [titlePlaceholder, timePlaceholder, infoPlaceholder] {
            view.layer.removeAnimation(forKey: "cafeteriaSkeletonOpacity")
            view.layer.add(animation, forKey: "cafeteriaSkeletonOpacity")
        }
    }
}

final class CafeteriaSkeletonCellView: UITableViewCell {
    static let reuseIdentifier = "CafeteriaSkeletonCellView"

    private let menuPlaceholder = UIView()
    private let pricePlaceholder = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
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

        for view in [menuPlaceholder, pricePlaceholder] {
            view.backgroundColor = .secondarySystemFill
            view.layer.cornerRadius = 4
            view.layer.masksToBounds = true
            contentView.addSubview(view)
        }

        menuPlaceholder.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(16)
            make.width.equalToSuperview().multipliedBy(0.58)
            make.height.equalTo(16)
        }
        pricePlaceholder.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(menuPlaceholder.snp.bottom).offset(10)
            make.bottom.equalToSuperview().inset(16)
            make.width.equalTo(70)
            make.height.equalTo(16)
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

        for view in [menuPlaceholder, pricePlaceholder] {
            view.layer.removeAnimation(forKey: "cafeteriaSkeletonOpacity")
            view.layer.add(animation, forKey: "cafeteriaSkeletonOpacity")
        }
    }
}
