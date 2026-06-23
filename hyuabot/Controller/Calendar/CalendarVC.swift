import UIKit
import SnapKit
import RxSwift
import RealmSwift
import Api

class CalendarVC: UIViewController {

    // MARK: - Private types

    private struct EventSegment {
        let event: Event
        let row: Int
        let startCol: Int
        let endCol: Int
        let roundLeft: Bool   // event actually starts here (not continuing from prev row)
        let roundRight: Bool  // event actually ends here (not continuing to next row)
        let slot: Int
        let dimmed: Bool
    }

    // MARK: - State

    private let disposeBag = DisposeBag()
    private let isLoading = BehaviorSubject<Bool>(value: false)
    private let eventSubject = BehaviorSubject<[Event]>(value: [])
    private var notificationToken: NotificationToken?

    private var currentMonth: Foundation.Date = {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: Foundation.Date())) ?? Foundation.Date()
    }()
    private var calendarDates: [Foundation.Date] = []
    private var eventSegments: [EventSegment] = []
    private var selectedDate: Foundation.Date?
    private var currentCellHeight: CGFloat = 80

    private var calendarHeightConstraint: Constraint?
    private var overlayHeightConstraint: Constraint?
    private var eventViewHeightConstraint: Constraint?
    private var lastRenderedWidth: CGFloat = 0

    // MARK: - Formatters

    private let dateFormatter = DateFormatter().then {
        $0.dateFormat = "yyyy-MM-dd"
        $0.timeZone = TimeZone(identifier: "Asia/Seoul")
    }
    private let monthLabelFormatter = DateFormatter().then {
        $0.dateFormat = "yyyy년 M월"
        $0.locale = Locale(identifier: "ko_KR")
        $0.timeZone = TimeZone(identifier: "Asia/Seoul")
    }
    private let selectedDateFormatter = DateFormatter().then {
        $0.dateFormat = "yyyy년 M월 d일 (E)"
        $0.locale = Locale(identifier: "ko_KR")
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
        $0.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        $0.tintColor = .label
    }
    private let nextButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        $0.tintColor = .label
    }
    private let monthLabel = UILabel().then {
        $0.font = .godo(size: 17, weight: .bold)
        $0.textAlignment = .center
    }
    private let weekdayHeaderView = UIStackView().then {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
    }
    private lazy var calendarCollectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeCompositionalLayout())
        cv.isScrollEnabled = false
        cv.backgroundColor = .systemBackground
        cv.register(CalendarGridCell.self, forCellWithReuseIdentifier: CalendarGridCell.reuseIdentifier)
        cv.delegate = self
        cv.dataSource = self
        return cv
    }()
    // Overlay sits on top of collection view; bars are drawn here as frame-based views
    private let eventOverlayView = UIView().then {
        $0.backgroundColor = .clear
        $0.isUserInteractionEnabled = false
    }
    private let panelDivider = UIView().then { $0.backgroundColor = .separator }
    private let selectedDateLabel = UILabel().then {
        $0.font = .godo(size: 15, weight: .bold)
        $0.textColor = .label
        $0.isHidden = true
    }
    private let noEventsLabel = UILabel().then {
        $0.font = .godo(size: 14, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }
    private lazy var selectedEventView = UITableView().then {
        $0.delegate = self
        $0.dataSource = self
        $0.rowHeight = UITableView.automaticDimension
        $0.estimatedRowHeight = 70
        $0.isScrollEnabled = false
        $0.separatorStyle = .none
        $0.register(CalendarEventCellView.self, forCellReuseIdentifier: CalendarEventCellView.reuseIdentifier)
    }
    private let loadingSpinner = UIActivityIndicatorView().then {
        $0.style = .large; $0.color = .label
    }
    private let loadingLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular); $0.textColor = .label
    }
    private lazy var loadingStackView = UIStackView(arrangedSubviews: [loadingSpinner, loadingLabel]).then {
        $0.axis = .vertical; $0.spacing = 10; $0.alignment = .center
        $0.backgroundColor = .systemBackground
    }
    private lazy var loadingView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.addSubview(loadingStackView)
        loadingStackView.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    // MARK: - Lifecycle

    deinit { notificationToken?.invalidate() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateCalendarDates()
        updateEventVersion()
        observeSubjects()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.calendar)
        scrollView.layoutIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.showCoachMarksIfNeeded()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let w = view.bounds.width
        guard w > 0 else { return }
        let newHeight = max(72, w / 7 * 1.25)
        if abs(currentCellHeight - newHeight) > 0.5 {
            currentCellHeight = newHeight
            calendarCollectionView.setCollectionViewLayout(makeCompositionalLayout(), animated: false)
            let rows = max(1, calendarDates.count / 7)
            let totalH = CGFloat(rows) * currentCellHeight
            calendarHeightConstraint?.update(offset: totalH)
            overlayHeightConstraint?.update(offset: totalH)
        }
        if abs(w - lastRenderedWidth) > 0.5 {
            lastRenderedWidth = w
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
                heightDimension: .absolute(currentCellHeight)
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
        view.backgroundColor = .systemBackground
        navigationItem.title = String(localized: "tabbar.calendar")

        let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
        let wdColors: [UIColor] = [.systemRed, .label, .label, .label, .label, .label, .systemBlue]
        for (i, day) in weekdays.enumerated() {
            weekdayHeaderView.addArrangedSubview(UILabel().then {
                $0.text = day
                $0.font = .godo(size: 12, weight: .regular)
                $0.textColor = wdColors[i]
                $0.textAlignment = .center
            })
        }

        view.addSubview(scrollView)
        view.addSubview(loadingView)
        scrollView.addSubview(scrollContent)

        scrollContent.addSubview(monthNavView)
        monthNavView.addSubview(prevButton)
        monthNavView.addSubview(monthLabel)
        monthNavView.addSubview(nextButton)
        scrollContent.addSubview(weekdayHeaderView)
        scrollContent.addSubview(calendarCollectionView)
        scrollContent.addSubview(eventOverlayView)   // sibling of collection view, on top
        scrollContent.addSubview(panelDivider)
        scrollContent.addSubview(selectedDateLabel)
        scrollContent.addSubview(noEventsLabel)
        scrollContent.addSubview(selectedEventView)

        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        loadingView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        monthNavView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        prevButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        nextButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        monthLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        weekdayHeaderView.snp.makeConstraints { make in
            make.top.equalTo(monthNavView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(28)
        }
        calendarCollectionView.snp.makeConstraints { make in
            make.top.equalTo(weekdayHeaderView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            calendarHeightConstraint = make.height.equalTo(480).constraint
        }
        // Overlay exactly covers the calendar grid
        eventOverlayView.snp.makeConstraints { make in
            make.top.equalTo(weekdayHeaderView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            overlayHeightConstraint = make.height.equalTo(480).constraint
        }
        panelDivider.snp.makeConstraints { make in
            make.top.equalTo(calendarCollectionView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        selectedDateLabel.snp.makeConstraints { make in
            make.top.equalTo(panelDivider.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        noEventsLabel.snp.makeConstraints { make in
            make.top.equalTo(selectedDateLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        selectedEventView.snp.makeConstraints { make in
            make.top.equalTo(selectedDateLabel.snp.bottom)
            make.leading.trailing.equalToSuperview()
            eventViewHeightConstraint = make.height.equalTo(0).constraint
            make.bottom.equalToSuperview().inset(20)
        }

        prevButton.addTarget(self, action: #selector(didTapPrev), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
        noEventsLabel.text = String(localized: "calendar.select.hint")
    }

    // MARK: - Calendar grid data

    private func updateCalendarDates() {
        calendarDates = makeCalendarDates(for: currentMonth)
        monthLabel.text = monthLabelFormatter.string(from: currentMonth)
        let rows = max(1, calendarDates.count / 7)
        let totalH = CGFloat(rows) * currentCellHeight
        calendarHeightConstraint?.update(offset: totalH)
        overlayHeightConstraint?.update(offset: totalH)
        computeLayout()
        calendarCollectionView.reloadData()
        renderEventBars()
        updateSelectedDatePanel()
    }

    private func makeCalendarDates(for month: Foundation.Date) -> [Foundation.Date] {
        let cal = Calendar.current
        guard let first = cal.date(from: cal.dateComponents([.year, .month], from: month)) else { return [] }
        let weekday = cal.component(.weekday, from: first) - 1

        var dates: [Foundation.Date] = []
        for i in stride(from: weekday - 1, through: 0, by: -1) {
            if let d = cal.date(byAdding: .day, value: -(i + 1), to: first) { dates.append(d) }
        }
        let count = cal.range(of: .day, in: .month, for: first)?.count ?? 0
        for i in 0..<count {
            if let d = cal.date(byAdding: .day, value: i, to: first) { dates.append(d) }
        }
        let total = ((dates.count + 6) / 7) * 7
        var last = dates.last ?? first
        while dates.count < total {
            last = cal.date(byAdding: .day, value: 1, to: last) ?? last
            dates.append(last)
        }
        return dates
    }

    // MARK: - Event layout computation (per-row segments)

    private func computeLayout() {
        guard let allEvents = try? eventSubject.value() else { return }
        var segments: [EventSegment] = []
        let numRows = calendarDates.count / 7

        for row in 0..<numRows {
            let startIdx = row * 7
            let weekDates = Array(calendarDates[startIdx..<min(startIdx + 7, calendarDates.count)])
            guard !weekDates.isEmpty else { continue }

            let weekStartStr = dateFormatter.string(from: weekDates.first!)
            let weekEndStr   = dateFormatter.string(from: weekDates.last!)

            let rowEvents = allEvents.filter {
                String($0.endDate.prefix(10))   >= weekStartStr &&
                String($0.startDate.prefix(10)) <= weekEndStr
            }.sorted { lhs, rhs in
                lhs.startDate != rhs.startDate
                    ? lhs.startDate < rhs.startDate
                    : lhs.endDate > rhs.endDate     // longer events get lower slots
            }

            var slotOccupancy: [Int: Set<Int>] = [:]

            for event in rowEvents {
                let evStart = String(event.startDate.prefix(10))
                let evEnd   = String(event.endDate.prefix(10))

                var cols = Set<Int>()
                for col in 0..<weekDates.count {
                    let dayStr = dateFormatter.string(from: weekDates[col])
                    if evStart <= dayStr && evEnd >= dayStr { cols.insert(col) }
                }
                guard !cols.isEmpty else { continue }

                var slot = 0
                while let occ = slotOccupancy[slot], !occ.isDisjoint(with: cols) { slot += 1 }
                slotOccupancy[slot] = (slotOccupancy[slot] ?? []).union(cols)

                let sc = cols.min()!, ec = cols.max()!
                let isCurrent = Calendar.current.isDate(
                    weekDates[sc], equalTo: currentMonth, toGranularity: .month)

                segments.append(EventSegment(
                    event: event,
                    row: row,
                    startCol: sc,
                    endCol: ec,
                    roundLeft:  evStart == dateFormatter.string(from: weekDates[sc]),
                    roundRight: evEnd   == dateFormatter.string(from: weekDates[ec]),
                    slot: slot,
                    dimmed: !isCurrent
                ))
            }
        }
        eventSegments = segments
    }

    // MARK: - Overlay rendering

    private static let maxSlot: Int = 2
    private static let barH: CGFloat = 14
    private static let barSpacing: CGFloat = 1
    private static let dateAreaH: CGFloat = 30  // top of cell to where bars start

    private func renderEventBars() {
        eventOverlayView.subviews.forEach { $0.removeFromSuperview() }
        guard view.bounds.width > 0 else { return }
        let colW = view.bounds.width / 7

        for seg in eventSegments where seg.slot < Self.maxSlot {
            let leftInset: CGFloat  = seg.roundLeft  ? 3 : 0
            let rightInset: CGFloat = seg.roundRight ? 3 : 0
            let x = CGFloat(seg.startCol) * colW + leftInset
            let y = CGFloat(seg.row) * currentCellHeight
                  + Self.dateAreaH
                  + CGFloat(seg.slot) * (Self.barH + Self.barSpacing)
            let w = max(0, CGFloat(seg.endCol - seg.startCol + 1) * colW - leftInset - rightInset)

            let bar = UIView()
            bar.frame = CGRect(x: x, y: y, width: w, height: Self.barH)
            bar.backgroundColor = seg.event.categoryColor.withAlphaComponent(seg.dimmed ? 0.4 : 1.0)
            bar.clipsToBounds = true

            var corners: CACornerMask = []
            if seg.roundLeft  { corners.formUnion([.layerMinXMinYCorner, .layerMinXMaxYCorner]) }
            if seg.roundRight { corners.formUnion([.layerMaxXMinYCorner, .layerMaxXMaxYCorner]) }
            bar.layer.cornerRadius = (seg.roundLeft || seg.roundRight) ? 3 : 0
            bar.layer.maskedCorners = corners

            let lbl = UILabel()
            let textX: CGFloat = seg.roundLeft ? 3 : 1
            lbl.frame = CGRect(x: textX, y: 1, width: max(0, w - textX - 3), height: Self.barH - 2)
            lbl.text = seg.event.title
            lbl.font = .godo(size: 9, weight: .regular)
            lbl.textColor = .white
            lbl.numberOfLines = 1
            lbl.lineBreakMode = .byTruncatingTail
            bar.addSubview(lbl)

            eventOverlayView.addSubview(bar)
        }
    }

    // MARK: - Selected date panel

    private var selectedEvents: [Event] {
        guard let date = selectedDate, let all = try? eventSubject.value() else { return [] }
        let str = dateFormatter.string(from: date)
        return all
            .filter { String($0.startDate.prefix(10)) <= str && String($0.endDate.prefix(10)) >= str }
            .sorted { $0.startDate < $1.startDate }
    }

    private func updateSelectedDatePanel() {
        if let date = selectedDate {
            selectedDateLabel.text = selectedDateFormatter.string(from: date)
            selectedDateLabel.isHidden = false
            let events = selectedEvents
            noEventsLabel.text = String(localized: "calendar.no.events")
            noEventsLabel.isHidden = !events.isEmpty
            selectedEventView.reloadData()
            updateEventViewHeight()
        } else {
            selectedDateLabel.isHidden = true
            noEventsLabel.text = String(localized: "calendar.select.hint")
            noEventsLabel.isHidden = false
            eventViewHeightConstraint?.update(offset: 0)
        }
    }

    private func updateEventViewHeight() {
        selectedEventView.layoutIfNeeded()
        eventViewHeightConstraint?.update(offset: selectedEventView.contentSize.height)
        scrollView.layoutIfNeeded()
    }

    // MARK: - Month navigation

    private func animateMonthTransition(forward: Bool) {
        let t = CATransition()
        t.type = .push
        t.subtype = forward ? .fromRight : .fromLeft
        t.duration = 0.28
        t.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        calendarCollectionView.layer.add(t, forKey: nil)
        eventOverlayView.layer.add(t, forKey: nil)
    }

    @objc private func didTapPrev() {
        guard let prev = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        currentMonth = prev
        selectedDate = nil
        animateMonthTransition(forward: false)
        updateCalendarDates()
    }

    @objc private func didTapNext() {
        guard let next = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) else { return }
        currentMonth = next
        selectedDate = nil
        animateMonthTransition(forward: true)
        updateCalendarDates()
    }

    // MARK: - Data

    private func observeSubjects() {
        notificationToken = Database.shared.database.objects(Event.self).observe { [weak self] changes in
            switch changes {
            case .initial(let results):
                self?.eventSubject.onNext(results.map { $0 })
            case .update(_, let deletions, let insertions, let modifications):
                if !deletions.isEmpty || !insertions.isEmpty || !modifications.isEmpty {
                    self?.eventSubject.onNext(Database.shared.database.objects(Event.self).map { $0 })
                }
            default: break
            }
        }
        eventSubject.subscribe(onNext: { [weak self] _ in
            self?.computeLayout()
            self?.calendarCollectionView.reloadData()
            self?.renderEventBars()
            self?.updateSelectedDatePanel()
        }).disposed(by: disposeBag)
        isLoading.subscribe(onNext: { [weak self] loading in
            guard let self else { return }
            loadingView.isHidden = !loading
            loading ? loadingSpinner.startAnimating() : loadingSpinner.stopAnimating()
        }).disposed(by: disposeBag)
    }

    private func updateEventVersion() {
        loadingLabel.text = String(localized: "event.version.loading")
        isLoading.onNext(true)
        Task {
            let response = try? await Network.shared.client.fetch(query: CalendarPageVersionQuery())
            if let data = response?.data {
                let prev = UserDefaults.standard.string(forKey: "calendarVersion") ?? ""
                let isEmpty = Database.shared.database.objects(Event.self).isEmpty
                if data.calendar.version != prev || isEmpty { updateEvent() }
            }
        }
        isLoading.onNext(false)
    }

    private func updateEvent() {
        loadingLabel.text = String(localized: "event.database.loading")
        Task {
            let response = try? await Network.shared.client.fetch(query: CalendarPageQuery())
            if let data = response?.data {
                Event.replaceAll(with: data.calendar.categories.map { Event.transform(from: $0) }.flatMap { $0 })
                UserDefaults.standard.set(data.calendar.version, forKey: "calendarVersion")
            }
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
            ),
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
        let isCurrent = Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month)
        let isSelected = selectedDate.map { Calendar.current.isDate(date, inSameDayAs: $0) } ?? false
        cell.configure(date: date, isCurrentMonth: isCurrent, selected: isSelected)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let date = calendarDates[indexPath.item]
        if let cur = selectedDate, Calendar.current.isDate(date, inSameDayAs: cur) {
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
        selectedEvents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CalendarEventCellView.reuseIdentifier
        ) as? CalendarEventCellView else { return UITableViewCell() }
        cell.setupUI(item: selectedEvents[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        updateEventViewHeight()
    }
}
