//
//  SubwayRealtimeContentView.swift
//  hyuabot
//
import SnapKit
import UIKit

final class SubwayRealtimeContentView: UIView, UIScrollViewDelegate {
    var onSelectTab: ((SubwayTabType) -> Void)?
    var onRefresh: (() -> Void)?
    var onTimetableTap: ((SubwayTimetableTarget) -> Void)?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let titleContainer = UIView()
    private let titleLabel = UILabel()
    let segmentView = SubwaySegmentView(buttonIdentifierPrefix: "viewpager.tab")
    private let skeletonList = SubwayRealtimeSkeletonListView()
    private let cardsStack = UIStackView()
    private let footnoteContainer = UIView()
    private let footnoteLabel = UILabel()
    private let compactBar = SubwayCompactBarView(maxTitleWidth: nil)
    private let refreshControl = UIRefreshControl()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = SettingsStyle.Color.background
        accessibilityIdentifier = "subway.root"
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(tab: SubwayTabType, isLoading: Bool, sections: [SubwaySectionContent]) {
        let selected = tab == .line4 ? 0 : tab == .lineSuin ? 1 : 2
        segmentView.configure(items: segmentItems, selected: selected)
        skeletonList.isHidden = !isLoading
        skeletonList.setAnimating(isLoading)
        cardsStack.isHidden = isLoading
        footnoteContainer.isHidden = isLoading
        if !isLoading {
            for (index, card) in cardsStack.arrangedSubviews.enumerated() {
                guard let card = card as? SubwaySectionCardView else { continue }
                if sections.indices.contains(index) {
                    card.isHidden = false; card.configure(sections[index])
                } else {
                    card.isHidden = true
                }
            }
            footnoteLabel.numberOfLines = tab == .transfer ? 1 : 0
            footnoteLabel.text = String(localized: tab == .transfer ? "subway.realtime.footnote.transfer" : "subway.realtime.footnote")
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
        [
            .init(title: String(localized: "subway.tab.blue"), dotColors: [SubwayRouteLine.line4.color], count: nil),
            .init(title: String(localized: "subway.tab.yellow"), dotColors: [SubwayRouteLine.suin.color], count: nil),
            .init(
                title: String(localized: "subway.tab.transfer"),
                dotColors: [SubwayRouteLine.line4.color, SubwayRouteLine.suin.color],
                count: nil
            )
        ]
    }

    private func setupUI() {
        scrollView.alwaysBounceVertical = true
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .automatic
        scrollView.showsVerticalScrollIndicator = false
        scrollView.accessibilityIdentifier = "subway.scroll"
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentStack.axis = .vertical
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.top.equalTo(scrollView.contentLayoutGuide).offset(45)
            $0.bottom.equalTo(scrollView.contentLayoutGuide).offset(-24)
            $0.leading.trailing.equalTo(scrollView.frameLayoutGuide).inset(16)
        }
        titleLabel.attributedText = SettingsStyle.attributedText(
            String(localized: "tabbar.subway"), font: SettingsStyle.font(32, bold: true),
            color: SettingsStyle.Color.text, lineHeight: 40
        ).withKern(-0.5)
        titleLabel.accessibilityTraits = .header
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.accessibilityIdentifier = "subway.title"
        titleContainer.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(4); $0.top.bottom.equalToSuperview() }
        contentStack.addArrangedSubview(titleContainer)
        contentStack.setCustomSpacing(20, after: titleContainer)
        contentStack.addArrangedSubview(segmentView)
        contentStack.setCustomSpacing(16, after: segmentView)
        contentStack.addArrangedSubview(skeletonList)
        contentStack.setCustomSpacing(16, after: skeletonList)
        cardsStack.axis = .vertical
        cardsStack.spacing = 16
        for _ in 0 ..< 2 {
            let card = SubwaySectionCardView()
            card.onTimetableTap = { [weak self] in self?.onTimetableTap?($0) }
            cardsStack.addArrangedSubview(card)
        }
        contentStack.addArrangedSubview(cardsStack)
        contentStack.setCustomSpacing(12, after: cardsStack)
        footnoteLabel.font = SettingsStyle.font(12)
        footnoteLabel.textColor = SettingsStyle.Color.commuterFaint
        footnoteLabel.numberOfLines = 0
        footnoteContainer.addSubview(footnoteLabel)
        footnoteLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)) }
        contentStack.addArrangedSubview(footnoteContainer)
        let fade = CafeteriaBottomFadeView()
        addSubview(fade)
        fade.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(120) }
        compactBar.setTitle(String(localized: "tabbar.subway"))
        addSubview(compactBar)
        compactBar.snp
            .makeConstraints { $0.leading.trailing.top.equalToSuperview(); $0.bottom.equalTo(safeAreaLayoutGuide.snp.top).offset(44) }
        segmentView.configure(items: segmentItems, selected: 0)
        segmentView.onSelect = { [weak self] index in
            guard let self else { return }
            let tab: SubwayTabType = index == 0 ? .line4 : index == 1 ? .lineSuin : .transfer
            onSelectTab?(tab)
        }
    }

    @objc
    private func refresh() {
        onRefresh?()
    }
}
