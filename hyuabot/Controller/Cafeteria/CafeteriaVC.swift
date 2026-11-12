//
//  CafeteriaVC.swift
//  hyuabot
//

import Api
import RxSwift
import SnapKit
import UIKit

class CafeteriaVC: UIViewController, SettingsStyledScreen, UIScrollViewDelegate {
    private let disposeBag = DisposeBag()
    private var selectedMeal: CafeteriaMeal = .breakfast
    private var sources: [CafeteriaSource] = []
    private var isLoading = false
    private var lastWeekShift = 0
    private var didApplyInitialMealSelection = false
    private var didReceiveExternalMealSelection = false
    private var today: Foundation.Date {
        #if DEBUG
            return Calendar.current.startOfDay(for: CafeteriaDebugFixture.activeMode == nil ? .now : CafeteriaDebugFixture.now)
        #else
            return Calendar.current.startOfDay(for: .now)
        #endif
    }

    private var now: Foundation.Date {
        #if DEBUG
            return CafeteriaDebugFixture.activeMode == nil ? .now : CafeteriaDebugFixture.now
        #else
            return .now
        #endif
    }

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let headerBar = CafeteriaHeaderBarView()
    private let weekStrip = CafeteriaWeekStripView()
    private let mealSegment = CafeteriaMealSegmentView()
    private let skeletonList = CafeteriaSkeletonListView()
    private let cardsStack = UIStackView()
    private let emptyCard = CafeteriaEmptyCardView()
    private let footnote = UILabel()
    private let footnoteContainer = UIView()
    private let bottomFade = CafeteriaBottomFadeView()
    private let compactBar = UIView()
    private let compactTitle = UILabel()
    private let compactSeparator = UIView()
    private var pendingInfoCoachMark = false
    private var fetchTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindInteractions()
        applyInitialMealSelectionIfNeeded()
        #if DEBUG
            if let mode = CafeteriaDebugFixture.activeMode {
                CafeteriaData.shared.feedDate.onNext(CafeteriaDebugFixture.today)
                isLoading = mode == .loading
                sources = CafeteriaDebugFixture.sources(for: mode)
                CafeteriaData.shared.isLoading.onNext(isLoading)
                render()
            }
        #endif
        observeSubjects()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        tabBarController?.setNeedsStatusBarAppearanceUpdate()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            tabBarController?.setNeedsStatusBarAppearanceUpdate()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.cafeteria)
        showCoachMarksIfNeeded()
    }

    private func setupUI() {
        view.backgroundColor = SettingsStyle.Color.background
        view.accessibilityIdentifier = "cafeteria.root"
        scrollView.accessibilityIdentifier = "cafeteria.scroll"
        scrollView.alwaysBounceVertical = true
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .automatic
        scrollView.showsVerticalScrollIndicator = false
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        cardsStack.axis = .vertical
        cardsStack.spacing = 12
        skeletonList.isHidden = true
        emptyCard.isHidden = true
        footnote.numberOfLines = 0
        footnote.attributedText = SettingsStyle.attributedText(
            String(localized: "cafeteria.footnote"), font: SettingsStyle.font(12),
            color: SettingsStyle.Color.commuterFaint, lineHeight: 16
        )
        footnoteContainer.addSubview(footnote)
        footnote.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)) }
        [headerBar, weekStrip, mealSegment, skeletonList, cardsStack, emptyCard, footnoteContainer].forEach(contentStack.addArrangedSubview)
        contentStack.setCustomSpacing(HYUMetrics.Layout.titleToControl, after: headerBar)
        contentStack.setCustomSpacing(12, after: weekStrip)
        contentStack.setCustomSpacing(HYUMetrics.Layout.controlToContent, after: mealSegment)
        contentStack.setCustomSpacing(12, after: skeletonList)
        contentStack.setCustomSpacing(HYUMetrics.Layout.contentToFootnote, after: cardsStack)
        contentStack.setCustomSpacing(12, after: emptyCard)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        view.addSubview(bottomFade)
        setupCompactBar()
        headerBar.accessory.install(in: view)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(45)
            make.bottom.equalTo(scrollView.contentLayoutGuide).offset(-HYUMetrics.Layout.screenBottom)
            make.leading.trailing.equalTo(scrollView.frameLayoutGuide).inset(16)
        }
        bottomFade.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(120)
        }
    }

    private func setupCompactBar() {
        compactBar.backgroundColor = SettingsStyle.Color.background
        compactBar.alpha = 0
        compactBar.isUserInteractionEnabled = true
        compactTitle.attributedText = SettingsStyle.attributedText(
            String(localized: "tabbar.cafeteria"), font: SettingsStyle.font(17, bold: true),
            color: SettingsStyle.Color.text, lineHeight: 22
        )
        compactTitle.accessibilityElementsHidden = true
        compactSeparator.backgroundColor = SettingsStyle.Color.separator
        view.addSubview(compactBar)
        compactBar.addSubview(compactTitle)
        compactBar.addSubview(compactSeparator)
        compactBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top).offset(44)
        }
        compactTitle.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(11)
        }
        compactSeparator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    private func bindInteractions() {
        headerBar.onMonthTap = { [weak self] in self?.presentDatePicker() }
        headerBar.onTodayTap = { [weak self] in self?.selectToday() }
        headerBar.onShareTap = { [weak self] in self?.share() }
        weekStrip.onSelectDate = { [weak self] date in self?.selectDate(date) }
        weekStrip.onShiftWeek = { [weak self] direction in self?.shiftWeek(direction) }
        mealSegment.onSelect = { [weak self] meal in
            self?.selectedMeal = meal
            self?.render()
        }
    }

    private func observeSubjects() {
        let campusID = UserDefaults.standard.integer(forKey: "campusID") == 0 ? 2 : UserDefaults.standard.integer(forKey: "campusID")
        CafeteriaData.shared.feedDate.subscribe(onNext: { [weak self] feedDate in
            guard let self else { return }
            #if DEBUG
                if CafeteriaDebugFixture.activeMode != nil {
                    render(); return
                }
            #endif
            CafeteriaData.shared.isLoading.onNext(true)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let date = formatter.string(from: feedDate)
            fetchTask?.cancel()
            fetchTask = Task {
                let response = try? await Network.shared.client.fetch(query: CafeteriaPageQuery(date: date, campusID: Int32(campusID)))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.sources = response?.data?.cafeteria.map(CafeteriaSource.init) ?? []
                    CafeteriaData.shared.isLoading.onNext(false)
                    self.isLoading = false
                    self.render()
                }
            }
        }).disposed(by: disposeBag)
        CafeteriaData.shared.isLoading.observe(on: MainScheduler.instance).subscribe(onNext: { [weak self] loading in
            guard let self else { return }
            isLoading = loading
            render()
        }).disposed(by: disposeBag)
    }

    private func render() {
        let selectedDate = (try? CafeteriaData.shared.feedDate.value()) ?? today
        let isToday = Calendar.current.isDate(selectedDate, inSameDayAs: today)
        let cards = CafeteriaDisplayLogic.cards(from: sources, meal: selectedMeal, showsStatus: isToday, now: now)
        let campusID = UserDefaults.standard.integer(forKey: "campusID") == 0 ? 2 : UserDefaults.standard.integer(forKey: "campusID")
        headerBar.configure(
            campusName: String(localized: campusID == 1 ? "campus.seoul" : "campus.erica"),
            monthText: formatted(selectedDate, template: "yMMMM"),
            monthAccessibilityLabel: String(
                format: String(localized: "cafeteria.month.a11y.format"),
                formatted(selectedDate, template: "MMMMdE")
            ),
            showsToday: !isToday,
            shareEnabled: !isLoading && !cards.isEmpty,
            shareAccessibilityLabel: String(
                format: String(localized: "cafeteria.share.a11y.format"),
                formatted(selectedDate, template: "MMMMdE"),
                selectedMeal.title
            )
        )
        let days = CafeteriaDisplayLogic.weekDays(selected: selectedDate, today: today)
        if let first = days.first?.date, let last = days.last?.date {
            weekStrip.configure(
                days: days,
                accessibilityLabel: String(
                    format: String(localized: "cafeteria.week.a11y.format"),
                    formatted(first, template: "MMMMd"),
                    formatted(
                        last,
                        template: "MMMMd"
                    )
                ),
                slideDirection: lastWeekShift
            )
        }
        lastWeekShift = 0
        mealSegment.configure(selected: selectedMeal)
        skeletonList.isHidden = !isLoading
        skeletonList.setAnimating(isLoading)
        cardsStack.isHidden = isLoading || cards.isEmpty
        emptyCard.isHidden = isLoading || !cards.isEmpty
        footnoteContainer.isHidden = isLoading || cards.isEmpty
        cardsStack.arrangedSubviews.forEach { cardsStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        if !isLoading, !cards.isEmpty {
            for card in cards {
                let view = CafeteriaMenuCardView()
                view.configure(card)
                view.onInfoTap = { [weak self] id in self?.openCafeteriaInfoVC(cafeteriaID: id) }
                cardsStack.addArrangedSubview(view)
            }
        } else if !isLoading {
            configureEmpty(date: selectedDate, isToday: isToday)
        }
        presentPendingInfoCoachMarkIfPossible()
    }

    private func configureEmpty(date: Foundation.Date, isToday: Bool) {
        let counts = CafeteriaDisplayLogic.counts(from: sources)
        let state = CafeteriaDisplayLogic.emptyState(selected: selectedMeal, counts: counts) ?? .noMenusForDay
        switch state {
        case .noMenusForDay:
            emptyCard.configure(
                title: String(localized: "cafeteria.empty.day.title"),
                message: String(format: String(localized: "cafeteria.empty.day.message.format"), formatted(date, template: "MMMMdE")),
                actionTitle: String(localized: "cafeteria.empty.day.action")
            )
            emptyCard.onAction = { [weak self] in
                guard let next = Calendar.current.date(byAdding: .day, value: 1, to: date) else { return }
                AnalyticsManager.logSelect(.cafeteriaNextDate, type: .dateControl)
                CafeteriaData.shared.feedDate.onNext(next)
            }
        case let .noMenusForMeal(alternative):
            emptyCard.configure(
                title: String(format: String(localized: "cafeteria.empty.meal.title.format"), selectedMeal.title),
                message: String(format: String(localized: "cafeteria.empty.meal.message.format"), selectedMeal.title),
                actionTitle: String(format: String(localized: "cafeteria.empty.meal.action.format"), alternative.title)
            )
            emptyCard.onAction = { [weak self] in self?.selectedMeal = alternative; self?.render() }
        }
    }

    private func openCafeteriaInfoVC(cafeteriaID: Int) {
        let vc = CafeteriaInfoVC(cafeteriaID: cafeteriaID)
        vc.onOpenMap = { [weak self] in (self?.tabBarController as? RootVC)?.openCampus(.map, animated: true) }
        vc.configureSheetPresentation()
        present(vc, animated: true)
    }

    #if DEBUG
        func presentDebugInfo(cafeteriaID: Int) {
            openCafeteriaInfoVC(cafeteriaID: cafeteriaID)
        }
    #endif

    func scrollToMealTab(_ index: Int, animated: Bool = true) {
        selectedMeal = CafeteriaMeal(rawValue: index) ?? .breakfast
        render()
    }

    func showMeal(date: Foundation.Date, mealIndex: Int) {
        didReceiveExternalMealSelection = true
        didApplyInitialMealSelection = true
        loadViewIfNeeded()
        selectedMeal = CafeteriaMeal(rawValue: mealIndex) ?? .breakfast
        CafeteriaData.shared.feedDate.onNext(date)
    }

    func applyInitialMealSelectionIfNeeded() {
        guard !didApplyInitialMealSelection, !didReceiveExternalMealSelection else { return }
        didApplyInitialMealSelection = true
        let selection = CafeteriaData.automaticMealSelection(at: now)
        selectedMeal = CafeteriaMeal(rawValue: selection.mealIndex) ?? .breakfast
        let current = (try? CafeteriaData.shared.feedDate.value()) ?? selection.date
        if !Calendar.current.isDate(current, inSameDayAs: selection.date) {
            CafeteriaData.shared.feedDate.onNext(selection.date)
        } else {
            render()
        }
    }
}

extension CafeteriaVC {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        headerBar.accessory.update(layoutNow: false)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        compactBar.alpha = min(max((offset - 36) / 16, 0), 1)
        headerBar.accessory.update()
    }

    private func selectDate(_ date: Foundation.Date) {
        AnalyticsManager.logSelect(.cafeteriaDateChanged, type: .dateControl)
        selectedMeal = CafeteriaMeal(rawValue: CafeteriaData.automaticMealSelection(at: now).mealIndex) ?? .breakfast
        CafeteriaData.shared.feedDate.onNext(date)
    }

    private func shiftWeek(_ direction: Int) {
        AnalyticsManager.logSelect(direction < 0 ? .cafeteriaPreviousDate : .cafeteriaNextDate, type: .dateControl)
        let current = (try? CafeteriaData.shared.feedDate.value()) ?? today
        guard let date = Calendar.current.date(byAdding: .day, value: direction * 7, to: current) else { return }
        lastWeekShift = direction
        selectedMeal = CafeteriaMeal(rawValue: CafeteriaData.automaticMealSelection(at: now).mealIndex) ?? .breakfast
        CafeteriaData.shared.feedDate.onNext(date)
    }

    private func selectToday() {
        AnalyticsManager.logSelect(.cafeteriaDateChanged, type: .dateControl)
        let current = (try? CafeteriaData.shared.feedDate.value()) ?? today
        if !Calendar.current.isDate(current, equalTo: today, toGranularity: .weekOfYear) {
            lastWeekShift = current > today ? -1 : 1
        }
        selectedMeal = CafeteriaMeal(rawValue: CafeteriaData.automaticMealSelection(at: now).mealIndex) ?? .breakfast
        CafeteriaData.shared.feedDate.onNext(today)
    }

    private func presentDatePicker() {
        let date = (try? CafeteriaData.shared.feedDate.value()) ?? today
        let picker = CafeteriaDatePickerVC(selectedDate: date) { [weak self] date in
            guard let self else { return }
            AnalyticsManager.logSelect(.cafeteriaDateChanged, type: .dateControl)
            selectedMeal = CafeteriaMeal(rawValue: CafeteriaData.automaticMealSelection(at: now).mealIndex) ?? .breakfast
            CafeteriaData.shared.feedDate.onNext(date)
        }
        present(picker, animated: true)
    }

    private func share() {
        guard let date = try? CafeteriaData.shared.feedDate.value(), let text = CafeteriaDisplayLogic.shareText(
            sources: sources,
            meal: selectedMeal,
            date: date
        ) else { return }
        AnalyticsManager.logSelect(.cafeteriaShareButton, type: .button)
        let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = headerBar.shareButton
        present(activity, animated: true)
    }

    private func formatted(_ date: Foundation.Date, template: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: .current)
        return formatter.string(from: date)
    }

    private func showCoachMarksIfNeeded() {
        #if DEBUG
            guard CafeteriaDebugFixture.activeMode == nil else { return }
        #endif
        guard CoachMarkManager.shared.shouldShowPage("cafeteria") else { return }
        presentCoachMarks(pageId: "cafeteria", items: [
            CoachMarkItem(
                id: "cafeteria.date",
                targetView: weekStrip,
                title: String(localized: "coach.cafeteria.date.title"),
                message: String(localized: "coach.cafeteria.date.message")
            ),
            CoachMarkItem(
                id: "cafeteria.tabs",
                targetView: mealSegment,
                title: String(localized: "coach.cafeteria.tabs.title"),
                message: String(localized: "coach.cafeteria.tabs.message")
            )
        ], shouldMarkAsShown: false) { [weak self] in self?.showInfoCoachMarkWhenReady() }
    }

    private func showInfoCoachMarkWhenReady() {
        #if DEBUG
            guard CafeteriaDebugFixture.activeMode == nil else { return }
        #endif
        pendingInfoCoachMark = true
        presentPendingInfoCoachMarkIfPossible()
    }

    func presentPendingInfoCoachMarkIfPossible() {
        guard pendingInfoCoachMark, view.window != nil, !cardsStack.isHidden,
              let card = cardsStack.arrangedSubviews.first as? CafeteriaMenuCardView else { return }
        pendingInfoCoachMark = false
        presentCoachMarks(
            pageId: "cafeteria",
            items: [CoachMarkItem(
                id: "cafeteria.header.info",
                targetViewProvider: { card.infoButton },
                title: String(localized: "coach.cafeteria.header.info.title"),
                message: String(localized: "coach.cafeteria.header.info.message")
            )],
            shouldMarkAsShown: false
        ) {
            CoachMarkManager.shared.markPageShown("cafeteria")
        }
    }
}
