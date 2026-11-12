//
//  BusTimetableVC.swift
//  hyuabot
//

import Api
import RxSwift
import UIKit

final class BusTimetableVC: UIViewController {
    let stopID: Int32
    let routes: [Int32]
    let stopName: String
    let routeNames: [String]
    private let disposeBag = DisposeBag()
    private var refreshSubscription: Disposable?
    private var items: [BusTimetableItem] = []
    private var day: BusTimetableDay?
    private var filter: String?
    private var expanded = false
    private var isLoading = true
    private var sections: [BusTimetableHourGroup] = []
    private var hiddenPastCount = 0
    private var showsCard = false
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let headerView = BusTimetableHeaderView()
    private let footerView = BusTimetableCardFooterView()

    init(stopID: Int32, routes: [Int32], routeNames: [String], stopName: String) {
        self.stopID = stopID
        self.routes = routes
        self.routeNames = routeNames
        self.stopName = stopName
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeData()
        fetchBusTimetable()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.busTimetable)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        configureNavigationBar()
        render()
        refreshSubscription?.dispose()
        refreshSubscription = Observable<Int>.interval(.seconds(60), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in self?.render() })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        refreshSubscription?.dispose()
        refreshSubscription = nil
    }

    private func setupUI() {
        view.backgroundColor = SettingsStyle.Color.background
        tableView.backgroundColor = SettingsStyle.Color.background
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 0
        tableView.sectionFooterHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.rowHeight = BusTimetableRowCell.rowHeight
        tableView.estimatedRowHeight = BusTimetableRowCell.rowHeight
        tableView.accessibilityIdentifier = "bus.timetable.table"
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(BusTimetableRowCell.self, forCellReuseIdentifier: BusTimetableRowCell.reuseIdentifier)
        tableView.register(BusTimetableHourHeaderView.self, forHeaderFooterViewReuseIdentifier: BusTimetableHourHeaderView.reuseIdentifier)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView
        headerView.onSelectDay = { [weak self] day in
            guard let self else { return }
            self.day = day
            resetSelection()
        }
        headerView.onSelectFilter = { [weak self] route in
            guard let self else { return }
            filter = route
            resetSelection()
        }
        headerView.onExpand = { [weak self] in
            self?.expanded = true
            self?.render()
        }
    }

    private func resetSelection() {
        expanded = false
        render()
        tableView.setContentOffset(CGPoint(x: 0, y: -tableView.adjustedContentInset.top), animated: false)
    }

    private func configureNavigationBar() {
        let scrolledAppearance = UINavigationBarAppearance()
        scrolledAppearance.configureWithDefaultBackground()
        scrolledAppearance.titleTextAttributes = SettingsNavigationStyle.makeAppearance().titleTextAttributes
        let edgeAppearance = UINavigationBarAppearance()
        edgeAppearance.configureWithTransparentBackground()
        edgeAppearance.backgroundColor = .clear
        edgeAppearance.shadowColor = .clear
        var edgeTitleAttributes = SettingsNavigationStyle.makeAppearance().titleTextAttributes
        edgeTitleAttributes[.foregroundColor] = UIColor.clear
        edgeAppearance.titleTextAttributes = edgeTitleAttributes
        navigationItem.title = stopName
        navigationItem.standardAppearance = scrolledAppearance
        navigationItem.compactAppearance = scrolledAppearance
        navigationItem.scrollEdgeAppearance = edgeAppearance
        navigationItem.compactScrollEdgeAppearance = edgeAppearance
        navigationController?.navigationBar.tintColor = SettingsStyle.Color.link
    }

    private func observeData() {
        BusTimetableData.shared.timetable.observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] items in
                self?.items = items
                self?.render()
            }).disposed(by: disposeBag)
        BusTimetableData.shared.isLoading.observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] loading in
                self?.isLoading = loading
                self?.render()
            }).disposed(by: disposeBag)
    }

    private func fetchBusTimetable() {
        BusTimetableData.shared.isLoading.onNext(true)
        Task {
            let response = try? await Network.shared.client.fetch(query: BusTimetablePageQuery(routeStops: self.routes.map {
                BusRouteStopInput(route: $0, stop: self.stopID)
            }))
            await MainActor.run {
                if let data = response?.data {
                    BusTimetableData.shared.publish(data.bus.flatMap { bus in
                        bus.timetable.map { timetable in
                            BusTimetableItem(route: bus.route.name, weekdays: timetable.weekday, time: timetable.time.toLocalTime())
                        }
                    })
                } else {
                    BusTimetableData.shared.isLoading.onNext(false)
                }
            }
        }
    }

    private func render() {
        let tabs = BusDisplayLogic.dayTabs(items: items)
        let now = Foundation.Date()
        let calendar = BusDisplayLogic.serviceCalendar
        let today = BusDisplayLogic.today(date: now, tabs: tabs, calendar: calendar)
        let selected = day.flatMap { tabs.contains($0) ? $0 : nil } ?? today
        let entries = BusDisplayLogic.entries(items: items, day: selected, routeFilter: filter, calendar: calendar)
        let layout = BusDisplayLogic.layout(
            entries: entries, isToday: selected == today,
            nowMinutes: BusDisplayLogic.serviceMinutes(of: now, calendar: calendar), expanded: expanded
        )
        let state: BusTimetableHeaderState
        if isLoading {
            state = .loading
        } else if let filter, !items.contains(where: { $0.route == filter }) {
            state = .noData(route: filter)
        } else if routeNames.count == 1, items.isEmpty, let route = routeNames.first {
            state = .noData(route: route)
        } else if entries.isEmpty {
            state = .noService(dayName: dayTitle(selected))
        } else {
            state = .list(hiddenPastCount: layout.hiddenPastCount)
        }
        if case .list = state {
            sections = layout.groups
            showsCard = true
        } else {
            sections = []
            showsCard = false
        }
        hiddenPastCount = layout.hiddenPastCount
        headerView.configure(BusTimetableHeaderContent(
            routeNames: routeNames, stopName: stopName, days: tabs, selectedDay: selected,
            dayCounts: tabs.map {
                BusDisplayLogic.entries(items: items, day: $0, routeFilter: filter, calendar: calendar).count
            },
            filter: filter, state: state
        ))
        footerView.configure(showsCard: showsCard)
        tableView.reloadData()
        resizeSupplementaryViews()
    }

    private func dayTitle(_ day: BusTimetableDay) -> String {
        switch day {
        case .weekdays: return String(localized: "bus.timetable.weekdays")
        case .saturday: return String(localized: "bus.timetable.saturdays")
        case .sunday: return String(localized: "bus.timetable.sundays")
        case .weekends: return String(localized: "bus.timetable.weekends")
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizeSupplementaryViews()
    }

    private func resizeSupplementaryViews() {
        let width = tableView.bounds.width
        guard width > 0 else { return }
        let headerHeight = headerView.fittingHeight(width: width)
        if headerView.frame.size != CGSize(width: width, height: headerHeight) {
            headerView.frame = CGRect(x: 0, y: 0, width: width, height: headerHeight)
            tableView.tableHeaderView = headerView
        }
        let footerHeight = BusTimetableCardFooterView.height(showsCard: showsCard, width: width)
        if footerView.frame.size != CGSize(width: width, height: footerHeight) {
            footerView.frame = CGRect(x: 0, y: 0, width: width, height: footerHeight)
            tableView.tableFooterView = footerView
        }
    }
}

extension BusTimetableVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: BusTimetableRowCell.reuseIdentifier, for: indexPath
        ) as? BusTimetableRowCell else { return UITableViewCell() }
        let row = sections[indexPath.section].rows[indexPath.row]
        let isMerged = routeNames.count > 1 && filter == nil
        let isLastRow = indexPath.section == sections.count - 1
            && indexPath.row == sections[indexPath.section].rows.count - 1
        cell.configure(
            row, showsRouteBadge: BusDisplayLogic.showsTimetableRouteBadge(isMerged: isMerged), roundsBottom: isLastRow
        )
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        BusTimetableHourHeaderView.height(isFirst: section == 0)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { .leastNonzeroMagnitude }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: BusTimetableHourHeaderView.reuseIdentifier
        ) as? BusTimetableHourHeaderView else { return nil }
        header.configure(
            hour: sections[section].hour, isFirst: section == 0,
            roundsTop: section == 0 && hiddenPastCount == 0
        )
        return header
    }
}
