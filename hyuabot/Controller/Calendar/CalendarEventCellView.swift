import UIKit
import SnapKit

class CalendarEventCellView: UITableViewCell {
    static let reuseIdentifier = "CalendarEventCellView"

    private let stripeView = UIView()
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 15, weight: .bold)
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }
    private let statusBadge = UILabel().then {
        $0.font = .godo(size: 11, weight: .bold)
        $0.textColor = .white
        $0.layer.cornerRadius = 4
        $0.clipsToBounds = true
        $0.textAlignment = .center
    }
    private let dateLabel = UILabel().then {
        $0.font = .godo(size: 13, weight: .regular)
        $0.textColor = .secondaryLabel
    }
    private let descLabel = UILabel().then {
        $0.font = .godo(size: 13, weight: .regular)
        $0.textColor = .tertiaryLabel
        $0.numberOfLines = 2
    }

    private static let parseFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return f
    }()
    private static let shortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd"
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return f
    }()
    private static let shortYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yy/MM/dd"
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return f
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    func setupUI() {
        selectionStyle = .none
        contentView.addSubview(stripeView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(statusBadge)
        contentView.addSubview(dateLabel)
        contentView.addSubview(descLabel)

        stripeView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(3)
        }
        statusBadge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(titleLabel)
            make.height.equalTo(20)
            make.width.greaterThanOrEqualTo(44)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.equalTo(stripeView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(statusBadge.snp.leading).offset(-8)
        }
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualTo(statusBadge.snp.leading).offset(-8)
        }
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(2)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(12)
        }
    }

    func setupUI(item: Event) {
        stripeView.backgroundColor = item.categoryColor

        let textColor: UIColor = item.isPast ? .tertiaryLabel : .label
        titleLabel.text = item.title
        titleLabel.textColor = textColor

        dateLabel.text = formattedDate(item)
        dateLabel.textColor = item.isPast ? .tertiaryLabel : .secondaryLabel

        if item.descriptionText.isEmpty {
            descLabel.isHidden = true
            descLabel.text = nil
            descLabel.snp.updateConstraints { make in
                make.top.equalTo(dateLabel.snp.bottom).offset(0)
                make.bottom.equalToSuperview().inset(12)
            }
        } else {
            descLabel.isHidden = false
            descLabel.text = item.descriptionText
            descLabel.snp.updateConstraints { make in
                make.top.equalTo(dateLabel.snp.bottom).offset(2)
                make.bottom.equalToSuperview().inset(12)
            }
        }

        if item.isOngoing {
            statusBadge.isHidden = false
            statusBadge.text = String(localized: "calendar.event.status.ongoing")
            statusBadge.backgroundColor = .systemGreen
        } else if let days = item.daysUntilStart, days <= 7 {
            statusBadge.isHidden = false
            statusBadge.text = "D-\(days)"
            statusBadge.backgroundColor = .systemOrange
        } else {
            statusBadge.isHidden = true
        }
    }

    private func formattedDate(_ item: Event) -> String {
        let startStr = String(item.startDate.prefix(10))
        let endStr = String(item.endDate.prefix(10))
        guard let start = Self.parseFormatter.date(from: startStr),
              let end = Self.parseFormatter.date(from: endStr) else { return startStr }
        if item.isSingleDay {
            return Self.shortFormatter.string(from: start)
        }
        let startYear = Calendar.current.component(.year, from: start)
        let endYear = Calendar.current.component(.year, from: end)
        if startYear != endYear {
            return "\(Self.shortYearFormatter.string(from: start)) - \(Self.shortYearFormatter.string(from: end))"
        }
        return "\(Self.shortFormatter.string(from: start)) - \(Self.shortFormatter.string(from: end))"
    }
}
