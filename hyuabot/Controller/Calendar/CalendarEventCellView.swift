import SnapKit
import UIKit

class CalendarEventCellView: UITableViewCell {
    static let reuseIdentifier = "CalendarEventCellView"

    private let stripeView = UIView()
    private let separatorView = UIView()
    private let titleLabel = UILabel().then {
        $0.font = SettingsStyle.font(16, bold: true)
        $0.numberOfLines = 0
        $0.lineBreakMode = .byTruncatingTail
    }
    private let titleRow = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .top
        $0.spacing = 8
    }
    private let rowStack = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 8
    }
    private let badgeContainer = UIView()
    private let statusBadge = UILabel().then {
        $0.font = SettingsStyle.monospacedDigitFont(11, bold: true)
        $0.textAlignment = .center
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    private let metaLabel = UILabel().then {
        $0.font = SettingsStyle.monospacedDigitFont(13)
        $0.textColor = SettingsStyle.Color.secondaryText
        $0.numberOfLines = 0
    }
    private let descLabel = UILabel().then {
        $0.font = SettingsStyle.font(13)
        $0.textColor = SettingsStyle.Color.secondaryText
        $0.numberOfLines = 2
    }
    private let textStack = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 1
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        badgeContainer.layer.cornerRadius = 11
        badgeContainer.clipsToBounds = true
        badgeContainer.addSubview(statusBadge)
        statusBadge.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)) }
        badgeContainer.snp.makeConstraints { $0.height.equalTo(22) }
        badgeContainer.setContentHuggingPriority(.required, for: .vertical)
        titleRow.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(titleRow)
        textStack.addArrangedSubview(metaLabel)
        textStack.addArrangedSubview(descLabel)
        rowStack.addArrangedSubview(textStack)
        rowStack.addArrangedSubview(badgeContainer)
        badgeContainer.setContentCompressionResistancePriority(.required, for: .horizontal)
        badgeContainer.setContentHuggingPriority(.required, for: .horizontal)
        [stripeView, rowStack, separatorView].forEach(contentView.addSubview)
        stripeView.layer.cornerRadius = 2
        separatorView.backgroundColor = SettingsStyle.Color.separator
        stripeView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(10)
            make.width.equalTo(4)
        }
        rowStack.snp.makeConstraints { make in
            make.leading.equalTo(stripeView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(10)
        }
        separatorView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().inset(32)
            make.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    func setupUI(item: Event, showsSeparator: Bool) {
        stripeView.backgroundColor = SettingsStyle.Color.calendarCategoryStrong(item.categoryID)
        stripeView.alpha = item.isPast ? 0.4 : 1
        separatorView.isHidden = !showsSeparator
        titleLabel.text = item.title
        titleLabel.textColor = item.isPast ? SettingsStyle.Color.faint : SettingsStyle.Color.text
        metaLabel.text = CalendarLayoutLogic.metaText(
            categoryName: item.categoryName,
            start: String(item.startDate.prefix(10)),
            end: String(item.endDate.prefix(10)),
            locale: .autoupdatingCurrent
        )
        let description = item.descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        descLabel.text = description
        descLabel.isHidden = description.isEmpty

        if item.isOngoing {
            statusBadge.text = String(localized: "calendar.event.status.ongoing")
            badgeContainer.backgroundColor = SettingsStyle.Color.levelGoodFill
            statusBadge.textColor = SettingsStyle.Color.levelGood
            badgeContainer.isHidden = false
        } else if let days = item.daysUntilStart, days <= 7 {
            statusBadge.text = "D-\(days)"
            badgeContainer.backgroundColor = SettingsStyle.Color.levelMidFill
            statusBadge.textColor = SettingsStyle.Color.levelMid
            badgeContainer.isHidden = false
        } else {
            statusBadge.text = nil
            badgeContainer.isHidden = true
        }
        isAccessibilityElement = true
        accessibilityLabel = [item.title, badgeContainer.isHidden ? nil : statusBadge.text, metaLabel.text,
                              descLabel.isHidden ? nil : descLabel.text]
            .compactMap { $0 }.joined(separator: ", ")
    }

}
