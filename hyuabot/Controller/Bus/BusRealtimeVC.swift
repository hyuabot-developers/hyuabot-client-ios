import UIKit
import RxSwift

class BusRealtimeVC: UIViewController {
    private let cityBusTabVC = BusRealtimeTabVC()
    private let seoulBusTabVC = BusRealtimeTabVC()
    private let suwonBusTabVC = BusRealtimeTabVC()
    private let otherBusTabVC = BusRealtimeTabVC()
    private var subscription: Disposable?
    private lazy var helpButton = UIButton().then {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .hanyangGreen
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "questionmark.circle")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        $0.configuration = config
        $0.addTarget(self, action: #selector(openHelpVC), for: .touchUpInside)
    }
    private lazy var viewPager: ViewPager = {
        let viewPager = ViewPager(sizeConfiguration: .fixed(width: 125, height: 60, spacing: 0))
        // Add the content pages to the view pager
        viewPager.contentView.pages = [
            cityBusTabVC.view,
            seoulBusTabVC.view,
            suwonBusTabVC.view,
            otherBusTabVC.view
        ]
        // Add the tab titles to the view pager
        viewPager.tabView.tabs = [
            TabItem(title: String(localized: "bus.tab.city")),
            TabItem(title: String(localized: "bus.tab.seoul")),
            TabItem(title: String(localized: "bus.tab.suwon")),
            TabItem(title: String(localized: "bus.tab.other"))
        ]
        return viewPager
    }()

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
        self.view.addSubview(helpButton)
        self.viewPager.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        self.helpButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(20)
            make.width.height.equalTo(50)
        }
    }
    
    private func observeSubjects() {
        
    }
    
    private func fetchBusRealtimeData() {
        
    }
    
    private func startPolling() {
        self.fetchBusRealtimeData()
        subscription = Observable<Int>.interval(.seconds(30), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.fetchBusRealtimeData()
            })
    }
    
    private func stopPolling() {
        subscription?.dispose()
    }
    
    @objc func appDidEnterBackground() { self.stopPolling() }
    @objc func appWillEnterForeground() { self.startPolling() }
    @objc func openHelpVC() {}
}
