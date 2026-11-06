import SnapKit
import UIKit

struct CalendarDayConfiguration: Equatable {
    let day: Int
    let weekdayIndex: Int
    let isCurrentMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let showsTopBorder: Bool
    let accessibilityText: String
}

final class CalendarGridCell: UICollectionViewCell {
    static let reuseIdentifier = "CalendarGridCell"
    static let rowHeight: CGFloat = 71

    private let topBorder = UIView()
    private let selectionView = UIView()
    private let numberCircle = UIView()
    private let numberLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        selectionView.backgroundColor = SettingsStyle.Color.accentFill
        selectionView.layer.cornerRadius = 10
        selectionView.layer.cornerCurve = .continuous
        numberCircle.layer.cornerRadius = 13
        numberLabel.textAlignment = .center
        topBorder.backgroundColor = SettingsStyle.Color.separator
        [selectionView, topBorder, numberCircle, numberLabel].forEach(contentView.addSubview)
        selectionView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(3)
            make.leading.trailing.equalToSuperview().inset(1)
            make.height.equalTo(62)
        }
        topBorder.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        numberCircle.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(26)
        }
        numberLabel.snp.makeConstraints { make in
            make.edges.equalTo(numberCircle)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ configuration: CalendarDayConfiguration) {
        numberLabel.text = "\(configuration.day)"
        selectionView.isHidden = !configuration.isSelected
        topBorder.isHidden = !configuration.showsTopBorder
        numberLabel.font = SettingsStyle.monospacedDigitFont(14, bold: configuration.isToday || configuration.isSelected)
        numberCircle.backgroundColor = configuration.isToday ? SettingsStyle.Color.accent : .clear
        if configuration.isToday {
            numberLabel.textColor = SettingsStyle.Color.onAccent
        } else if configuration.weekdayIndex == 0 {
            numberLabel.textColor = SettingsStyle.Color.danger
        } else if configuration.weekdayIndex == 6 {
            numberLabel.textColor = SettingsStyle.Color.saturday
        } else {
            numberLabel.textColor = configuration.isCurrentMonth ? SettingsStyle.Color.text : SettingsStyle.Color.faint
        }
        numberLabel.alpha = !configuration.isCurrentMonth && (configuration.weekdayIndex == 0 || configuration.weekdayIndex == 6) ? 0.5 : 1
        isAccessibilityElement = true
        accessibilityLabel = configuration.accessibilityText
        accessibilityTraits = configuration.isSelected ? [.button, .selected] : .button
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        numberLabel.text = nil
        numberLabel.textColor = SettingsStyle.Color.text
        numberLabel.alpha = 1
        numberLabel.font = SettingsStyle.monospacedDigitFont(14)
        numberCircle.backgroundColor = .clear
        selectionView.isHidden = true
        topBorder.isHidden = true
        isAccessibilityElement = false
        accessibilityLabel = nil
        accessibilityTraits = []
    }
}
