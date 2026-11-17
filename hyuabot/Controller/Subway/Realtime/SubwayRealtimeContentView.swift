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

    let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    let segmentView = SubwaySegmentView(buttonIdentifierPrefix: "viewpager.tab")
    private let skeletonList = SubwayRealtimeSkeletonListView()
    private let cardsStack = UIStackView()
    private let footnoteContainer = UIView()
    private let footnoteLabel = UILabel()
    private let refreshControl = UIRefreshControl()
    /// Unfolded Duo layout: the second direction's card continues in the right-hand pane.
    let duoColumn = DuoSecondaryColumnView(spacing: 16)
    private let secondCard = SubwaySectionCardView()

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

    func render(tab: SubwayTabType, isLoading: Bool, sections: [SubwaySectionContent], splitSecond: Bool = false) {
        let selected = tab == .line4 ? 0 : tab == .lineSuin ? 1 : 2
        segmentView.configure(items: segmentItems, selected: selected)
        skeletonList.isHidden = !isLoading
        skeletonList.setAnimating(isLoading)
        cardsStack.isHidden = isLoading
        footnoteContainer.isHidden = isLoading
        secondCard.isHidden = isLoading || !splitSecond || sections.count < 2
        if !secondCard.isHidden { secondCard.configure(sections[1]) }
        if !isLoading {
            for (index, card) in cardsStack.arrangedSubviews.enumerated() {
                guard let card = card as? SubwaySectionCardView else { continue }
                if splitSecond, index == 1 {
                    card.isHidden = true
                } else if sections.indices.contains(index) {
                    card.isHidden = false; card.configure(sections[index])
                } else {
                    card.isHidden = true
                }
            }
            footnoteLabel.numberOfLines = tab == .transfer ? 1 : 0
            footnoteLabel.text = String(localized: tab == .transfer ? "subway.realtime.footnote.transfer" : "subway.realtime.footnote")
        }
    }

    /// Aligns the right-hand card with the first card on the left.
    func updateDuoTopInset() {
        guard !cardsStack.isHidden else { return }
        duoColumn.setTopInset(scrollView.adjustedContentInset.top + 8 + cardsStack.frame.minY)
    }

    func endRefreshing() {
        refreshControl.endRefreshing()
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
        scrollView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            // Horizontal safe-area is 0 on phones; in the Duo wide layout it carries the rail / detail pane.
            $0.leading.trailing.equalTo(safeAreaLayoutGuide)
        }
        contentStack.axis = .vertical
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.top.equalTo(scrollView.contentLayoutGuide).offset(8)
            $0.bottom.equalTo(scrollView.contentLayoutGuide).offset(-HYUMetrics.Layout.screenBottom)
            $0.leading.trailing.equalTo(scrollView.frameLayoutGuide).inset(16)
        }
        contentStack.addArrangedSubview(segmentView)
        contentStack.setCustomSpacing(HYUMetrics.Layout.controlToContent, after: segmentView)
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
        secondCard.onTimetableTap = { [weak self] in self?.onTimetableTap?($0) }
        secondCard.isHidden = true
        duoColumn.stack.addArrangedSubview(secondCard)
        contentStack.setCustomSpacing(HYUMetrics.Layout.contentToFootnote, after: cardsStack)
        footnoteLabel.font = SettingsStyle.font(12)
        footnoteLabel.textColor = SettingsStyle.Color.commuterFaint
        footnoteLabel.numberOfLines = 0
        footnoteContainer.addSubview(footnoteLabel)
        footnoteLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)) }
        contentStack.addArrangedSubview(footnoteContainer)
        let fade = CafeteriaBottomFadeView()
        addSubview(fade)
        fade.snp.makeConstraints { $0.bottom.equalToSuperview(); $0.leading.trailing.equalTo(safeAreaLayoutGuide); $0.height.equalTo(120) }
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
