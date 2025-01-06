import UIKit
import RxSwift
import QueryAPI

class ShuttleRealtimeVC: UIViewController {
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private let disposeBag = DisposeBag()
    private var subscription: Disposable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.startPolling()
        // Detect if the app is in the background
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        self.stopPolling()
    }
    
    @objc func appDidEnterBackground() { self.stopPolling() }
    @objc func appWillEnterForeground() { self.startPolling() }
    
    func startPolling() {
        fetchShuttleRealtimeData()
        subscription = Observable<Int>.interval(.seconds(10), scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                self.fetchShuttleRealtimeData()
            })
    }
    
    func stopPolling() {
        subscription?.dispose()
    }
    
    func fetchShuttleRealtimeData() {
        let now = Date.now
        let timeFormatter = DateFormatter().then { $0.dateFormat = "HH:mm" }
        let dateTimeFormatter = DateFormatter().then { $0.dateFormat = "yyyy-MM-dd HH:mm" }
        let dataDelegate = ShuttleRealtimeData.shared
        Network.shared.client.fetch(query: ShuttleRealtimePageQuery(shuttleStart: timeFormatter.string(from: now), shuttleDateTime: dateTimeFormatter.string(from: now))) { result in
            if case .success(let response) = result {
                dataDelegate.shuttleRealtimeData.onNext(response.data)
            }
        }
    }
}
