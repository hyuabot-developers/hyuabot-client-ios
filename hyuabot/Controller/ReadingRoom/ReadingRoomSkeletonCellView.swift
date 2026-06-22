import UIKit

final class ReadingRoomSkeletonCellView: UITableViewCell {
    static let reuseIdentifier = "ReadingRoomSkeletonCellView"

    private let namePlaceholder = UIView()
    private let seatPlaceholder = UIView()
    private let alarmPlaceholder = UIView()
    private let progressPlaceholder = UIView()

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

        [namePlaceholder, seatPlaceholder, alarmPlaceholder, progressPlaceholder].forEach { view in
            view.backgroundColor = .secondarySystemFill
            view.layer.cornerRadius = 4
            view.layer.masksToBounds = true
            contentView.addSubview(view)
        }

        namePlaceholder.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(12)
            make.width.equalTo(132)
            make.height.equalTo(18)
        }
        alarmPlaceholder.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalTo(namePlaceholder)
            make.width.height.equalTo(24)
        }
        seatPlaceholder.snp.makeConstraints { make in
            make.trailing.equalTo(alarmPlaceholder.snp.leading).offset(-14)
            make.centerY.equalTo(namePlaceholder)
            make.width.equalTo(64)
            make.height.equalTo(18)
        }
        progressPlaceholder.snp.makeConstraints { make in
            make.top.equalTo(namePlaceholder.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(12)
            make.height.equalTo(4)
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

        [namePlaceholder, seatPlaceholder, alarmPlaceholder, progressPlaceholder].forEach { view in
            view.layer.removeAnimation(forKey: "readingRoomSkeletonOpacity")
            view.layer.add(animation, forKey: "readingRoomSkeletonOpacity")
        }
    }
}
