import Api
import ApolloAPI
import Network
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
            station("K258", ["down"], nil),
            station("S26", ["up"], nil)
        ]
    }
}

// swiftlint:disable:next type_body_length
class SubwayRealtimeVC: UIViewController {
    private let transitStatusView = TransitStatusView()
    private let networkMonitor = NWPathMonitor()
    private var lastSuccessfulCheckAt: Foundation.Date?
    private var hasTransitError = false
    private var requestGeneration = 0
    private var lastAppliedGeneration = 0
    private static let chojiTravelMinutes = 8
    private static let chojiTransferBufferMinutes = 8
    private let disposeBag = DisposeBag()
    private lazy var line4VC = SubwayRealtimeTabVC(
        tabType: .line4,
        refreshMethod: self.fetchSubwayRealtimeData,
        showEntireTimetable: self.showEntireTimetable
    )
    private lazy var lineSuinVC = SubwayRealtimeTabVC(
        tabType: .lineSuin,
        refreshMethod: self.fetchSubwayRealtimeData,
        showEntireTimetable: self.showEntireTimetable
    )
    private lazy var transferVC = SubwayRealtimeTabVC(
        tabType: .transfer,
        refreshMethod: self.fetchSubwayRealtimeData,
        showEntireTimetable: self.showEntireTimetable
    )
    private var subscription: Disposable?
    private lazy var viewPager: ViewPager = {
        let viewPager = ViewPager(sizeConfiguration: .fillEqually(height: 52, spacing: 0))
        viewPager.contentView.pages = [
            self.line4VC.view,
            self.lineSuinVC.view,
            self.transferVC.view
        ]
        viewPager.tabView.tabs = [
            TabItem(title: String(localized: "subway.tab.blue")),
            TabItem(title: String(localized: "subway.tab.yellow")),
            TabItem(title: String(localized: "subway.tab.transfer"))
        ]
        viewPager.onPageChanged = { [weak self] _ in self?.renderTransitStatus() }
        return viewPager
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.subwayRealtime)
        showCoachMarksIfNeeded()
    }

    private func showCoachMarksIfNeeded() {
        presentCoachMarks(pageId: "subway.realtime", items: [
            CoachMarkItem(
                id: "subway.tabs",
                targetView: viewPager.tabView,
                title: String(localized: "coach.subway.tabs.title"),
                message: String(localized: "coach.subway.tabs.message")
            ),
            CoachMarkItem(
                id: "subway.transfer",
                targetViewProvider: { [weak self] in self?.viewPager.tabView.tabCellView(at: 2) },
                title: String(localized: "coach.subway.transfer.title"),
                message: String(localized: "coach.subway.transfer.message")
            )
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        networkMonitor.start(queue: DispatchQueue(label: "subway.transit.network"))
        setupUI()
        observeSubjects()
        renderTransitStatus()
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
        NotificationCenter.default.removeObserver(self)
        stopPolling()
    }

    deinit {
        networkMonitor.cancel()
    }

    private func setupUI() {
        view.addSubview(viewPager)
        view.addSubview(transitStatusView)
        transitStatusView.onRetry = { [weak self] in self?.fetchSubwayRealtimeData() }
        viewPager.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.transitStatusView.snp.top)
        }
        transitStatusView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    private func observeSubjects() {
        SubwayRealtimeData.shared.realtimeData.subscribe(onNext: { data in
            // Update Realtime Data
            SubwayRealtimeData.shared.combinedRealtimeData.onNext(SubwayCombinedRealtimeData(
                campusBlue: data.first(where: { $0.stationID == "K449" }),
                campusYellow: data.first(where: { $0.stationID == "K251" }),
                oidoBlue: data.first(where: { $0.stationID == "K456" }),
                oidoYellow: data.first(where: { $0.stationID == "K258" }),
                chojiSeohae: data.first(where: { $0.stationID == "S26" })
            ))
        }).disposed(by: disposeBag)
        SubwayRealtimeData.shared.combinedRealtimeData.subscribe(onNext: { [weak self] data in
            guard
                let data,
                let campusBlue = data.campusBlue,
                let campusYellow = data.campusYellow,
                let oidoYellow = data.oidoYellow,
                let chojiSeohae = data.chojiSeohae
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
            SubwayRealtimeData.shared.transferDown.onNext(processChojiDirection(
                campusBlue: campusBlue,
                campusYellow: campusYellow,
                chojiSeohae: chojiSeohae
            ))
        }).disposed(by: disposeBag)
    }

    private func processIncheonDirection(
        campusBlue: SubwayRealtimePageQuery.Data.Subway,
        campusYellow: SubwayRealtimePageQuery.Data.Subway,
        oidoYellow: SubwayRealtimePageQuery.Data.Subway
    ) -> [SubwayTransferItem] {
        let downRealtimeWithoutTransfer: [SubwayTransferItem] = campusYellow.arrival.first(where: { $0.direction == "down" })?.entries
            .filter {
                entry in entry.terminal.stationID > "K258" && entry.isRealtime && entry.terminal.stationID.hasPrefix("K2")
            }.map {
                entry in SubwayTransferItem(
                    take: entry,
                    transfer: nil,
                    transferWaitMinutes: nil
                )
            } ?? []
        let downTimetableToTransfer: [SubwayRealtimePageQuery.Data.Subway.Arrival.Entry] = oidoYellow.arrival
            .first(where: { $0.direction == "down" })?.entries.filter {
                entry in entry.origin?.stationID == "K258"
            } ?? []
        let downRealtimeWithTransfer: [SubwayTransferItem] = campusBlue.arrival.first(where: { $0.direction == "down" })?.entries.filter {
            entry in entry.terminal.stationID == "K456"
        }.map { entry in
            let firstItemWithOutTransfer = findTakeTrain(compare: downRealtimeWithoutTransfer, target: entry)
            return SubwayTransferItem(
                take: entry,
                transfer: findTransferTrain(compare: downTimetableToTransfer, entry: entry, target: firstItemWithOutTransfer),
                transferWaitMinutes: nil
            )
        }.filter {
            entry in entry.transfer != nil
        } ?? []
        return (downRealtimeWithoutTransfer + downRealtimeWithTransfer).sorted { $0.take.minutes < $1.take.minutes }
    }

    private func processChojiDirection(
        campusBlue: SubwayRealtimePageQuery.Data.Subway,
        campusYellow: SubwayRealtimePageQuery.Data.Subway,
        chojiSeohae: SubwayRealtimePageQuery.Data.Subway
    ) -> [SubwayTransferItem] {
        let firstLegs = (
            campusBlue.arrival.first(where: { $0.direction == "down" })?.entries.filter {
                $0.terminal.stationID >= "K452" && $0.terminal.stationID.hasPrefix("K4")
            } ?? []
        ) + (
            campusYellow.arrival.first(where: { $0.direction == "down" })?.entries.filter {
                $0.terminal.stationID >= "K254" && $0.terminal.stationID.hasPrefix("K2")
            } ?? []
        )
        let secondLegs = chojiSeohae.arrival.first(where: { $0.direction == "up" })?.entries.filter {
            $0.terminal.stationID <= "S16" && $0.terminal.stationID.hasPrefix("S")
        } ?? []

        return firstLegs.sorted { $0.minutes < $1.minutes }.compactMap { firstLeg in
            guard let transfer = secondLegs.first(where: {
                $0.minutes > firstLeg.minutes + Self.chojiTravelMinutes + Self.chojiTransferBufferMinutes
            }) else { return nil }
            return SubwayTransferItem(
                take: firstLeg,
                transfer: transfer,
                transferWaitMinutes: transfer.minutes - firstLeg.minutes - Self.chojiTravelMinutes
            )
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
                    self.hasTransitError = false
                    self.lastAppliedGeneration = generation
                    self.lastSuccessfulCheckAt = .now
                    SubwayRealtimeData.shared.realtimeData.onNext(data.subway)
                    self.renderTransitStatus()
                    SubwayRealtimeData.shared.isLoading.onNext(false)
                    self.line4VC.reload()
                    self.lineSuinVC.reload()
                    self.transferVC.reload()
                } else {
                    self.hasTransitError = true
                    self.renderTransitStatus()
                    SubwayRealtimeData.shared.isLoading.onNext(false)
                }
            }
        }
    }

    private func renderTransitStatus() {
        let stations = (try? SubwayRealtimeData.shared.realtimeData.value()) ?? []
        let visibleStationIDs: Set<String> = switch viewPager.tabView.currentIndex {
        case 0: ["K449", "K456"]
        case 1: ["K251", "K258"]
        default: ["K449", "K456", "K251", "K258", "S26"]
        }
        let visibleStations = stations.filter { visibleStationIDs.contains($0.stationID) }
        transitStatusView.show(
            RealtimeFreshness.statusText(
                stationUpdates: visibleStations.map { $0.realtime.map { Optional($0.updatedAt) } },
                hasArrivals: visibleStations.contains { $0.arrival.contains { !$0.entries.isEmpty } },
                lastSuccessfulCheckAt: lastSuccessfulCheckAt,
                isLoading: (try? SubwayRealtimeData.shared.isLoading.value()) ?? false,
                hasError: hasTransitError,
                isOffline: networkMonitor.currentPath.status == .unsatisfied,
                staleAfter: 180
            ),
            retry: hasTransitError
        )
    }

    private func startPolling() {
        fetchSubwayRealtimeData()
        subscription = Observable<Int>.interval(.seconds(15), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.fetchSubwayRealtimeData()
            })
    }

    private func stopPolling() {
        subscription?.dispose()
    }

    private func showEntireTimetable(title: String.LocalizationValue, heading: SubwayHeadingEnum) {
        guard let nc = navigationController as? SubwayNC else { return }
        nc.moveToTimetableVC(timetableTitle: title, heading: heading)
    }

    private func checkTimetableAfterRealtime(departureTime: String, maxValue: Double) -> Bool {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        guard let departureTime = dateFormatter.date(from: departureTime) else { return false }
        let hour = calendar.component(.hour, from: departureTime)
        let minute = calendar.component(.minute, from: departureTime)
        let second = calendar.component(.second, from: departureTime)
        let remainingTime = (hour * 3600 + minute * 60 + second) - (calendar.component(.hour, from: Date.now) * 3600 + calendar.component(
            .minute,
            from: Date.now
        ) * 60 + calendar.component(.second, from: Date.now)) // in seconds
        return remainingTime > Int(maxValue * 60)
    }

    private func calculateRemainingTime(current: Foundation.Date, departureTime: String) -> Int {
        let splitTime = departureTime.split(separator: ":")
        guard splitTime.count >= 2,
              var hour = Int(splitTime[0]),
              let minute = Int(splitTime[1]) else { return Int.max }
        if hour < 4 {
            hour += 24
        }
        return 60 * (hour - Calendar.current.component(.hour, from: current)) + (minute - Calendar.current.component(
            .minute,
            from: current
        ))
    }

    @objc func appDidEnterBackground() {
        stopPolling()
    }

    @objc func appWillEnterForeground() {
        startPolling()
    }
}
