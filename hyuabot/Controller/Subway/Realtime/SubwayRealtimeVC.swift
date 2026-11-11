//
//  SubwayRealtimeVC.swift
//  hyuabot
//

import Api
import ApolloAPI
import RxSwift
import UIKit

enum SubwayPayloadSelection {
    static func allKeys(weekday: String) -> [SubwayStationInput] {
        func station(_ id: String, _ directions: [String], _ limit: Int?) -> SubwayStationInput {
            SubwayStationInput(
                stationID: id, direction: directions, weekdays: [weekday],
                limit: limit.map { .some(Int32($0)) } ?? .null
            )
        }
        return [
            station("K449", ["up", "down"], 4),
            station("K251", ["up", "down"], 4),
            station("K258", ["up", "down"], nil),
            station("K456", ["up"], nil)
        ]
    }
}

class SubwayRealtimeVC: UIViewController {
    private var requestGeneration = 0
    private var lastAppliedGeneration = 0
    private let disposeBag = DisposeBag()
    private let contentView = SubwayRealtimeContentView()
    private var selectedTab: SubwayTabType = .line4
    private var subscription: Disposable?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.subwayRealtime)
        showCoachMarksIfNeeded()
    }

    private func showCoachMarksIfNeeded() {
        presentCoachMarks(pageId: "subway.realtime", items: [
            CoachMarkItem(
                id: "subway.tabs",
                targetView: contentView.segmentView,
                title: String(localized: "coach.subway.tabs.title"),
                message: String(localized: "coach.subway.tabs.message")
            ),
            CoachMarkItem(
                id: "subway.transfer",
                targetViewProvider: { [weak self] in self?.contentView.segmentView.button(at: 2) },
                title: String(localized: "coach.subway.transfer.title"),
                message: String(localized: "coach.subway.transfer.message")
            )
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeSubjects()
        SubwayRealtimeData.shared.isLoading.distinctUntilChanged().observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in self?.render() }).disposed(by: disposeBag)
        SubwayRealtimeData.shared.transferUp.observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in self?.render() }).disposed(by: disposeBag)
        SubwayRealtimeData.shared.transferDown.observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in self?.render() }).disposed(by: disposeBag)
        #if DEBUG
            if SubwayDebugFixture.activeMode != nil {
                render()
            }
        #endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startPolling()
        navigationController?.setNavigationBarHidden(true, animated: false)
        // Detect if the app is in the background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        stopPolling()
    }

    private func setupUI() {
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        navigationItem.backButtonTitle = String(localized: "tabbar.subway")
        contentView.onSelectTab = { [weak self] tab in
            self?.selectedTab = tab
            self?.render()
        }
        contentView.onTimetableTap = { [weak self] target in
            AnalyticsManager.logSelect(.subwayShowEntireTimetable)
            (self?.navigationController as? SubwayNC)?.moveToTimetableVC(line: target.line, heading: target.heading)
        }
        contentView.onRefresh = { [weak self] in
            AnalyticsManager.logSelect(.subwayRefresh)
            self?.fetchSubwayRealtimeData()
        }
    }

    private func render() {
        #if DEBUG
            let fixtureMode = SubwayDebugFixture.activeMode
            let isLoading = fixtureMode == .loading ? true : (fixtureMode != nil ? false : (
                (try? SubwayRealtimeData.shared.isLoading.value()) ?? true
            ))
            let now = fixtureMode != nil ? SubwayDebugFixture.now : Date.now
        #else
            let isLoading = (try? SubwayRealtimeData.shared.isLoading.value()) ?? true
            let now = Date.now
        #endif
        let sections: [SubwaySectionContent]
        switch selectedTab {
        case .line4:
            sections = SubwayDisplayLogic.lineSections(
                line: .line4,
                up: arrivals(.line4, .up),
                down: arrivals(.line4, .down)
            )
        case .lineSuin:
            sections = SubwayDisplayLogic.lineSections(
                line: .suin,
                up: arrivals(.suin, .up),
                down: arrivals(.suin, .down)
            )
        case .transfer:
            let toIncheon: [SubwayTransferRouteInfo]
            let toHanyang: [SubwayTransferRouteInfo]
            #if DEBUG
                if let fixtureMode {
                    toIncheon = SubwayDebugFixture.transferRoutes(toIncheon: true, mode: fixtureMode)
                    toHanyang = SubwayDebugFixture.transferRoutes(toIncheon: false, mode: fixtureMode)
                } else {
                    toIncheon = ((try? SubwayRealtimeData.shared.transferUp.value()) ?? []).map {
                        SubwayTransferRouteInfo(item: $0, transferStation: String(localized: "subway.station.k258"), showsPosition: false)
                    }
                    toHanyang = ((try? SubwayRealtimeData.shared.transferDown.value()) ?? []).map {
                        SubwayTransferRouteInfo(item: $0, transferStation: String(localized: "subway.station.k258"), showsPosition: true)
                    }
                }
            #else
                toIncheon = ((try? SubwayRealtimeData.shared.transferUp.value()) ?? []).map {
                    SubwayTransferRouteInfo(item: $0, transferStation: String(localized: "subway.station.k258"), showsPosition: false)
                }
                toHanyang = ((try? SubwayRealtimeData.shared.transferDown.value()) ?? []).map {
                    SubwayTransferRouteInfo(item: $0, transferStation: String(localized: "subway.station.k258"), showsPosition: true)
                }
            #endif
            sections = SubwayDisplayLogic.transferSections(toIncheon: toIncheon, toHanyang: toHanyang, now: now)
        }
        contentView.render(tab: selectedTab, isLoading: isLoading, sections: sections)
    }

    private func arrivals(_ line: SubwayLine, _ heading: SubwayHeadingEnum) -> [SubwayArrivalInfo] {
        #if DEBUG
            if let mode = SubwayDebugFixture.activeMode {
                return SubwayDebugFixture.arrivals(line: line, heading: heading, mode: mode)
            }
        #endif
        let subway: SubwayRealtimePageQuery.Data.Subway? = switch line {
        case .line4: try? SubwayRealtimeData.shared.combinedRealtimeData.value()?.campusBlue
        case .suin: try? SubwayRealtimeData.shared.combinedRealtimeData.value()?.campusYellow
        }
        let direction = heading == .up ? "up" : "down"
        return subway?.arrival.first(where: { $0.direction == direction })?.entries.map(SubwayArrivalInfo.init(entry:)) ?? []
    }

    private func observeSubjects() {
        SubwayRealtimeData.shared.realtimeData.subscribe(onNext: { data in
            // Update Realtime Data
            SubwayRealtimeData.shared.combinedRealtimeData.onNext(SubwayCombinedRealtimeData(
                campusBlue: data.first(where: { $0.stationID == "K449" }),
                campusYellow: data.first(where: { $0.stationID == "K251" }),
                oidoBlue: data.first(where: { $0.stationID == "K456" }),
                oidoYellow: data.first(where: { $0.stationID == "K258" })
            ))
        }).disposed(by: disposeBag)
        SubwayRealtimeData.shared.combinedRealtimeData.subscribe(onNext: { [weak self] data in
            guard
                let data,
                let campusBlue = data.campusBlue,
                let campusYellow = data.campusYellow,
                let oidoYellow = data.oidoYellow
            else {
                SubwayRealtimeData.shared.transferUp.onNext([])
                SubwayRealtimeData.shared.transferDown.onNext([])
                return
            }
            guard let self else { return }
            SubwayRealtimeData.shared.transferUp.onNext(processIncheonDirection(
                campusBlue: campusBlue,
                campusYellow: campusYellow,
                oidoYellow: oidoYellow
            ))
            SubwayRealtimeData.shared.transferDown.onNext(processHanyangDirection(oidoBlue: data.oidoBlue, oidoYellow: oidoYellow))
        }).disposed(by: disposeBag)
    }

    private func processIncheonDirection(
        campusBlue: SubwayRealtimePageQuery.Data.Subway,
        campusYellow: SubwayRealtimePageQuery.Data.Subway,
        oidoYellow: SubwayRealtimePageQuery.Data.Subway
    ) -> [SubwayTransferItem] {
        let downRealtimeWithoutTransfer: [SubwayTransferItem] = campusYellow.arrival.first(where: { $0.direction == "down" })?.entries
            .filter { entry in entry.terminal.stationID > "K258" && entry.isRealtime && entry.terminal.stationID.hasPrefix("K2")
            }.map { entry in SubwayTransferItem(
                take: entry,
                transfer: nil,
                transferWaitMinutes: nil
            )
            } ?? []
        let downTimetableToTransfer: [SubwayRealtimePageQuery.Data.Subway.Arrival.Entry] = oidoYellow.arrival
            .first(where: { $0.direction == "down" })?.entries.filter { entry in entry.origin?.stationID == "K258"
            } ?? []
        let downRealtimeWithTransfer: [SubwayTransferItem] = campusBlue.arrival.first(where: { $0.direction == "down" })?.entries
            .filter { entry in entry.terminal.stationID == "K456" }
            .map { entry in
                let firstItemWithOutTransfer = findTakeTrain(compare: downRealtimeWithoutTransfer, target: entry)
                return SubwayTransferItem(
                    take: entry,
                    transfer: findTransferTrain(compare: downTimetableToTransfer, entry: entry, target: firstItemWithOutTransfer),
                    transferWaitMinutes: nil
                )
            }.filter { entry in entry.transfer != nil
            } ?? []
        return (downRealtimeWithoutTransfer + downRealtimeWithTransfer).sorted { $0.take.minutes < $1.take.minutes }
    }

    private func processHanyangDirection(
        oidoBlue: SubwayRealtimePageQuery.Data.Subway?,
        oidoYellow: SubwayRealtimePageQuery.Data.Subway
    ) -> [SubwayTransferItem] {
        let first = oidoYellow.arrival.first(where: { $0.direction == "up" })?.entries ?? []
        let line4 = oidoBlue?.arrival.first(where: { $0.direction == "up" })?.entries ?? []
        return SubwayHanyangTransfer.routes(
            arrivingAtOido: first,
            line4Departures: line4,
            minutes: { $0.minutes },
            terminalID: { $0.terminal.stationID },
            isRealtime: { $0.isRealtime }
        ).map {
            SubwayTransferItem(take: $0.take, transfer: $0.transfer, transferWaitMinutes: $0.waitMinutes)
        }
    }

    private func findTakeTrain(
        compare: [SubwayTransferItem],
        target: SubwayRealtimePageQuery.Data.Subway.Arrival.Entry
    ) -> SubwayTransferItem? {
        compare.first(where: { $0.take.minutes > target.minutes })
    }

    private func findTransferTrain(
        compare: [SubwayRealtimePageQuery.Data.Subway.Arrival.Entry],
        entry: SubwayRealtimePageQuery.Data.Subway.Arrival.Entry,
        target: SubwayTransferItem?
    ) -> SubwayRealtimePageQuery.Data.Subway.Arrival.Entry? {
        compare.first(where: { transfer in
            if let target {
                transfer.minutes > entry.minutes + 20 && transfer.minutes < target.take.minutes + 20
            } else {
                transfer.minutes > entry.minutes + 20
            }
        })
    }

    private func fetchSubwayRealtimeData() {
        let today = Foundation.Date.now
        let component = Calendar.current.component(.weekday, from: today)
        let weekday = (component == 1 || component == 7) ? "weekends" : "weekdays"
        let language = LanguageManager.shared.apiLanguageTag
        SubwayRealtimeData.shared.prepareForLanguage(language)
        requestGeneration += 1
        let generation = requestGeneration
        let keys = SubwayPayloadSelection.allKeys(weekday: weekday)
        Task {
            let response = try? await Network.shared.client.fetch(
                query: SubwayRealtimePageQuery(
                    keys: keys,
                    language: language
                ),
                cachePolicy: .networkOnly
            )
            await MainActor.run {
                // A slow response from an earlier timer tick is still applied while the tab (and thus the keys) is unchanged.
                let currentDay = Calendar.current.component(.weekday, from: .now)
                let currentWeekday = (currentDay == 1 || currentDay == 7) ? "weekends" : "weekdays"
                guard generation > self.lastAppliedGeneration,
                      keys == SubwayPayloadSelection.allKeys(weekday: currentWeekday),
                      language == LanguageManager.shared.apiLanguageTag else { return }
                if let data = response?.data {
                    self.lastAppliedGeneration = generation
                    SubwayRealtimeData.shared.realtimeData.onNext(data.subway)
                    SubwayRealtimeData.shared.isLoading.onNext(false)
                    self.render()
                    self.contentView.endRefreshing()
                } else {
                    SubwayRealtimeData.shared.isLoading.onNext(false)
                    self.contentView.endRefreshing()
                }
            }
        }
    }

    private func startPolling() {
        #if DEBUG
            guard SubwayDebugFixture.activeMode == nil else { return }
        #endif
        fetchSubwayRealtimeData()
        subscription = Observable<Int>.interval(.seconds(15), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.fetchSubwayRealtimeData()
            })
    }

    private func stopPolling() {
        subscription?.dispose()
    }

    @objc
    func appDidEnterBackground() {
        stopPolling()
    }

    @objc
    func appWillEnterForeground() {
        startPolling()
    }
}

extension SubwayRealtimeVC {
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        // Pushed screens (e.g. the timetable) show only the back chevron.
        navigationItem.backButtonDisplayMode = .minimal
    }
}

extension SubwayArrivalInfo {
    init(entry: SubwayRealtimePageQuery.Data.Subway.Arrival.Entry) {
        self.init(
            terminalName: entry.terminal.name,
            minutes: entry.minutes,
            isRealtime: entry.isRealtime,
            isLast: entry.isLast ?? false,
            status: entry.status,
            location: entry.location
        )
    }
}

extension SubwayTransferRouteInfo {
    init(item: SubwayTransferItem, transferStation: String, showsPosition: Bool) {
        let first = SubwayTransferLegInfo(
            line: .from(stationID: item.take.terminal.stationID), terminalName: item.take.terminal.name,
            minutes: item.take.minutes, location: showsPosition ? item.take.location : nil,
            status: showsPosition ? item.take.status : nil
        )
        if let transfer = item.transfer {
            self.init(
                first: first,
                transferStation: transferStation,
                waitMinutes: item.transferWaitMinutes ?? (transfer.minutes - item.take.minutes),
                second: SubwayTransferLegInfo(
                    line: .from(stationID: transfer.terminal.stationID),
                    terminalName: transfer.terminal.name,
                    minutes: transfer.minutes
                )
            )
        } else {
            self.init(first: first, transferStation: nil, waitMinutes: nil, second: nil)
        }
    }
}
