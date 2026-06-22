import UIKit

final class BusRealtimeSkeletonHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "BusRealtimeSkeletonHeaderView"

    private let titlePlaceholder = UIView()
    private let locationPlaceholder = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
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
        contentView.backgroundColor = .hanyangBlue
        [titlePlaceholder, locationPlaceholder].forEach { view in
            view.backgroundColor = UIColor.white.withAlphaComponent(0.36)
            view.layer.cornerRadius = 4
            view.layer.masksToBounds = true
            contentView.addSubview(view)
        }

        titlePlaceholder.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(160)
            make.height.equalTo(16)
        }
        locationPlaceholder.snp.makeConstraints { make in
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

        [titlePlaceholder, locationPlaceholder].forEach { view in
            view.layer.removeAnimation(forKey: "busRealtimeSkeletonOpacity")
            view.layer.add(animation, forKey: "busRealtimeSkeletonOpacity")
        }
    }
}

final class BusRealtimeSkeletonFooterView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "BusRealtimeSkeletonFooterView"

    private let leftPlaceholder = UIView()
    private let separator = UIView()
    private let rightPlaceholder = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
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
        separator.backgroundColor = .separator
        [leftPlaceholder, rightPlaceholder].forEach { view in
            view.backgroundColor = .secondarySystemFill
            view.layer.cornerRadius = 4
            view.layer.masksToBounds = true
            contentView.addSubview(view)
        }
        contentView.addSubview(separator)

        separator.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(20)
            make.center.equalToSuperview()
        }
        leftPlaceholder.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().multipliedBy(0.5)
            make.width.equalTo(118)
            make.height.equalTo(16)
        }
        rightPlaceholder.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().multipliedBy(1.5)
            make.width.equalTo(118)
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

        [leftPlaceholder, rightPlaceholder].forEach { view in
            view.layer.removeAnimation(forKey: "busRealtimeSkeletonOpacity")
            view.layer.add(animation, forKey: "busRealtimeSkeletonOpacity")
        }
    }
}

final class BusRealtimeSkeletonCellView: UITableViewCell {
    static let reuseIdentifier = "BusRealtimeSkeletonCellView"

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
            make.width.equalTo(112)
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
            view.layer.removeAnimation(forKey: "busRealtimeSkeletonOpacity")
            view.layer.add(animation, forKey: "busRealtimeSkeletonOpacity")
        }
    }
}
