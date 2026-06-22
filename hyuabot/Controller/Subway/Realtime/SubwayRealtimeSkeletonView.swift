import UIKit

final class SubwayRealtimeSkeletonHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "SubwayRealtimeSkeletonHeaderView"

    private let titlePlaceholder = UIView()

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
        titlePlaceholder.backgroundColor = UIColor.white.withAlphaComponent(0.36)
        titlePlaceholder.layer.cornerRadius = 4
        titlePlaceholder.layer.masksToBounds = true
        contentView.addSubview(titlePlaceholder)

        titlePlaceholder.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(150)
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
        titlePlaceholder.layer.removeAnimation(forKey: "subwayRealtimeSkeletonOpacity")
        titlePlaceholder.layer.add(animation, forKey: "subwayRealtimeSkeletonOpacity")
    }
}

final class SubwayRealtimeSkeletonFooterView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "SubwayRealtimeSkeletonFooterView"

    private let buttonPlaceholder = UIView()

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
        buttonPlaceholder.backgroundColor = .secondarySystemFill
        buttonPlaceholder.layer.cornerRadius = 4
        buttonPlaceholder.layer.masksToBounds = true
        contentView.addSubview(buttonPlaceholder)

        buttonPlaceholder.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(150)
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
        buttonPlaceholder.layer.removeAnimation(forKey: "subwayRealtimeSkeletonOpacity")
        buttonPlaceholder.layer.add(animation, forKey: "subwayRealtimeSkeletonOpacity")
    }
}

final class SubwayRealtimeSkeletonCellView: UITableViewCell {
    static let reuseIdentifier = "SubwayRealtimeSkeletonCellView"

    private let destinationPlaceholder = UIView()
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

        [destinationPlaceholder, timePlaceholder].forEach { view in
            view.backgroundColor = .secondarySystemFill
            view.layer.cornerRadius = 4
            view.layer.masksToBounds = true
            contentView.addSubview(view)
        }

        destinationPlaceholder.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.equalTo(92)
            make.height.equalTo(18)
            make.verticalEdges.equalToSuperview().inset(15)
        }
        timePlaceholder.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.equalTo(122)
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

        [destinationPlaceholder, timePlaceholder].forEach { view in
            view.layer.removeAnimation(forKey: "subwayRealtimeSkeletonOpacity")
            view.layer.add(animation, forKey: "subwayRealtimeSkeletonOpacity")
        }
    }
}
