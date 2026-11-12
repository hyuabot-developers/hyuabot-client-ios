//
//  ShuttleRealtimeFooterView.swift
//  hyuabot
//

import SnapKit
import Then
import UIKit

private final class ExtendedHitAreaButton: UIButton {
    var minimumHitArea = CGSize(width: 44, height: 44)

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let widthInset = min(0, bounds.width - minimumHitArea.width) / 2
        let heightInset = min(0, bounds.height - minimumHitArea.height) / 2
        return bounds.insetBy(dx: widthInset, dy: heightInset).contains(point)
    }
}

// swiftlint:disable:next type_body_length
class ShuttleRealtimeFooterView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "ShuttleRealtimeFooterView"
    static let timetableButtonHeight: CGFloat = 44
    static let cardGap: CGFloat = 16
    static let connectorSpacing: CGFloat = 8
    private var showEntireTimetable: ((_ stop: ShuttleStopEnum, _ section: Int) -> Void)?
    private var showBusAlternativeStop: ((_ alternative: ShuttleBusAlternativeDisplayData) -> Void)?
    private var stopID: ShuttleStopEnum?
    private var section: Int?
    private var alternatives: [ShuttleBusAlternativeDisplayData] = []
    private weak var transferView: ShuttleTransferInfoView?

    private let transferContainer = UIView()
    let busAlternativeContainer = UIView()
    private let transferConnectorSpacer = UIView()
    private let busAlternativeStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
        $0.alignment = .fill
    }

    let showEntireTimeTableButton = UIButton(type: .system)
    private let cardContainer = UIView()
    private let timetableSeparator = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundView = UIView()
        backgroundView?.backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.clipsToBounds = false
        transferContainer.backgroundColor = .clear
        busAlternativeContainer.backgroundColor = .clear
        busAlternativeContainer.addSubview(busAlternativeStackView)
        busAlternativeStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        showEntireTimeTableButton.snp.makeConstraints { make in
            make.height.equalTo(Self.timetableButtonHeight)
        }
        transferConnectorSpacer.snp.makeConstraints { make in
            make.height.equalTo(Self.connectorSpacing)
        }

        configureTimetableButton()

        cardContainer.backgroundColor = SettingsStyle.Color.card
        cardContainer.layer.cornerRadius = 16
        cardContainer.layer.cornerCurve = .continuous
        cardContainer.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        cardContainer.clipsToBounds = true
        contentView.addSubview(cardContainer)
        cardContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-Self.cardGap)
        }

        timetableSeparator.backgroundColor = SettingsStyle.Color.separator
        cardContainer.addSubview(timetableSeparator)
        timetableSeparator.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        let stackView = UIStackView(arrangedSubviews: [
            busAlternativeContainer,
            transferConnectorSpacer,
            transferContainer,
            showEntireTimeTableButton
        ]).then {
            $0.axis = .vertical
            $0.spacing = 0
            $0.alignment = .fill
        }
        cardContainer.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        showEntireTimeTableButton.addTarget(self, action: #selector(showEntireTimeTable), for: .touchUpInside)
        transferContainer.isHidden = true
        busAlternativeContainer.isHidden = true
        transferConnectorSpacer.isHidden = true
    }

    private func configureTimetableButton() {
        var configuration = UIButton.Configuration.plain()
        var title = AttributedString(String(localized: "shuttle.show.entire.timetable"))
        title.font = SettingsStyle.font(14, bold: true)
        title.foregroundColor = SettingsStyle.Color.link
        configuration.attributedTitle = title
        configuration.image = UIImage(
            systemName: "calendar",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        )
        configuration.imagePlacement = .leading
        configuration.imagePadding = 6
        configuration.contentInsets = .zero
        showEntireTimeTableButton.configuration = configuration
    }

    func setupUI(
        stopID: ShuttleStopEnum,
        section: Int,
        transferView: ShuttleTransferInfoView?,
        busAlternatives: [ShuttleBusAlternativeDisplayData],
        forceShow: Bool = false,
        showEntireTimetable: @escaping (_ stop: ShuttleStopEnum, _ section: Int) -> Void,
        showBusAlternativeStop: @escaping (_ alternative: ShuttleBusAlternativeDisplayData) -> Void
    ) {
        self.stopID = stopID
        self.section = section
        self.showEntireTimetable = showEntireTimetable
        self.showBusAlternativeStop = showBusAlternativeStop
        setTransferView(transferView)

        let alternatives = forceShow && busAlternatives.isEmpty
            ? [ShuttleBusAlternativeDisplayData(
                routeName: String(localized: String
                    .LocalizationValue(stopID == .station ? "shuttle.bus.alternative.route.campus" : "shuttle.bus.alternative.route")),
                minutes: nil,
                color: .busGreen,
                busStopName: "",
                busStopLatitude: 0,
                busStopLongitude: 0
            )]
            : busAlternatives
        let isUnchanged = self.stopID == stopID
            && self.section == section
            && self.alternatives == alternatives
            && busAlternativeContainer.isHidden == alternatives.isEmpty
        if isUnchanged {
            return
        }

        for arrangedSubview in busAlternativeStackView.arrangedSubviews {
            busAlternativeStackView.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }

        self.alternatives = alternatives

        guard !alternatives.isEmpty else {
            busAlternativeContainer.isHidden = true
            return
        }

        for (index, alternative) in alternatives.enumerated() {
            let row = makeAlternativeRow(alternative: alternative, index: index)
            busAlternativeStackView.addArrangedSubview(row)
            row.snp.makeConstraints { make in
                make.height.equalTo(ShuttleRealtimeCellView.informationRowHeight)
            }
        }
        busAlternativeContainer.isHidden = false
    }

    private func setTransferView(_ transferView: ShuttleTransferInfoView?) {
        if self.transferView === transferView, transferView?.superview === transferContainer {
            transferContainer.isHidden = transferView?.preferredHeight == 0
            return
        }
        transferContainer.subviews.forEach { $0.removeFromSuperview() }
        self.transferView = transferView
        guard let transferView, transferView.preferredHeight > 0 else {
            transferContainer.isHidden = true
            return
        }
        transferContainer.addSubview(transferView)
        transferView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        transferContainer.isHidden = false
    }

    private func makeAlternativeTimeLabel(_ alternative: ShuttleBusAlternativeDisplayData) -> UILabel {
        UILabel().then {
            $0.font = SettingsStyle.monospacedDigitFont(17, bold: true)
            $0.textColor = SettingsStyle.Color.text
            $0.textAlignment = .right
            if let minutes = alternative.minutes {
                $0.text = String(format: String(localized: "shuttle.bus.alternative.minutes.%lld"), minutes)
            } else {
                $0.text = String(localized: "shuttle.bus.alternative.no.data")
            }
        }
    }

    private func addAlternativeSeparator(to row: UIView) {
        let separator = UIView()
        separator.backgroundColor = SettingsStyle.Color.separator
        row.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    // swiftlint:disable:next function_body_length
    private func makeAlternativeRow(alternative: ShuttleBusAlternativeDisplayData, index: Int) -> UIView {
        let row = UIView()
        row.backgroundColor = .clear
        let routeBadge = BusRouteBadgeView(size: .shuttle)
        let nameParts = alternative.routeName.components(separatedBy: " (")
        let routeNumber = nameParts.first ?? alternative.routeName
        let direction = nameParts.count > 1 ? nameParts[1].trimmingCharacters(in: CharacterSet(charactersIn: ")")) : nil
        let directionText = direction.map { raw -> String in
            raw.hasSuffix("방면") ? raw : String(
                format: String(localized: "shuttle.bus.alternative.direction.%@"),
                locale: Locale.current,
                raw
            )
        }
        let stopText = alternative.busStopName.isEmpty ? nil : alternative.busStopName
        let titleText = directionText ?? stopText ?? alternative.routeName
        let subtitleText = directionText == nil ? nil : stopText
        routeBadge.configure(text: routeNumber, fill: alternative.color)
        routeBadge.setContentHuggingPriority(.required, for: .horizontal)
        routeBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
        let title = UILabel().then {
            $0.attributedText = SettingsStyle.attributedText(
                titleText,
                font: SettingsStyle.font(15, bold: true),
                color: SettingsStyle.Color.text,
                lineHeight: 20,
                lineBreakMode: .byTruncatingTail
            )
            $0.numberOfLines = 1
        }
        let subtitle = UILabel().then {
            $0.attributedText = SettingsStyle.attributedText(
                subtitleText ?? "",
                font: SettingsStyle.font(12),
                color: SettingsStyle.Color.secondaryText,
                lineHeight: 16,
                lineBreakMode: .byTruncatingTail
            )
            $0.numberOfLines = 1
            $0.isHidden = subtitleText == nil
        }
        let textStack = UIStackView(arrangedSubviews: [title, subtitle]).then {
            $0.axis = .vertical
            $0.spacing = 2
        }
        let time = makeAlternativeTimeLabel(alternative)
        time.setContentHuggingPriority(.required, for: .horizontal)
        time.setContentCompressionResistancePriority(.required, for: .horizontal)
        let infoButton = makeAlternativeInfoButton(alternative: alternative, index: index)

        row.addSubview(routeBadge)
        row.addSubview(textStack)
        row.addSubview(time)
        row.addSubview(infoButton)
        if index > 0 {
            addAlternativeSeparator(to: row)
        }
        setupAlternativeRowConstraints(
            routeBadge: routeBadge,
            textStack: textStack,
            time: time,
            infoButton: infoButton
        )
        return row
    }

    private func makeAlternativeInfoButton(alternative: ShuttleBusAlternativeDisplayData, index: Int) -> UIButton {
        ExtendedHitAreaButton(type: .system).then {
            $0.tag = index
            let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
            $0.setImage(UIImage(systemName: "info.circle", withConfiguration: symbolConfiguration), for: .normal)
            $0.tintColor = alternative.color
            $0.accessibilityLabel = String(localized: "coach.shuttle.footer.title")
            $0.addTarget(self, action: #selector(showAlternativeStop(_:)), for: .touchUpInside)
            let hasStopInfo = alternative.busStopLatitude != 0 && alternative.busStopLongitude != 0
            $0.isEnabled = hasStopInfo
            $0.alpha = hasStopInfo ? 1 : 0.38
        }
    }

    private func setupAlternativeRowConstraints(
        routeBadge: BusRouteBadgeView,
        textStack: UIStackView,
        time: UILabel,
        infoButton: UIButton
    ) {
        routeBadge.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(routeBadge.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(time.snp.leading).offset(-8)
        }
        infoButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        time.snp.makeConstraints { make in
            make.trailing.equalTo(infoButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(textStack.snp.trailing).offset(8)
        }
    }

    @objc
    private func showAlternativeStop(_ sender: UIButton) {
        guard alternatives.indices.contains(sender.tag) else { return }
        showBusAlternativeStop?(alternatives[sender.tag])
    }

    @objc
    func showEntireTimeTable() {
        AnalyticsManager.logSelect(.shuttleShowEntireTimetable)
        guard let stopID, let section else { return }
        showEntireTimetable?(stopID, section)
    }
}
