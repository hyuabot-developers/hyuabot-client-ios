import UIKit

class ShuttleRealtimeSkeletonCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleRealtimeSkeletonCellView"

    private let routePlaceholder = UIView()
    private let timePlaceholder = UIView()
    private let alarmPlaceholder = UIView()

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

        for view in [routePlaceholder, timePlaceholder, alarmPlaceholder] {
            view.backgroundColor = .secondarySystemFill
            view.layer.cornerRadius = 4
            view.layer.masksToBounds = true
            contentView.addSubview(view)
        }

        routePlaceholder.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.equalTo(82)
            make.height.equalTo(18)
            make.verticalEdges.equalToSuperview().inset(15)
        }
        alarmPlaceholder.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        timePlaceholder.snp.makeConstraints { make in
            make.trailing.equalTo(alarmPlaceholder.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
            make.width.equalTo(74)
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

        for view in [routePlaceholder, timePlaceholder, alarmPlaceholder] {
            view.layer.removeAnimation(forKey: "shuttleRealtimeSkeletonOpacity")
            view.layer.add(animation, forKey: "shuttleRealtimeSkeletonOpacity")
        }
    }
}
