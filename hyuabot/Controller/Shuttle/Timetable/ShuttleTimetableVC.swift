//
//  ShuttleTimetableVC.swift
//  hyuabot
//

import Api
import RxSwift
import UIKit

class ShuttleTimetableVC: UIViewController {
    private let stopID: String.LocalizationValue
    private let destination: String.LocalizationValue
    private let disposeBag = DisposeBag()
    private lazy var weekdaysVC = ShuttleTimetableTabVC(isWeekdays: true, showViaVC: openShuttleViaVC)
    private lazy var weekendsVC = ShuttleTimetableTabVC(isWeekdays: false, showViaVC: openShuttleViaVC)
    private let header = ShuttleTimetableHeaderView()
    private let pager = ContentView()

    init(stopID: String.LocalizationValue, destination: String.LocalizationValue) {
        self.stopID = stopID
        self.destination = destination
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        configureNavigationBar()
        ShuttleTimetableData.shared.options.onNext(ShuttleTimetableOptions(
            start: stopID,
            end: destination,
            date: Date.now,
            period: nil
        ))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.shuttleTimetable)
        showCoachMarksIfNeeded()
    }

    private func showCoachMarksIfNeeded() {
        guard CoachMarkManager.shared.shouldShowPage("shuttle.timetable") else { return }
        let isLoaded = (try? ShuttleTimetableData.shared.weekdays.value())?.isEmpty == false
        if isLoaded {
            presentTimetableCoachMarks()
        } else {
            ShuttleTimetableData.shared.weekdays
                .filter { !$0.isEmpty }
                .take(1)
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        self?.presentTimetableCoachMarks()
                    }
                })
                .disposed(by: disposeBag)
        }
    }

    private func presentTimetableCoachMarks() {
        let items: [CoachMarkItem] = [
            CoachMarkItem(
                id: "shuttle.timetable.tabs",
                targetView: header.daySegment,
                title: String(localized: "coach.shuttle.timetable.tabs.title"),
                message: String(localized: "coach.shuttle.timetable.tabs.message")
            ),
            CoachMarkItem(
                id: "shuttle.timetable.row",
                targetView: pager,
                title: String(localized: "coach.shuttle.timetable.row.title"),
                message: String(localized: "coach.shuttle.timetable.row.message")
            ),
            CoachMarkItem(
                id: "shuttle.timetable.filter",
                targetView: header.routeButton,
                title: String(localized: "coach.shuttle.timetable.filter.title"),
                message: String(localized: "coach.shuttle.timetable.filter.message")
            )
        ]
        presentCoachMarks(pageId: "shuttle.timetable", items: items)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeSubjects()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        ShuttleTimetableData.shared.options.onNext(nil)
        ShuttleTimetableData.shared.timetable.onNext([])
        ShuttleTimetableData.shared.weekdays.onNext([])
        ShuttleTimetableData.shared.weekends.onNext([])
    }

    private func setupUI() {
        view.backgroundColor = SettingsStyle.Color.background
        view.addSubview(header)
        view.addSubview(pager)
        pager.pages = [weekdaysVC.view, weekendsVC.view]
        pager.delegate = self
        header.onRouteTap = { [weak self] in self?.openFilterVC() }
        header.onSelectDay = { [weak self] isWeekdays in
            self?.pager.moveToPage(index: isWeekdays ? 0 : 1)
        }
        header.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        pager.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(header.snp.bottom)
            make.bottom.equalToSuperview()
        }
    }

    private func configureNavigationBar() {
        SettingsNavigationStyle.apply(to: self)
    }

    private func observeSubjects() {
        ShuttleTimetableData.shared.options.subscribe(onNext: { options in
            guard let options else { return }
            let period: String?
            if let date = options.date {
                let formatter = DateFormatter()
                formatter.locale = .current
                formatter.dateFormat = "M/d(E)"
                period = formatter.string(from: date)
            } else {
                period = options.period.map { String(localized: $0) }
            }
            self.header.configure(
                start: String(localized: options.start),
                end: String(localized: options.end),
                period: period,
                isWeekdays: self.pager.currentIndex == 0
            )
            // Query the timetable data
            let (stopID, destinations) = self.resolveStopAndDestination(options: options)
            self.fetchTimetable(options: options, stopID: stopID, destinations: destinations)
        }).disposed(by: disposeBag)
        ShuttleTimetableData.shared.timetable.subscribe(onNext: { timetable in
            ShuttleTimetableData.shared.weekdays.onNext(timetable.filter(\.weekday))
            ShuttleTimetableData.shared.weekends.onNext(timetable.filter { !$0.weekday })
            ShuttleTimetableData.shared.isLoading.onNext(false)
        }).disposed(by: disposeBag)
        ShuttleTimetableData.shared.weekdays.subscribe(onNext: { _ in
            self.weekdaysVC.reload()
        }).disposed(by: disposeBag)
        ShuttleTimetableData.shared.weekends.subscribe(onNext: { _ in
            self.weekendsVC.reload()
        }).disposed(by: disposeBag)
    }

    private func resolveStopAndDestination(options: ShuttleTimetableOptions) -> (String, [String]) {
        let route = ShuttleDisplayLogic.timetableRoute(start: options.start, end: options.end)
        return (route.stopID, route.destinationKey.map { [$0] } ?? [])
    }

    private func fetchTimetable(options: ShuttleTimetableOptions, stopID: String, destinations: [String]) {
        if options.period == nil {
            guard let date = options.date else { return }
            let dateFormatter = DateFormatter().then {
                $0.dateFormat = "yyyy-MM-dd"
            }
            ShuttleTimetableData.shared.isLoading.onNext(true)
            Task {
                let periodResponse = try? await Network.shared.client.fetch(query: ShuttleTimetablePeriodQuery(
                    date: dateFormatter.string(from: date)
                ))
                guard let period = periodResponse?.data?.shuttle.period?.type else {
                    publishTimetable([])
                    return
                }
                let timetableResponse = try? await Network.shared.client.fetch(query: ShuttleTimetablePageQuery(
                    date: .none,
                    period: [period],
                    weekdays: [true, false],
                    stopID: stopID,
                    destination: destinations
                ))
                publishTimetable(timetableResponse?.data?.shuttle.stops.first?.timetable.order ?? [])
            }
        } else {
            guard let period = resolvedPeriod(options.period) else {
                publishTimetable([])
                return
            }
            ShuttleTimetableData.shared.isLoading.onNext(true)
            Task {
                let timetableResponse = try? await Network.shared.client.fetch(query: ShuttleTimetablePageQuery(
                    date: .none,
                    period: [period],
                    weekdays: [true, false],
                    stopID: stopID,
                    destination: destinations
                ))
                publishTimetable(timetableResponse?.data?.shuttle.stops.first?.timetable.order ?? [])
            }
        }
    }

    private func resolvedPeriod(_ period: String.LocalizationValue?) -> String? {
        if period == "shuttle.period.semester" {
            return "semester"
        } else if period == "shuttle.period.vacation" {
            return "vacation"
        } else if period == "shuttle.period.vacation_session" {
            return "vacation_session"
        }
        return nil
    }

    private func publishTimetable(_ timetable: [ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order]) {
        DispatchQueue.main.async {
            ShuttleTimetableData.shared.timetable.onNext(timetable)
        }
    }

    private func openShuttleViaVC(_ item: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order) {
        let vc = ShuttleViaVC(item: item)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom(resolver: { context in
                min(vc.sheetHeight, context.maximumDetentValue)
            })]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true, completion: nil)
    }

    @objc
    private func openFilterVC() {
        AnalyticsManager.logSelect(.shuttleOpenFilter)
        let vc = ShuttleTimetableFilterVC()
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom { [weak vc] context in
                guard let vc else { return 0 }
                return min(vc.sheetHeight, context.maximumDetentValue)
            }]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true, completion: nil)
    }
}

extension ShuttleTimetableVC: ContentViewDelegate {
    func didMoveToPage(index: Int) {
        header.daySegment.setSelected(index)
    }
}
