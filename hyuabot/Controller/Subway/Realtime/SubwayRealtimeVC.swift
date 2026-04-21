import UIKit
import RxSwift
import Api

class SubwayRealtimeVC: UIViewController {
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
        let viewPager = ViewPager(sizeConfiguration: .fillEqually(height: 60, spacing: 0))
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
        return viewPager
    }()
    private let loadingSpinner = UIActivityIndicatorView().then {
        $0.style = .large
        $0.color = .label
    }
    private let loadingLabel = UILabel().then {
        $0.text = String(localized: "subway.realtime.loading")
        $0.font = .godo(size: 16, weight: .regular)
        $0.textColor = .label
    }
    private lazy var loadingStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [loadingSpinner, loadingLabel])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.backgroundColor = .systemBackground
        return stackView
    }()
    private lazy var loadingView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.addSubview(loadingStackView)
        loadingStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.observeSubjects()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.startPolling()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        // Detect if the app is in the background
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        self.stopPolling()
    }
    
    private func setupUI() {
        self.view.addSubview(viewPager)
        self.view.addSubview(loadingView)
        self.viewPager.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        self.loadingView.snp.makeConstraints { make in
            make.edges.equalTo(viewPager)
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
            ))
        }).disposed(by: disposeBag)
        SubwayRealtimeData.shared.combinedRealtimeData.subscribe(onNext: {[weak self] data in
            guard
                data?.campusBlue != nil,
                data?.campusYellow != nil,
                data?.oidoBlue != nil,
                data?.oidoYellow != nil else { return }
            guard let self = self else { return }
            SubwayRealtimeData.shared.transferUp.onNext(self.processUpDirection(oidoBlue: data!.oidoBlue!, oidoYellow: data!.oidoYellow!))
            SubwayRealtimeData.shared.transferDown.onNext(self.processDownDirection(campusBlue: data!.campusBlue!, campusYellow: data!.campusYellow!, oidoYellow: data!.oidoYellow!))
        }).disposed(by: disposeBag)
        SubwayRealtimeData.shared.isLoading.subscribe(onNext: { isLoading in
            if (isLoading) {
                self.loadingView.isHidden = false
                self.loadingSpinner.startAnimating()
            } else {
                self.loadingView.isHidden = true
                self.loadingSpinner.stopAnimating()
            }
        }).disposed(by: disposeBag)
    }
    
    private func processUpDirection(
        oidoBlue: SubwayRealtimePageQuery.Data.Subway,
        oidoYellow: SubwayRealtimePageQuery.Data.Subway,
    ) -> [SubwayTransferItem] {
        let upRealtimeWithoutTransfer: [SubwayTransferItem] = oidoYellow.arrival.first(where: { $0.direction == "up" })?.entries.filter { entry in
            entry.isRealtime && entry.terminal.stationID < "K251"
        }.map{ entry in
            SubwayTransferItem(take: entry, transfer: nil)
        } ?? []
        let upTimetableToTransfer: [SubwayRealtimePageQuery.Data.Subway.Arrival.Entry] = oidoBlue.arrival.first(where: { $0.direction == "up" })?.entries ?? []
        let upRealtimeWithTransfer: [SubwayTransferItem] = oidoYellow.arrival.first(where: { $0.direction == "up" })?.entries.filter {
            entry in entry.terminal.stationID >= "K251" && entry.isRealtime
        }.map {
            entry in SubwayTransferItem(
                take: entry,
                transfer: upTimetableToTransfer.first { transfer in transfer.minutes > entry.minutes }
            )
        } ?? []
        return (upRealtimeWithoutTransfer + upRealtimeWithTransfer).sorted { $0.take.minutes < $1.take.minutes }
    }

    private func processDownDirection(
        campusBlue: SubwayRealtimePageQuery.Data.Subway,
        campusYellow: SubwayRealtimePageQuery.Data.Subway,
        oidoYellow: SubwayRealtimePageQuery.Data.Subway
    ) -> [SubwayTransferItem] {
        let downRealtimeWithoutTransfer: [SubwayTransferItem] = campusYellow.arrival.first(where: { $0.direction == "down" })?.entries.filter {
            entry in entry.terminal.stationID > "K258" && entry.isRealtime && entry.terminal.stationID.hasPrefix("K2")
        }.map {
            entry in SubwayTransferItem(
                take: entry,
                transfer: nil
            )
        } ?? []
        let downTimetableToTransfer: [SubwayRealtimePageQuery.Data.Subway.Arrival.Entry] = oidoYellow.arrival.first(where: { $0.direction == "down" })?.entries.filter {
                entry in entry.origin?.stationID == "K258"
        } ?? []
        let downRealtimeWithTransfer: [SubwayTransferItem] = campusBlue.arrival.first(where: { $0.direction == "down" })?.entries.filter {
            entry in entry.terminal.stationID == "K456"
        }.map { entry in
            let firstItemWithOutTransfer = findTakeTrain(compare: downRealtimeWithoutTransfer, target: entry)
            return SubwayTransferItem(
                take: entry,
                transfer: findTransferTrain(compare: downTimetableToTransfer, entry: entry, target: firstItemWithOutTransfer)
            )
        }.filter {
            entry in entry.transfer != nil
        } ?? []
        return (downRealtimeWithoutTransfer + downRealtimeWithTransfer).sorted { $0.take.minutes < $1.take.minutes }
    }
    
    private func findTakeTrain(compare: [SubwayTransferItem], target: SubwayRealtimePageQuery.Data.Subway.Arrival.Entry) -> SubwayTransferItem? {
        return compare.first(where: {$0.take.minutes > target.minutes})
    }
    
    private func findTransferTrain(compare: [SubwayRealtimePageQuery.Data.Subway.Arrival.Entry], entry: SubwayRealtimePageQuery.Data.Subway.Arrival.Entry, target: SubwayTransferItem?) -> SubwayRealtimePageQuery.Data.Subway.Arrival.Entry? {
        return compare.first(where: {
            if (target == nil) {
                return $0.minutes > entry.minutes + 20
            } else {
                return $0.minutes > entry.minutes + 20 && $0.minutes < target!.take.minutes + 20
            }
        })
    }
    
    private func fetchSubwayRealtimeData() {
        let today = Foundation.Date.now
        let component = Calendar.current.component(.weekday, from: today)
        let weekday = (component == 1 || component == 7) ? "weekends" : "weekdays"
        Task {
            let response = try? await Network.shared.client.fetch(query: SubwayRealtimePageQuery(weekday: weekday))
            if let data = response?.data {
                SubwayRealtimeData.shared.realtimeData.onNext(data.subway)
                SubwayRealtimeData.shared.isLoading.onNext(false)
                self.line4VC.reload()
                self.lineSuinVC.reload()
                self.transferVC.reload()
            }
        }
    }
    
    private func startPolling() {
        self.fetchSubwayRealtimeData()
        subscription = Observable<Int>.interval(.seconds(30), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.fetchSubwayRealtimeData()
            })
    }
    
    private func stopPolling() {
        subscription?.dispose()
    }
    
    private func showEntireTimetable(title: String.LocalizationValue, heading: SubwayHeadingEnum) {
        guard let nc = self.navigationController as? SubwayNC else { return }
        nc.moveToTimetableVC(timetableTitle: title, heading: heading)
    }
    
    private func checkTimetableAfterRealtime(departureTime: String, maxValue: Double) -> Bool {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let departureTime = dateFormatter.date(from: departureTime)
        let hour = calendar.component(.hour, from: departureTime!)
        let minute = calendar.component(.minute, from: departureTime!)
        let second = calendar.component(.second, from: departureTime!)
        let remainingTime = (hour * 3600 + minute * 60 + second) - (calendar.component(.hour, from: Date.now) * 3600 + calendar.component(.minute, from: Date.now) * 60 + calendar.component(.second, from: Date.now)) // in seconds
        return remainingTime > Int(maxValue * 60)
    }
    
    private func calculateRemainingTime(current: Foundation.Date, departureTime: String) -> Int {
        let splitTime = departureTime.split(separator: ":")
        var hour = Int(splitTime[0])!
        if hour < 4 {
            hour += 24
        }
        let minute = Int(splitTime[1])!
        let timeDelta = 60 * (hour - Calendar.current.component(.hour, from: current)) + (minute - Calendar.current.component(.minute, from: current))
        return timeDelta
    }
    
    @objc func appDidEnterBackground() { self.stopPolling() }
    @objc func appWillEnterForeground() { self.startPolling() }
}
