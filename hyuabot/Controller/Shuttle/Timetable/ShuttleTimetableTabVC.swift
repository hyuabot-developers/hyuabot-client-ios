//
//  ShuttleTimetableTabVC.swift
//  hyuabot
//

import Api
import RxSwift
import UIKit

class ShuttleTimetableTabVC: UIViewController {
    private let isWeekdays: Bool
    private let showViaVC: @MainActor (ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order) -> Void
    private let disposeBag = DisposeBag()
    private var showsSkeleton = false
    private var showsPastRows = false
    private var nowMinutes: Int?
    private var items: [ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order] = []
    private var projection = ShuttleDisplayLogic.timetableProjection(
        departureMinutes: [],
        nowMinutes: nil,
        scrollNowMinutes: 0,
        showsPastRows: false
    )

    private lazy var shuttleTimetableTableView: UITableView = .init(frame: .zero, style: .grouped).then {
        $0.backgroundColor = SettingsStyle.Color.background
        $0.separatorStyle = .none
        $0.contentInset.bottom = 28
        $0.delegate = self
        $0.dataSource = self
        $0.sectionHeaderTopPadding = 0
        $0.sectionFooterHeight = 0
        $0.estimatedSectionFooterHeight = 0
        $0.showsVerticalScrollIndicator = false
        $0.register(ShuttleTimetableCellView.self, forCellReuseIdentifier: ShuttleTimetableCellView.reuseIdentifier)
        $0.register(ShuttleTimetableEmptyCellView.self, forCellReuseIdentifier: ShuttleTimetableEmptyCellView.reuseIdentifier)
        $0.register(ShuttleTimetableSkeletonCellView.self, forCellReuseIdentifier: ShuttleTimetableSkeletonCellView.reuseIdentifier)
        $0.register(BusTimetableHourHeaderView.self, forHeaderFooterViewReuseIdentifier: BusTimetableHourHeaderView.reuseIdentifier)
    }

    init(
        isWeekdays: Bool,
        showViaVC: @escaping @MainActor (ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order) -> Void
    ) {
        self.isWeekdays = isWeekdays
        self.showViaVC = showViaVC
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeSubjects()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if projection.hiddenPastCount > 0 {
            if shuttleTimetableTableView.tableHeaderView?.frame.width != shuttleTimetableTableView.bounds.width {
                updateFoldStrip()
            }
        }
    }

    private func setupUI() {
        view.addSubview(shuttleTimetableTableView)
        shuttleTimetableTableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    var firstVisibleCell: UIView? {
        shuttleTimetableTableView.visibleCells.first
    }

    private func rebuildProjection() {
        items = (try? (isWeekdays ? ShuttleTimetableData.shared.weekdays.value() : ShuttleTimetableData.shared.weekends.value())) ?? []
        let now = Date.now
        let comps = Calendar.current.dateComponents([.hour, .minute], from: now)
        let nowService = ShuttleDisplayLogic.serviceMinutes(hour: comps.hour ?? 0, minute: comps.minute ?? 0)
        let selectedDate = (try? ShuttleTimetableData.shared.options.value())?.date
        let nowMinutes = ShuttleDisplayLogic.isServiceDayMatch(
            isWeekdays: isWeekdays,
            selectedDate: selectedDate,
            now: now,
            calendar: .current
        ) ? nowService : nil
        self.nowMinutes = nowMinutes
        projection = ShuttleDisplayLogic.timetableProjection(
            departureMinutes: items.map { ShuttleDisplayLogic.serviceMinutes(time: $0.time) ?? Int.max },
            nowMinutes: nowMinutes,
            scrollNowMinutes: nowService,
            showsPastRows: showsPastRows
        )
        updateFoldStrip()
    }

    private func updateFoldStrip() {
        guard projection.hiddenPastCount > 0 else {
            shuttleTimetableTableView.tableHeaderView = nil
            return
        }
        let width = shuttleTimetableTableView.bounds.width > 0 ? shuttleTimetableTableView.bounds.width : view.bounds.width
        let container = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 44))
        let card = UIView().then {
            $0.backgroundColor = SettingsStyle.Color.card
            $0.layer.cornerRadius = 16
            $0.layer.cornerCurve = .continuous
            $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
        let button = UIButton(type: .system).then {
            var config = UIButton.Configuration.plain()
            config.image = UIImage(systemName: "chevron.up")?.applyingSymbolConfiguration(
                UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
            )
            config.imagePlacement = .leading
            config.imagePadding = 4
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            config.baseForegroundColor = SettingsStyle.Color.link
            config.attributedTitle = AttributedString(SettingsStyle.attributedText(
                String(format: String(localized: "shuttle.timetable.fold.%lld"), projection.hiddenPastCount),
                font: SettingsStyle.font(13, bold: true), color: SettingsStyle.Color.link, lineHeight: 18
            ))
            $0.configuration = config
            $0.accessibilityIdentifier = "shuttle.timetable.fold"
            $0.addTarget(self, action: #selector(showPastDepartures), for: .touchUpInside)
        }
        let separator = UIView().then { $0.backgroundColor = SettingsStyle.Color.separator }
        container.addSubview(card)
        card.addSubview(button)
        card.addSubview(separator)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)) }
        button.snp.makeConstraints { $0.edges.equalToSuperview() }
        separator.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(1 / UIScreen.main.scale) }
        shuttleTimetableTableView.tableHeaderView = container
    }

    @objc
    private func showPastDepartures() {
        showsPastRows = true
        reload()
    }

    func reload() {
        rebuildProjection()
        shuttleTimetableTableView.reloadData()
        guard !showsSkeleton,
              let item = projection.scrollTargetItem,
              let indexPath = projection.indexPath(ofItem: item) else { return }
        shuttleTimetableTableView.scrollToRow(at: indexPath, at: .middle, animated: false)
    }

    private func observeSubjects() {
        ShuttleTimetableData.shared.options
            .subscribe(onNext: { [weak self] _ in self?.showsPastRows = false })
            .disposed(by: disposeBag)
        ShuttleTimetableData.shared.isLoading
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                guard let self else { return }
                if isLoading {
                    showsPastRows = false
                }
                showsSkeleton = isLoading
                reload()
            })
            .disposed(by: disposeBag)
    }
}

extension ShuttleTimetableTabVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        showsSkeleton || items.isEmpty ? 1 : projection.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showsSkeleton {
            return 8
        }
        guard !items.isEmpty else { return 1 }
        guard projection.sections.indices.contains(section) else { return 0 }
        return projection.sections[section].itemIndices.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        showsSkeleton || items.isEmpty ? UITableView.automaticDimension : ShuttleTimetableCellView.rowHeight
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        showsSkeleton || items.isEmpty ? 0 : BusTimetableHourHeaderView.height(isFirst: section == 0)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !showsSkeleton, !items.isEmpty, projection.sections.indices.contains(section),
              let header = tableView
              .dequeueReusableHeaderFooterView(withIdentifier: BusTimetableHourHeaderView.reuseIdentifier) as? BusTimetableHourHeaderView
        else { return nil }
        header.configure(
            hour: projection.sections[section].hour,
            isFirst: section == 0,
            roundsTop: section == 0 && projection.hiddenPastCount == 0,
            horizontalInset: 16
        )
        return header
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showsSkeleton {
            return tableView.dequeueReusableCell(withIdentifier: ShuttleTimetableSkeletonCellView.reuseIdentifier, for: indexPath)
        }
        guard !items.isEmpty else {
            return tableView.dequeueReusableCell(withIdentifier: ShuttleTimetableEmptyCellView.reuseIdentifier, for: indexPath)
        }
        guard let itemIndex = projection.itemIndex(at: indexPath), items.indices.contains(itemIndex),
              let options = try? ShuttleTimetableData.shared.options.value(),
              let cell = tableView
              .dequeueReusableCell(withIdentifier: ShuttleTimetableCellView.reuseIdentifier, for: indexPath) as? ShuttleTimetableCellView
        else {
            return tableView.dequeueReusableCell(withIdentifier: ShuttleTimetableEmptyCellView.reuseIdentifier, for: indexPath)
        }
        cell.setupUI(option: options, item: items[itemIndex])
        let isLast = indexPath.section == projection.sections.count - 1 && indexPath.row == projection.sections[indexPath.section]
            .itemIndices.count - 1
        cell.apply(state: projection.states[itemIndex], roundsBottom: isLast)
        let departure = ShuttleDisplayLogic.serviceMinutes(time: items[itemIndex].time)
        if projection.states[itemIndex] == .next, let nowMinutes, let departure {
            let remaining = max(0, departure - nowMinutes)
            cell.setNextBadge(String(format: String(localized: "intent.common.minutes.later"), String(remaining)))
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let itemIndex = projection.itemIndex(at: indexPath), items.indices.contains(itemIndex) else { return }
        AnalyticsManager.logSelect(.shuttleSelectViaRow, type: .listItem)
        showViaVC(items[itemIndex])
    }
}
