import UIKit
import RxSwift
import QueryAPI

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
        $0.text = String(localized: "bus.realtime.loading")
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
        SubwayRealtimeData.shared.realtimeData.subscribe(onNext: { [weak self] data in
            var line4Up = [SubwayRealtimeItem]()
            var line4Down = [SubwayRealtimeItem]()
            var lineSuinUp = [SubwayRealtimeItem]()
            var lineSuinDown = [SubwayRealtimeItem]()
            // Station Data
            let line4Item = data.first { $0.id == "K449" }
            let lineSuinItem = data.first { $0.id == "K251" }
            // Combine Up and Down
            line4Item?.realtime.up.forEach { line4Up.append(SubwayRealtimeItem(realtimeUp: $0))}
            line4Item?.realtime.down.forEach { line4Down.append(SubwayRealtimeItem(realtimeDown: $0))}
            lineSuinItem?.realtime.up.forEach { lineSuinUp.append(SubwayRealtimeItem(realtimeUp: $0))}
            lineSuinItem?.realtime.down.forEach { lineSuinDown.append(SubwayRealtimeItem(realtimeDown: $0))}
            // Sort by time
            line4Up.sort { $0.realtimeUp?.time ?? 0 < $1.realtimeUp?.time ?? 0 }
            line4Down.sort { $0.realtimeDown?.time ?? 0 < $1.realtimeDown?.time ?? 0 }
            lineSuinUp.sort { $0.realtimeUp?.time ?? 0 < $1.realtimeUp?.time ?? 0 }
            lineSuinDown.sort { $0.realtimeDown?.time ?? 0 < $1.realtimeDown?.time ?? 0 }
            // Get max minute from realtime data
            let line4UpMax = line4Up.max { $0.realtimeUp?.time ?? 0 < $1.realtimeUp?.time ?? 0 }?.realtimeUp?.time ?? 0
            let line4DownMax = line4Down.max { $0.realtimeDown?.time ?? 0 < $1.realtimeDown?.time ?? 0 }?.realtimeDown?.time ?? 0
            let lineSuinUpMax = lineSuinUp.max { $0.realtimeUp?.time ?? 0 < $1.realtimeUp?.time ?? 0 }?.realtimeUp?.time ?? 0
            let lineSuinDownMax = lineSuinDown.max { $0.realtimeDown?.time ?? 0 < $1.realtimeDown?.time ?? 0 }?.realtimeDown?.time ?? 0
            line4Item?.timetable.up.filter {
                self?.calculateRemainingTime(departureTime: $0.time, maxValue: line4UpMax) ?? false
            }.forEach {
                line4Up.append(SubwayRealtimeItem(timetableUp: $0))
            }
            line4Item?.timetable.down.filter {
                self?.calculateRemainingTime(departureTime: $0.time, maxValue: line4DownMax) ?? false
            }.forEach {
                line4Down.append(SubwayRealtimeItem(timetableDown: $0))
            }
            lineSuinItem?.timetable.up.filter {
                self?.calculateRemainingTime(departureTime: $0.time, maxValue: lineSuinUpMax) ?? false
            }.forEach {
                lineSuinUp.append(SubwayRealtimeItem(timetableUp: $0))
            }
            lineSuinItem?.timetable.down.filter {
                self?.calculateRemainingTime(departureTime: $0.time, maxValue: lineSuinDownMax) ?? false
            }.forEach {
                lineSuinDown.append(SubwayRealtimeItem(timetableDown: $0))
            }
            // Update Realtime Data
            SubwayRealtimeData.shared.line4Up.onNext(line4Up)
            SubwayRealtimeData.shared.line4Down.onNext(line4Down)
            SubwayRealtimeData.shared.lineSuinUp.onNext(lineSuinUp)
            SubwayRealtimeData.shared.lineSuinDown.onNext(lineSuinDown)
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
    
    private func fetchSubwayRealtimeData() {
        let timeFormatter = DateFormatter().then {
            $0.dateFormat = "HH:mm"
        }
        let time = timeFormatter.string(from: Date.now)
        Network.shared.client.fetch(query: SubwayRealtimePageQuery(start: time)) { result in
            if case .success(let data) = result {
                SubwayRealtimeData.shared.realtimeData.onNext(data.data?.subway ?? [])
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
    
    private func showEntireTimetable(title: String.LocalizationValue) {

    }
    
    private func calculateRemainingTime(departureTime: String, maxValue: Double) -> Bool {
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
    
    @objc func appDidEnterBackground() { self.stopPolling() }
    @objc func appWillEnterForeground() { self.startPolling() }
}
