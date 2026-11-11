//
//  CalendarVC.swift
//  hyuabot
//

// swiftlint:disable file_length

import Api
import RealmSwift
import RxSwift
import SnapKit
import UIKit

// swiftlint:disable:next type_body_length
class CalendarVC: UIViewController, SettingsStyledScreen {
    // MARK: - State

    private let disposeBag = DisposeBag()
    private let isLoading = BehaviorSubject<Bool>(value: false)
    private let eventSubject = BehaviorSubject<[Event]>(value: [])
    private var notificationToken: NotificationToken?

    private var currentMonth: Foundation.Date = {
        let cal = CalendarVC.seoulCalendar
        return cal.date(from: cal.dateComponents([.year, .month], from: Foundation.Date())) ?? Foundation.Date()
    }()

    private var calendarDates: [Foundation.Date] = []
    private var weekLayouts: [CalendarWeekLayout] = []
    private var hiddenCategoryIDs = Set<Int>()
    private let categoryFilterView = CalendarCategoryFilterView()
    private let calendarCardView = UIView()
    private let panelHeaderView = CalendarPanelHeaderView()
    private let eventListCard = UIView()
    private let emptyStateView = CalendarEmptyStateView()
    private let skeletonView = CalendarSkeletonListView()
    private let hintLabel = CalendarHintLabel()
    private let monthEmptyView = UIView()
    private let monthEmptyLabel = UILabel()
    private var filterHeightConstraint: Constraint?
    private var cardTopConstraint: Constraint?
    private var emptyHeightConstraint: Constraint?
    private var emptyTopConstraint: Constraint?
    private var overlayHeightConstraint: Constraint?
    private static var seoulCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }
    private var selectedDate: Foundation.Date?

    private var calendarHeightConstraint: Constraint?
    private var eventViewHeightConstraint: Constraint?
    private var lastEventViewHeight: CGFloat = 0
    private var lastRenderedWidth: CGFloat = 0

    // MARK: - Formatters

    private let dateFormatter = DateFormatter().then {
        $0.dateFormat = "yyyy-MM-dd"
        $0.timeZone = TimeZone(identifier: "Asia/Seoul")
    }

    private let monthLabelFormatter = DateFormatter().then {
        $0.locale = Locale.autoupdatingCurrent
        $0.setLocalizedDateFormatFromTemplate("yMMMM")
        $0.timeZone = TimeZone(identifier: "Asia/Seoul")
    }

    private let selectedDateFormatter = DateFormatter().then {
        $0.locale = Locale.autoupdatingCurrent
        $0.setLocalizedDateFormatFromTemplate("MMMMdEEEE")
        $0.timeZone = TimeZone(identifier: "Asia/Seoul")
    }

    // MARK: - UI

    private lazy var scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
    }

    private let scrollContent = UIView()

    private let monthNavView = UIView()
    private let prevButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "chevron.left", withConfiguration:
            UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)), for: .normal)
        $0.tintColor = SettingsStyle.Color.link
        $0.accessibilityIdentifier = "calendar.previous_month"
        $0.accessibilityLabel = String(localized: "calendar.previous_month.accessibility")
    }

    private let nextButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "chevron.right", withConfiguration:
            UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)), for: .normal)
        $0.tintColor = SettingsStyle.Color.link
        $0.accessibilityIdentifier = "calendar.next_month"
        $0.accessibilityLabel = String(localized: "calendar.next_month.accessibility")
    }

    private let monthLabel = UILabel().then {
        $0.font = SettingsStyle.monospacedDigitFont(17, bold: true)
        $0.textColor = SettingsStyle.Color.text
        $0.textAlignment = .center
    }

    private let weekdayHeaderView = UIStackView().then {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
    }

    private lazy var calendarCollectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeCompositionalLayout())
        cv.isScrollEnabled = false
        cv.backgroundColor = .clear
        cv.register(CalendarGridCell.self, forCellWithReuseIdentifier: CalendarGridCell.reuseIdentifier)
        cv.delegate = self
        cv.dataSource = self
        return cv
    }()

    private let eventOverlayView = CalendarEventOverlayView()

    private lazy var selectedEventView = UITableView().then {
        $0.delegate = self
        $0.dataSource = self
        $0.rowHeight = UITableView.automaticDimension
        $0.estimatedRowHeight = 70
        $0.isScrollEnabled = false
        $0.backgroundColor = .clear
        $0.backgroundView = nil
        $0.separatorStyle = .none
        $0.register(CalendarEventCellView.self, forCellReuseIdentifier: CalendarEventCellView.reuseIdentifier)
    }

    // MARK: - Lifecycle

    deinit { notificationToken?.invalidate() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SettingsStyle.Color.background
        SettingsNavigationStyle.apply(to: self, largeTitle: true)
        setupUI()
        updateCalendarDates()
        #if DEBUG
        if let mode = CalendarDebugFixture.activeMode {
            observeSubjects()
            applyDebugFixture(mode)
            return
        }
        #endif
        updateEventVersion()
        observeSubjects()
        observeDatabase()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.calendar)
        scrollView.layoutIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.showCoachMarksIfNeeded()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        SettingsNavigationStyle.screenWillAppear(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SettingsNavigationStyle.screenWillDisappear(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        syncEventViewHeight()
        let width = calendarCollectionView.bounds.width
        if width > 0, abs(width - lastRenderedWidth) > 0.5 {
            lastRenderedWidth = width
            renderEventBars()
        }
    }

    // MARK: - Layout

    private func makeCompositionalLayout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / 7.0),
            heightDimension: .fractionalHeight(1.0)
        ))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(CalendarGridCell.rowHeight)
            ),
            repeatingSubitem: item, count: 7
        )
        group.interItemSpacing = .fixed(0)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 0
        return UICollectionViewCompositionalLayout(section: section)
    }

    // MARK: - Setup

    private func setupUI() {
        navigationItem.title = String(localized: "tabbar.calendar")
        let pill = CalendarTodayPillView()
        pill.addTarget(self, action: #selector(goToToday), for: .touchUpInside)
        let item = UIBarButtonItem(customView: pill)
        if #available(iOS 26.0, *) { item.hidesSharedBackground = true }
        navigationItem.rightBarButtonItem = item
        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)
        scrollView.addSubview(scrollContent)
        [categoryFilterView, calendarCardView, panelHeaderView, eventListCard, emptyStateView, skeletonView, hintLabel]
            .forEach { scrollContent.addSubview($0) }
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollContent.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        categoryFilterView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview()
            filterHeightConstraint = make.height.equalTo(44).constraint
        }
        calendarCardView.backgroundColor = SettingsStyle.Color.card
        calendarCardView.layer.cornerRadius = HYUMetrics.Radius.card
        calendarCardView.layer.cornerCurve = .continuous
        calendarCardView.snp.makeConstraints { make in
            cardTopConstraint = make.top.equalTo(categoryFilterView.snp.bottom).offset(8).constraint
            make.leading.trailing.equalToSuperview().inset(16)
        }
        setupCard()
        setupPanel()
        panelHeaderView.clearButton.addTarget(self, action: #selector(clearDateSelection), for: .touchUpInside)
        categoryFilterView.onToggle = { [weak self] id in
            guard let self else { return }
            let items = CalendarLayoutLogic.categoryItems(events.map { ($0.categoryID, $0.categoryName) })
            hiddenCategoryIDs = CalendarLayoutLogic.toggledHidden(hiddenCategoryIDs, toggling: id, allIDs: items.map(\.id))
            updateCategories()
            updateCalendarDates()
        }
        prevButton.addTarget(self, action: #selector(didTapPrev), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
    }

    private func setupWeekdays() {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        let weekdays = formatter.veryShortStandaloneWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        for (index, day) in weekdays.enumerated() {
            let label = UILabel()
            label.text = day
            label.font = SettingsStyle.font(12, bold: true)
            label.textColor = index == 0 ? SettingsStyle.Color.danger
                : (index == 6 ? SettingsStyle.Color.saturday : SettingsStyle.Color.secondaryText)
            label.textAlignment = .center
            weekdayHeaderView.addArrangedSubview(label)
        }
    }

    private func setupCard() {
        setupWeekdays()
        [monthNavView, weekdayHeaderView, calendarCollectionView, eventOverlayView, monthEmptyView]
            .forEach { calendarCardView.addSubview($0) }
        [prevButton, monthLabel, nextButton].forEach { monthNavView.addSubview($0) }
        monthNavView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(48)
        }
        prevButton.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        nextButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        monthLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        weekdayHeaderView.snp.makeConstraints { make in
            make.top.equalTo(monthNavView.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(24)
        }
        calendarCollectionView.snp.makeConstraints { make in
            make.top.equalTo(weekdayHeaderView.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(8)
            calendarHeightConstraint = make.height.equalTo(0).constraint
        }
        eventOverlayView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(calendarCollectionView)
            overlayHeightConstraint = make.height.equalTo(0).constraint
        }
        setupMonthEmptyView()
    }

    private func setupMonthEmptyView() {
        monthEmptyView.backgroundColor = SettingsStyle.Color.segmentBackground
        monthEmptyView.layer.cornerRadius = 10
        monthEmptyView.clipsToBounds = true
        monthEmptyView.addSubview(monthEmptyLabel)
        monthEmptyLabel.text = String(localized: "calendar.no.events")
        monthEmptyLabel.font = SettingsStyle.font(13)
        monthEmptyLabel.textColor = SettingsStyle.Color.secondaryText
        monthEmptyLabel.textAlignment = .center
        monthEmptyLabel.numberOfLines = 0
        monthEmptyLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        monthEmptyView.snp.makeConstraints { make in
            emptyTopConstraint = make.top.equalTo(calendarCollectionView.snp.bottom).offset(4).constraint
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().inset(8)
            emptyHeightConstraint = make.height.equalTo(monthEmptyLabel.snp.height).offset(16).constraint
        }
    }

    private func setupPanel() {
        eventListCard.backgroundColor = SettingsStyle.Color.card
        eventListCard.layer.cornerRadius = HYUMetrics.Radius.card
        eventListCard.layer.cornerCurve = .continuous
        eventListCard.clipsToBounds = true
        eventListCard.addSubview(selectedEventView)
        selectedEventView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            eventViewHeightConstraint = make.height.equalTo(0).constraint
        }
        [panelHeaderView, eventListCard, emptyStateView, skeletonView].forEach { $0.isHidden = true }
        panelHeaderView.snp.makeConstraints { make in
            make.top.equalTo(calendarCardView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        [eventListCard, emptyStateView, skeletonView].forEach { item in
            item.snp.makeConstraints { make in
                make.top.equalTo(panelHeaderView.snp.bottom).offset(6)
                make.leading.trailing.equalToSuperview().inset(16)
            }
        }
        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(eventListCard.snp.bottom).offset(HYUMetrics.Layout.contentToFootnote)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(12)
        }
        updatePanelLayout(visibleView: emptyStateView)
    }

    private func updatePanelLayout(visibleView: UIView) {
        hintLabel.snp.remakeConstraints { make in
            make.top.equalTo(visibleView.snp.bottom).offset(HYUMetrics.Layout.contentToFootnote)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(12)
        }
    }

    // MARK: - Calendar grid data

    private func updateCalendarDates() {
        calendarDates = makeCalendarDates(for: currentMonth)
        monthLabel.text = monthLabelFormatter.string(from: currentMonth)
        let rows = max(1, calendarDates.count / 7)
        let totalH = CGFloat(rows) * CalendarGridCell.rowHeight
        calendarHeightConstraint?.update(offset: totalH)
        overlayHeightConstraint?.update(offset: totalH)
        computeLayout()
        calendarCollectionView.reloadData()
        renderEventBars()
        updateSelectedDatePanel()
    }

    private func makeCalendarDates(for month: Foundation.Date) -> [Foundation.Date] {
        let cal = CalendarVC.seoulCalendar
        guard let first = cal.date(from: cal.dateComponents([.year, .month], from: month)) else { return [] }
        let weekday = cal.component(.weekday, from: first) - 1

        var dates: [Foundation.Date] = []
        for offset in stride(from: weekday - 1, through: 0, by: -1) {
            if let date = cal.date(byAdding: .day, value: -(offset + 1), to: first) { dates.append(date) }
        }
        let count = cal.range(of: .day, in: .month, for: first)?.count ?? 0
        for dayOffset in 0 ..< count {
            if let date = cal.date(byAdding: .day, value: dayOffset, to: first) { dates.append(date) }
        }
        let total = ((dates.count + 6) / 7) * 7
        var last = dates.last ?? first
        while dates.count < total {
            last = cal.date(byAdding: .day, value: 1, to: last) ?? last
            dates.append(last)
        }
        return dates
    }

    // MARK: - Event layout

    private var events: [Event] { (try? eventSubject.value()) ?? [] }

    private var filteredEvents: [Event] {
        events.filter { !hiddenCategoryIDs.contains($0.categoryID) }
    }

    private var visibleSpans: [CalendarSpan] {
        filteredEvents.map {
            CalendarSpan(id: $0.id, start: String($0.startDate.prefix(10)),
                         end: String($0.endDate.prefix(10)), categoryID: $0.categoryID)
        }
    }

    private func updateCategories() {
        let items = CalendarLayoutLogic.categoryItems(events.map { ($0.categoryID, $0.categoryName) })
        categoryFilterView.configure(items: items, hidden: hiddenCategoryIDs)
        categoryFilterView.isHidden = items.isEmpty
        filterHeightConstraint?.update(offset: items.isEmpty ? 0 : 44)
        cardTopConstraint?.update(offset: items.isEmpty ? 0 : 8)
    }

    private func computeLayout() {
        let spans = visibleSpans
        let monthKey = String(dateFormatter.string(from: currentMonth).prefix(7))
        let days = calendarDates.map { dateFormatter.string(from: $0) }
        weekLayouts = stride(from: 0, to: days.count, by: 7).map { start in
            CalendarLayoutLogic.weekLayout(weekDays: Array(days[start..<start + 7]), monthKey: monthKey, spans: spans)
        }
        let empty = !CalendarLayoutLogic.monthHasEvents(monthKey: monthKey, spans: spans)
        applyMonthEmptyVisibility(empty: empty, loading: (try? isLoading.value()) == true)
    }

    private func applyMonthEmptyVisibility(empty: Bool, loading: Bool) {
        let visible = empty && !loading
        monthEmptyView.isHidden = !visible
        emptyTopConstraint?.update(offset: visible ? 4 : 0)
        emptyHeightConstraint?.deactivate()
        monthEmptyView.snp.makeConstraints { make in
            if visible {
                emptyHeightConstraint = make.height.equalTo(monthEmptyLabel.snp.height).offset(16).constraint
            } else {
                emptyHeightConstraint = make.height.equalTo(0).constraint
            }
        }
    }

    private func renderEventBars() {
        let titles = Dictionary(events.map { ($0.id, $0.title) }, uniquingKeysWith: { first, _ in first })
        eventOverlayView.render(weeks: weekLayouts, titlesByID: titles, width: calendarCollectionView.bounds.width)
    }

    // MARK: - Selected date panel

    private var visibleEvents: [Event] {
        let today = dateFormatter.string(from: Foundation.Date())
        let ids = CalendarLayoutLogic.panelSpanIDs(spans: visibleSpans,
                                                   selectedDay: selectedDate.map { dateFormatter.string(from: $0) },
                                                   today: today)
        let byID = Dictionary(filteredEvents.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return ids.compactMap { byID[$0] }
    }

    private func updateSelectedDatePanel() {
        guard (try? isLoading.value()) != true else { return }
        let items = visibleEvents
        let title = selectedDate.map { selectedDateFormatter.string(from: $0) } ?? String(localized: "calendar.section.upcoming")
        panelHeaderView.configure(title: title, count: items.isEmpty ? nil : items.count, showsClear: selectedDate != nil)
        let isEmpty = items.isEmpty
        eventListCard.isHidden = isEmpty
        emptyStateView.isHidden = !isEmpty
        if isEmpty {
            let title = selectedDate == nil
                ? String(localized: "calendar.upcoming.empty")
                : String(localized: "calendar.empty.selected.title")
            let caption: String
            if selectedDate != nil {
                caption = String(localized: "calendar.empty.selected.caption")
            } else if hiddenCategoryIDs.isEmpty {
                caption = String(localized: "calendar.empty.upcoming.caption")
            } else {
                caption = String(localized: "calendar.empty.hidden.caption")
            }
            emptyStateView.configure(title: title, caption: caption)
            updatePanelLayout(visibleView: emptyStateView)
        } else {
            selectedEventView.reloadData()
            updateEventViewHeight()
            updatePanelLayout(visibleView: eventListCard)
        }
        panelHeaderView.isHidden = false
    }

    @objc
    private func clearDateSelection() {
        selectedDate = nil
        calendarCollectionView.reloadData()
        updateSelectedDatePanel()
    }

    private func updateEventViewHeight() {
        selectedEventView.layoutIfNeeded()
        eventViewHeightConstraint?.update(offset: selectedEventView.contentSize.height)
        lastEventViewHeight = selectedEventView.contentSize.height
        scrollView.layoutIfNeeded()
    }

    /// Self-sizing rows can settle after the first pass; re-measure so no blank band stays below the list.
    private func syncEventViewHeight() {
        guard !eventListCard.isHidden else { return }
        let height = selectedEventView.contentSize.height
        guard abs(height - lastEventViewHeight) > 0.5 else { return }
        lastEventViewHeight = height
        eventViewHeightConstraint?.update(offset: height)
    }

    // MARK: - Month navigation

    private func animateMonthTransition(direction: CGFloat) {
        let views = [calendarCollectionView, eventOverlayView]
        views.forEach {
            $0.alpha = 0
            $0.transform = CGAffineTransform(translationX: direction * 24, y: 0)
        }
        UIView.animate(withDuration: 0.22, delay: 0, options: .curveEaseOut) {
            views.forEach {
                $0.alpha = 1
                $0.transform = .identity
            }
        }
    }

    @objc
    private func goToToday() {
        let calendar = CalendarVC.seoulCalendar
        guard let month = calendar.date(from: calendar.dateComponents([.year, .month], from: Foundation.Date())) else { return }
        currentMonth = month
        selectedDate = nil
        animateMonthTransition(direction: 0)
        updateCalendarDates()
    }

    @objc
    private func didTapPrev() {
        guard let prev = CalendarVC.seoulCalendar.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        currentMonth = prev
        selectedDate = nil
        animateMonthTransition(direction: -1)
        updateCalendarDates()
    }

    @objc
    private func didTapNext() {
        guard let next = CalendarVC.seoulCalendar.date(byAdding: .month, value: 1, to: currentMonth) else { return }
        currentMonth = next
        selectedDate = nil
        animateMonthTransition(direction: 1)
        updateCalendarDates()
    }

    // MARK: - Data

    private func observeSubjects() {
        eventSubject.subscribe(onNext: { [weak self] _ in
            self?.updateCategories()
            self?.computeLayout()
            self?.calendarCollectionView.reloadData()
            self?.renderEventBars()
            self?.updateSelectedDatePanel()
        }).disposed(by: disposeBag)
        isLoading.subscribe(onNext: { [weak self] loading in
            guard let self else { return }
            if loading {
                applyMonthEmptyVisibility(empty: false, loading: true)
                panelHeaderView.configure(title: String(localized: "calendar.loading"), count: nil, showsClear: false)
                panelHeaderView.isHidden = false
                skeletonView.isHidden = false
                skeletonView.startPulse()
                eventListCard.isHidden = true
                emptyStateView.isHidden = true
                updatePanelLayout(visibleView: skeletonView)
            } else {
                skeletonView.stopPulse()
                skeletonView.isHidden = true
                let monthHasEvents = CalendarLayoutLogic.monthHasEvents(
                    monthKey: String(dateFormatter.string(from: currentMonth).prefix(7)), spans: visibleSpans
                )
                applyMonthEmptyVisibility(empty: !monthHasEvents, loading: false)
                updateSelectedDatePanel()
            }
        }).disposed(by: disposeBag)
    }

    private func observeDatabase() {
        notificationToken = Database.shared.database.objects(Event.self).observe { [weak self] changes in
            switch changes {
            case let .initial(results):
                self?.eventSubject.onNext(Array(results))
            case let .update(_, deletions, insertions, modifications):
                if !deletions.isEmpty || !insertions.isEmpty || !modifications.isEmpty {
                    self?.eventSubject.onNext(Array(Database.shared.database.objects(Event.self)))
                }
            default: break
            }
        }
    }

    #if DEBUG
    private func applyDebugFixture(_ mode: CalendarDebugFixture.Mode) {
        eventSubject.onNext(CalendarDebugFixture.events(mode: mode, today: Date()))
        isLoading.onNext(mode == .loading)
    }
    #endif

    private func updateEventVersion() {
        isLoading.onNext(true)
        Task {
            let response = try? await Network.shared.client.fetch(query: CalendarPageVersionQuery())
            if let data = response?.data {
                let prev = UserDefaults.standard.string(forKey: "calendarVersion") ?? ""
                let isEmpty = Database.shared.database.objects(Event.self).isEmpty
                if data.calendar.version != prev || isEmpty {
                    updateEvent()
                } else {
                    isLoading.onNext(false)
                }
            } else {
                isLoading.onNext(false)
            }
        }
    }

    private func updateEvent() {
        Task {
            let response = try? await Network.shared.client.fetch(query: CalendarPageQuery())
            if let data = response?.data {
                let events = await Event.transformTranslated(from: data.calendar.categories)
                await Event.replaceAll(with: events)
                UserDefaults.standard.set(data.calendar.version, forKey: "calendarVersion")
            }
            isLoading.onNext(false)
        }
    }

    // MARK: - Coach marks

    private func showCoachMarksIfNeeded() {
        presentCoachMarks(pageId: "calendar", items: [
            CoachMarkItem(
                id: "calendar.nav",
                targetView: monthNavView,
                title: String(localized: "coach.calendar.nav.title"),
                message: String(localized: "coach.calendar.nav.message")
            ),
            CoachMarkItem(
                id: "calendar.date",
                targetView: calendarCollectionView,
                title: String(localized: "coach.calendar.calendar.title"),
                message: String(localized: "coach.calendar.calendar.message")
            )
        ])
    }
}

// MARK: - UICollectionView

extension CalendarVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        calendarDates.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CalendarGridCell.reuseIdentifier, for: indexPath
        ) as? CalendarGridCell else { return UICollectionViewCell() }
        let date = calendarDates[indexPath.item]
        let isCurrent = CalendarVC.seoulCalendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
        let isSelected = selectedDate.map { CalendarVC.seoulCalendar.isDate(date, inSameDayAs: $0) } ?? false
        let today = dateFormatter.string(from: date) == dateFormatter.string(from: Foundation.Date())
        cell.configure(CalendarDayConfiguration(
            day: CalendarVC.seoulCalendar.component(.day, from: date), weekdayIndex: indexPath.item % 7,
            isCurrentMonth: isCurrent, isToday: today, isSelected: isSelected,
            showsTopBorder: indexPath.item >= 7, accessibilityText: dayAccessibilityText(at: indexPath.item, isToday: today)
        ))
        return cell
    }

    private func dayAccessibilityText(at index: Int, isToday: Bool) -> String {
        let total = weekLayouts.indices.contains(index / 7) ? weekLayouts[index / 7].totals[index % 7] : 0
        let count = total > 0
            ? String(format: String(localized: "calendar.day.events_count"), total)
            : String(localized: "calendar.day.no_events")
        let today = isToday ? ", " + String(localized: "calendar.today") : ""
        return selectedDateFormatter.string(from: calendarDates[index]) + today + ", " + count
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let date = calendarDates[indexPath.item]
        if let cur = selectedDate, CalendarVC.seoulCalendar.isDate(date, inSameDayAs: cur) {
            selectedDate = nil
        } else {
            selectedDate = date
        }
        collectionView.reloadData()
        updateSelectedDatePanel()
    }
}

// MARK: - UITableView (selected date events)

extension CalendarVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleEvents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CalendarEventCellView.reuseIdentifier
        ) as? CalendarEventCellView else { return UITableViewCell() }
        cell.setupUI(item: visibleEvents[indexPath.row], showsSeparator: indexPath.row > 0)
        return cell
    }

}
