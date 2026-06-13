import UIKit
import SnapKit

class CalendarGridCell: UICollectionViewCell {
    static let reuseIdentifier = "CalendarGridCell"

    private let selectedHighlight = UIView().then {
        $0.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        $0.isHidden = true
    }
    private let topBorder = UIView().then { $0.backgroundColor = .separator }
    private let todayCircle = UIView().then {
        $0.backgroundColor = .hanyangBlue
        $0.layer.cornerRadius = 12
        $0.isHidden = true
    }
    private let dateLabel = UILabel().then {
        $0.font = .godo(size: 13, weight: .regular)
        $0.textAlignment = .center
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.addSubview(selectedHighlight)
        contentView.addSubview(topBorder)
        contentView.addSubview(todayCircle)
        contentView.addSubview(dateLabel)

        selectedHighlight.snp.makeConstraints { $0.edges.equalToSuperview() }
        topBorder.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        todayCircle.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(24)
        }
        dateLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.centerX.equalToSuperview()
            make.height.equalTo(24)
        }
    }

    func configure(date: Foundation.Date, isCurrentMonth: Bool, selected: Bool) {
        let cal = Calendar.current
        let isToday = cal.isDateInToday(date)
        let weekday = cal.component(.weekday, from: date)
        let dimmed = !isCurrentMonth

        dateLabel.text = "\(cal.component(.day, from: date))"
        todayCircle.isHidden = !isToday
        selectedHighlight.isHidden = !selected

        if isToday {
            dateLabel.textColor = .white
        } else if weekday == 1 {
            dateLabel.textColor = UIColor.systemRed.withAlphaComponent(dimmed ? 0.35 : 1.0)
        } else if weekday == 7 {
            dateLabel.textColor = UIColor.systemBlue.withAlphaComponent(dimmed ? 0.35 : 1.0)
        } else {
            dateLabel.textColor = dimmed ? .tertiaryLabel : .label
        }
    }
}
