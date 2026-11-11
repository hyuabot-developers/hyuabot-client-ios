//
//  SubwayTimetableVC.swift
//  hyuabot
//

import Api
import RxSwift
import SnapKit
import UIKit

class SubwayTimetableVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let line: SubwayLine
    private let heading: SubwayHeadingEnum
    private let merged: Bool
    private let disposeBag = DisposeBag()
    private let now: Foundation.Date
    private var today: SubwayDayType
    private var day: SubwayDayType
    private var expanded = false
    private var isLoading = true
    private var weekdays: [SubwayTimetableDeparture] = []
    private var weekends: [SubwayTimetableDeparture] = []
    private var layout = SubwayTimetableLayout(hiddenPastCount: 0, groups: [])
    private var lastTableWidth: CGFloat = 0
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let header = SubwayTimetableHeaderView()
    private let footer = SubwayTimetableCardFooterView()
    private let compactBar = SubwayCompactBarView(maxTitleWidth: 200, titleCenterFromBottom: 22)

    init(line: SubwayLine, heading: SubwayHeadingEnum) {
        self.line = line
        self.heading = heading
        merged = SubwayDisplayLogic.isMerged(line: line, heading: heading)
        #if DEBUG
            let fixtureActive = SubwayDebugFixture.activeMode != nil
            now = fixtureActive ? SubwayDebugFixture.now : .now
            today = fixtureActive ? SubwayDebugFixture.dayType : SubwayDayType.serviceDay(.now)
        #else
            now = .now
            today = SubwayDayType.serviceDay(.now)
        #endif
        day = today
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCallbacks()
        fetchSubwayTimetable()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.subwayTimetable)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.tintColor = SettingsStyle.Color.link
        configureNavigationBar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let navBar = navigationController?.navigationBar {
            // Center the title on the back button: the button occupies the top 44pt of the navigation bar.
            compactBar.setTitleCenterFromBottom(view.safeAreaInsets.top - (navBar.frame.minY + 22))
        }
        guard tableView.bounds.width > 0, tableView.bounds.width != lastTableWidth else { return }
        resizeTableSupplementaryViews()
    }

    private func setupUI() {
        view.backgroundColor = SettingsStyle.Color.background
        navigationItem.title = nil
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 0
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInsetAdjustmentBehavior = .automatic
        tableView.estimatedRowHeight = 44
        tableView.sectionFooterHeight = 0
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SubwayTimetableRowCell.self, forCellReuseIdentifier: SubwayTimetableRowCell.reuseIdentifier)
        tableView.register(SubwayTimetableHourHeaderView.self, forHeaderFooterViewReuseIdentifier: "SubwayTimetableHourHeaderView")
        tableView.tableHeaderView = header
        tableView.tableFooterView = footer
        tableView.accessibilityLabel = String(
            format: String(localized: "subway.timetable.a11y.section.%@.%@"),
            merged ? String(localized: "subway.line.name.line4.suin") : SubwayDisplayLogic.routeLine(line).name,
            SubwayDisplayLogic.title(line: line, heading: heading)
        )
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        compactBar.setTitle(SubwayDisplayLogic.title(line: line, heading: heading))
        view.addSubview(compactBar)
        compactBar.snp.makeConstraints {
            $0.leading.trailing.top.equalToSuperview()
            // The safe-area top is the navigation bar bottom; its back button is 22pt above it.
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
    }

    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = .clear
        appearance.backButtonAppearance.normal.titleTextAttributes = [
            .font: SettingsStyle.font(17), .foregroundColor: SettingsStyle.Color.link
        ]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }

    private func setupCallbacks() {
        header.onSelectDay = { [weak self] selectedDay in
            guard let self else { return }
            day = selectedDay
            expanded = false
            render()
        }
        header.onExpand = { [weak self] in
            self?.expanded = true
            self?.render()
        }
    }

    private func fetchSubwayTimetable() {
        #if DEBUG
            if let mode = SubwayDebugFixture.activeMode {
                if mode != .loading {
                    weekdays = fixtureDepartures(day: .weekdays)
                    weekends = fixtureDepartures(day: .weekends)
                    isLoading = false
                }
                render()
                return
            }
        #endif
        SubwayTimetableData.shared.isLoading.onNext(true)
        SubwayTimetableData.shared.timetable.onNext([])
        let station = line == .line4 ? "K449" : "K251"
        let direction = heading == .up ? "up" : "down"
        Task {
            async let primary = fetchTimetable(station: station, direction: direction)
            async let suin = merged ? fetchTimetable(station: "K251", direction: "down") : []
            let (primaryRows, suinRows) = await (primary, suin)
            await MainActor.run {
                SubwayTimetableData.shared.timetable.onNext(primaryRows)
                SubwayTimetableData.shared.isLoading.onNext(false)
                weekdays = self.departures(primaryRows, suinRows: suinRows, day: .weekdays)
                weekends = self.departures(primaryRows, suinRows: suinRows, day: .weekends)
                isLoading = false
                render()
            }
        }
    }

    private func fetchTimetable(
        station: String,
        direction: String
    ) async -> [SubwayTimetablePageQuery.Data.Subway.Timetable] {
        let response = try? await Network.shared.client.fetch(
            query: SubwayTimetablePageQuery(
                station: station,
                direction: [direction],
                language: LanguageManager.shared.apiLanguageTag
            ),
            cachePolicy: .networkOnly
        )
        return response?.data?.subway.first?.timetable ?? []
    }

    private func departures(
        _ rows: [SubwayTimetablePageQuery.Data.Subway.Timetable],
        suinRows: [SubwayTimetablePageQuery.Data.Subway.Timetable],
        day: SubwayDayType
    ) -> [SubwayTimetableDeparture] {
        let line4 = SubwayDisplayLogic.departures(
            rows.filter { $0.weekday == day.apiValue }.map { (time: $0.time, terminalName: $0.terminal.name) },
            line: .line4
        )
        guard merged else { return line4 }
        let suin = SubwayDisplayLogic.departures(
            suinRows.filter { $0.weekday == day.apiValue }.map { (time: $0.time, terminalName: $0.terminal.name) },
            line: .suin
        )
        return SubwayDisplayLogic.merged([line4, suin])
    }

    #if DEBUG
        private func fixtureDepartures(day: SubwayDayType) -> [SubwayTimetableDeparture] {
            let primary = SubwayDebugFixture.departures(line: line, heading: heading, day: day)
            guard merged else { return primary }
            let suin = SubwayDebugFixture.departures(line: .suin, heading: .down, day: day)
            return SubwayDisplayLogic.merged([primary, suin])
        }
    #endif

    private func render() {
        let list = day == .weekdays ? weekdays : weekends
        layout = SubwayDisplayLogic.timetableLayout(
            list,
            nowMinutes: day == today ? SubwayDisplayLogic.nowMinutes(now) : nil,
            expanded: expanded,
            merged: merged
        )
        header.configure(
            line: line,
            heading: heading,
            day: day,
            counts: (weekday: isLoading ? nil : weekdays.count, weekend: isLoading ? nil : weekends.count),
            isLoading: isLoading,
            layout: layout
        )
        footer.configure(showsFootnote: !isLoading)
        resizeTableSupplementaryViews()
        tableView.reloadData()
    }

    private func resizeTableSupplementaryViews() {
        let width = tableView.bounds.width
        guard width > 0 else { return }
        lastTableWidth = width
        header.frame = CGRect(x: 0, y: 0, width: width, height: header.fittingHeight(width: width))
        footer.frame = CGRect(x: 0, y: 0, width: width, height: footer.fittingHeight(width: width))
        tableView.tableHeaderView = header
        tableView.tableFooterView = footer
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        isLoading ? 0 : layout.groups.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        layout.groups[section].rows.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SubwayTimetableRowCell.reuseIdentifier,
            for: indexPath
        ) as? SubwayTimetableRowCell else { return UITableViewCell() }
        cell.configure(layout.groups[indexPath.section].rows[indexPath.row], merged: merged)
        let isLastRow = indexPath.section == layout.groups.count - 1
            && indexPath.row == layout.groups[indexPath.section].rows.count - 1
        cell.setRoundsBottom(isLastRow)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: "SubwayTimetableHourHeaderView"
        ) as? SubwayTimetableHourHeaderView else { return nil }
        headerView.configure(layout.groups[section], isFirst: section == 0, roundsTop: section == 0 && layout.hiddenPastCount == 0)
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        28
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { .leastNonzeroMagnitude }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        compactBar.setRevealProgress(
            SubwayCompactBarView.revealProgress(
                contentOffsetY: tableView.contentOffset.y,
                adjustedTopInset: tableView.adjustedContentInset.top
            )
        )
    }
}
