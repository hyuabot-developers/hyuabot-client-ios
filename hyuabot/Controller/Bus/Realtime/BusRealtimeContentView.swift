//
//  BusRealtimeContentView.swift
//  hyuabot
//
import SnapKit
import Then
import UIKit

final class BusRealtimeContentView: UIView, UIScrollViewDelegate {
    var onSelectTab: ((BusRealtimeType) -> Void)?
    var onRefresh: (() -> Void)?
    var onSettingsTap: (() -> Void)?
    var onStopInfoTap: ((BusRealtimeSectionSpec) -> Void)?
    var onTimetableTap: ((BusRealtimeSectionSpec) -> Void)?
    var onLogTap: ((BusRealtimeSectionSpec) -> Void)?

    let segmentView = SubwaySegmentView(buttonIdentifierPrefix: "viewpager.tab")
    let noticeBar = BusNoticeBarView()
    let settingsButton = UIButton(type: .system)

    private let titleContainer = UIView()
    private let titleLabel = UILabel()
    private let compactBar = SubwayCompactBarView(maxTitleWidth: nil)
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let cardsStack = UIStackView()
    private let footnoteContainer = UIView()
    private let footnoteLabel = UILabel()
    private let refreshControl = UIRefreshControl()

    var firstCard: BusSectionCardView? { cardsStack.arrangedSubviews.first as? BusSectionCardView }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = SettingsStyle.Color.background
        setupScrollView()
        setupTitleRow()
        setupContent()
        setupFade()
        setupCompactBar()
        segmentView.onSelect = { [weak self] index in
            let tab: BusRealtimeType = [.city, .seoul, .suwon, .other][index]
            self?.onSelectTab?(tab)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(tab: BusRealtimeType, specs: [BusRealtimeSectionSpec], contents: [BusSectionContent]) {
        let selected: Int
        switch tab {
        case .city: selected = 0
        case .seoul: selected = 1
        case .suwon: selected = 2
        case .other: selected = 3
        }
        segmentView.configure(items: segmentItems, selected: selected)
        cardsStack.arrangedSubviews.forEach { view in
            cardsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        for (spec, content) in zip(specs, contents) {
            let card = BusSectionCardView()
            card.configure(content)
            card.onStopInfoTap = { [weak self] in self?.onStopInfoTap?(spec) }
            card.onTimetableTap = { [weak self] in self?.onTimetableTap?(spec) }
            card.onLogTap = { [weak self] in self?.onLogTap?(spec) }
            cardsStack.addArrangedSubview(card)
        }
    }

    func endRefreshing() {
        refreshControl.endRefreshing()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        compactBar.setRevealProgress(SubwayCompactBarView.revealProgress(
            contentOffsetY: scrollView.contentOffset.y,
            adjustedTopInset: scrollView.adjustedContentInset.top
        ))
    }

    private var segmentItems: [SubwaySegmentView.Item] {
        ["bus.tab.city", "bus.tab.seoul", "bus.tab.suwon", "bus.tab.other"].map {
            .init(title: String(localized: $0), dotColors: [], count: nil)
        }
    }

    private func setupTitleRow() {
        titleLabel.attributedText = SettingsStyle.attributedText(
            String(localized: "tabbar.bus"), font: SettingsStyle.font(32, bold: true),
            color: SettingsStyle.Color.text, lineHeight: 40
        ).withKern(-0.5)
        titleLabel.accessibilityTraits = .header
        titleLabel.accessibilityIdentifier = "bus.title"
        titleLabel.adjustsFontForContentSizeCategory = true
        titleContainer.addSubview(titleLabel)
        setupSettingsPill()
        settingsButton.accessibilityLabel = String(localized: "bus.quick_settings.title")
        settingsButton.accessibilityIdentifier = "bus.settings"
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        titleContainer.addSubview(settingsButton)
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(4)
            $0.trailing.equalTo(settingsButton.snp.leading).offset(-12)
            $0.centerY.equalTo(settingsButton)
        }
        settingsButton.snp.makeConstraints {
            $0.trailing.top.bottom.equalToSuperview()
            $0.height.equalTo(44)
        }
        contentStack.addArrangedSubview(titleContainer)
        contentStack.setCustomSpacing(16, after: titleContainer)
    }

    private func setupSettingsPill() {
        let capsule = UIView()
        capsule.backgroundColor = SettingsStyle.Color.accentFill
        capsule.layer.cornerRadius = 18
        capsule.isUserInteractionEnabled = false
        settingsButton.addSubview(capsule)
        capsule.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.height.equalTo(36)
            $0.leading.trailing.equalToSuperview()
        }
        let icon = UIImageView(image: UIImage(
            systemName: "slider.horizontal.3",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        ))
        icon.tintColor = SettingsStyle.Color.link
        let label = UILabel()
        label.text = String(localized: "bus.quick_settings.title")
        label.font = SettingsStyle.font(14, bold: true)
        label.textColor = SettingsStyle.Color.link
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 6
        capsule.addSubview(stack)
        stack.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(12)
        }
        icon.snp.makeConstraints { $0.size.equalTo(18) }
    }

    private func setupScrollView() {
        scrollView.alwaysBounceVertical = true
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.accessibilityIdentifier = "bus.scroll"
        scrollView.contentInsetAdjustmentBehavior = .automatic
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentStack.axis = .vertical
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.top.equalTo(scrollView.contentLayoutGuide).offset(45)
            $0.bottom.equalTo(scrollView.contentLayoutGuide).offset(-28)
            $0.leading.trailing.equalTo(scrollView.frameLayoutGuide).inset(16)
        }
    }

    private func setupContent() {
        contentStack.addArrangedSubview(segmentView)
        contentStack.setCustomSpacing(12, after: segmentView)
        contentStack.addArrangedSubview(noticeBar)
        contentStack.setCustomSpacing(16, after: noticeBar)
        cardsStack.axis = .vertical
        cardsStack.spacing = 16
        contentStack.addArrangedSubview(cardsStack)
        contentStack.setCustomSpacing(8, after: cardsStack)
        footnoteLabel.attributedText = SettingsStyle.attributedText(
            String(localized: "bus.realtime.footnote"), font: SettingsStyle.font(12),
            color: SettingsStyle.Color.commuterFaint, lineHeight: 16,
            lineBreakMode: .byTruncatingTail
        )
        footnoteLabel.accessibilityIdentifier = "bus.realtime.footnote"
        footnoteLabel.numberOfLines = 1
        footnoteLabel.adjustsFontForContentSizeCategory = true
        footnoteContainer.addSubview(footnoteLabel)
        footnoteLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)) }
        contentStack.addArrangedSubview(footnoteContainer)
        segmentView.configure(items: segmentItems, selected: 0)
    }

    private func setupFade() {
        let fade = CafeteriaBottomFadeView()
        fade.isUserInteractionEnabled = false
        addSubview(fade)
        fade.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(120) }
    }

    private func setupCompactBar() {
        compactBar.setTitle(String(localized: "tabbar.bus"))
        compactBar.accessibilityIdentifier = "bus.compactBar"
        addSubview(compactBar)
        compactBar.snp.makeConstraints {
            $0.leading.trailing.top.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide.snp.top).offset(44)
        }
    }

    @objc
    private func refresh() {
        onRefresh?()
    }

    @objc
    private func settingsTapped() {
        onSettingsTap?()
    }
}
