//
//  ShuttleRealtimeListHeaderView.swift
//  hyuabot
//

import SnapKit
import UIKit

@MainActor
final class ShuttleRealtimeListHeaderView: UIView {
    let noticeBar = BusNoticeBarView()
    let segmentView = SubwaySegmentView(buttonIdentifierPrefix: "viewpager.tab", columns: 3)
    let stopInfoButton: UIButton = HeaderHitAreaButton(type: .custom)
    var onSelectStop: ((Int) -> Void)?
    var onStopInfoTap: (() -> Void)?
    var onReturnToNearestTap: (() -> Void)?

    private let locationLabel = UILabel()
    private let locationIcon = UIImageView()
    private let locationButton = UIButton(type: .custom)
    private let presencePill = UIView()
    private let presenceDot = UIView()
    private let presenceLabel = UILabel()

    init(stopTitles: [String]) {
        super.init(frame: .zero)
        backgroundColor = SettingsStyle.Color.background

        locationIcon.image = UIImage(
            systemName: "location.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .regular)
        )
        locationIcon.tintColor = SettingsStyle.Color.commuterFaint
        locationIcon.contentMode = .scaleAspectFit
        locationIcon.setContentHuggingPriority(.required, for: .horizontal)
        locationIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        locationLabel.font = SettingsStyle.font(12)
        locationLabel.textColor = SettingsStyle.Color.commuterFaint
        locationLabel.numberOfLines = 1
        locationLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        locationLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        locationLabel.adjustsFontForContentSizeCategory = true
        let locationStack = UIStackView(arrangedSubviews: [locationIcon, locationLabel])
        locationStack.axis = .horizontal
        locationStack.alignment = .center
        locationStack.spacing = 4
        locationStack.isUserInteractionEnabled = false
        locationButton.addTarget(self, action: #selector(returnToNearestTapped), for: .touchUpInside)
        locationButton.accessibilityIdentifier = "shuttle.location.source"
        locationStack.layoutMargins = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        locationStack.isLayoutMarginsRelativeArrangement = true

        configurePresencePill()
        configureStopInfoButton()
        presencePill.setContentHuggingPriority(.required, for: .horizontal)
        presencePill.setContentCompressionResistancePriority(.required, for: .horizontal)
        stopInfoButton.setContentHuggingPriority(.required, for: .horizontal)
        stopInfoButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        let locationContainer = UIView()
        locationContainer.addSubview(locationStack)
        locationContainer.addSubview(locationButton)
        locationStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        locationButton.snp.makeConstraints { $0.edges.equalToSuperview() }
        let locationRow = UIStackView(arrangedSubviews: [locationContainer, presencePill, stopInfoButton])
        locationRow.axis = .horizontal
        locationRow.alignment = .center
        locationRow.spacing = 8
        locationRow.snp.makeConstraints { $0.height.equalTo(36) }

        let stack = UIStackView(arrangedSubviews: [noticeBar, segmentView, locationRow])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        stack.setCustomSpacing(12, after: noticeBar)
        stack.setCustomSpacing(6, after: segmentView)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16)
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        noticeBar.accessibilityIdentifier = "shuttle.notice.bar"
        segmentView.configure(
            items: stopTitles.map { SubwaySegmentView.Item(title: $0, dotColors: [], count: nil) },
            selected: 0
        )
        segmentView.onSelect = { [weak self] index in self?.onSelectStop?(index) }
        stopInfoButton.addTarget(self, action: #selector(stopInfoTapped), for: .touchUpInside)
    }

    @objc
    private func returnToNearestTapped() {
        onReturnToNearestTap?()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelectedStop(_ index: Int) {
        segmentView.setSelected(index)
    }

    func setLocationSource(isManual: Bool) {
        locationLabel.text = String(localized: isManual ? "shuttle.realtime.location.manual" : "shuttle.realtime.location.nearest")
        // The automatic nearest-stop state is tinted blue; a manual choice keeps the quiet gray.
        let tint = isManual ? SettingsStyle.Color.commuterFaint : SettingsStyle.Color.link
        locationLabel.textColor = tint
        locationIcon.tintColor = tint
        locationButton.isEnabled = isManual
        locationButton.accessibilityLabel = isManual ? locationLabel.text : nil
        locationButton.accessibilityTraits = isManual ? .button : []
        locationButton.isAccessibilityElement = isManual
    }

    func setPresence(text: String?, accessibilityLabel: String?, dotColor: UIColor?) {
        guard let text else {
            presencePill.isHidden = true
            return
        }
        presencePill.isHidden = false
        presenceLabel.text = text
        presencePill.accessibilityLabel = accessibilityLabel
        presenceDot.backgroundColor = dotColor
    }

    func setNoticeHidden(_ hidden: Bool) {
        noticeBar.isHidden = hidden
    }

    private func configurePresencePill() {
        presencePill.backgroundColor = SettingsStyle.Color.card
        presencePill.layer.cornerRadius = 12
        presencePill.isAccessibilityElement = true
        presencePill.accessibilityTraits = .staticText
        let content = UIStackView(arrangedSubviews: [presenceDot, presenceLabel])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 6
        content.isUserInteractionEnabled = false
        presencePill.addSubview(content)
        content.setContentCompressionResistancePriority(.required, for: .horizontal)
        content.setContentHuggingPriority(.required, for: .horizontal)
        content.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 10)) }
        presenceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        presenceDot.layer.cornerRadius = 4
        presenceDot.snp.makeConstraints { $0.size.equalTo(8) }
        presenceLabel.font = SettingsStyle.monospacedDigitFont(12)
        presenceLabel.textColor = SettingsStyle.Color.secondaryText
        presenceLabel.adjustsFontForContentSizeCategory = true
        presencePill.snp.makeConstraints { $0.height.equalTo(24) }
        presencePill.isHidden = true
    }

    private func configureStopInfoButton() {
        stopInfoButton.backgroundColor = .clear
        stopInfoButton.snp.makeConstraints { $0.height.equalTo(32) }
        let capsule = UIView()
        capsule.backgroundColor = SettingsStyle.Color.card
        capsule.layer.cornerRadius = 12
        capsule.isUserInteractionEnabled = false
        stopInfoButton.addSubview(capsule)
        capsule.snp.makeConstraints { $0.center.equalToSuperview(); $0.height.equalTo(24); $0.leading.trailing.equalToSuperview() }
        stopInfoButton.accessibilityIdentifier = "shuttle.stop_info"
        stopInfoButton.accessibilityLabel = String(localized: "shuttle.realtime.stop_info")
        let title = UILabel()
        title.text = String(localized: "shuttle.realtime.stop_info")
        title.font = SettingsStyle.font(12, bold: true)
        title.textColor = SettingsStyle.Color.link
        let chevron = UIImageView(image: UIImage(
            systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        ))
        chevron.tintColor = SettingsStyle.Color.link
        let content = UIStackView(arrangedSubviews: [title, chevron])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 4
        content.isUserInteractionEnabled = false
        capsule.addSubview(content)
        content.setContentCompressionResistancePriority(.required, for: .horizontal)
        content.setContentHuggingPriority(.required, for: .horizontal)
        title.setContentCompressionResistancePriority(.required, for: .horizontal)
        content.snp.makeConstraints { $0.center.equalToSuperview(); $0.leading.trailing.equalToSuperview().inset(10) }
        chevron.snp.makeConstraints { $0.size.equalTo(12) }
    }

    @objc
    private func stopInfoTapped() {
        onStopInfoTap?()
    }
}

private final class HeaderHitAreaButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let minimumHitSize: CGFloat = 44
        let verticalInset = max(0, (minimumHitSize - bounds.height) / 2)
        let horizontalInset = max(0, (minimumHitSize - bounds.width) / 2)
        return bounds.insetBy(dx: -horizontalInset, dy: -verticalInset).contains(point)
    }
}
