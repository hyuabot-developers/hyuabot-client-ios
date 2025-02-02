import UIKit
import RxSwift
import QueryAPI

class ReadingRoomVC: UIViewController {
    private let disposeBag = DisposeBag()
    private var subscription: Disposable?
    private let isLoading = BehaviorSubject<Bool>(value: false)
    private let refreshControl = UIRefreshControl()
    private let roomSubject = BehaviorSubject<[ReadingRoomPageQuery.Data.ReadingRoom]>(value: [])
    private lazy var readingRoomView = UITableView().then {
        $0.showsVerticalScrollIndicator = false
        $0.delegate = self
        $0.dataSource = self
        $0.register(ReadingRoomCellView.self, forCellReuseIdentifier: ReadingRoomCellView.reuseIdentifier)
        $0.refreshControl = refreshControl
        $0.refreshControl?.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
    }
    private let loadingSpinner = UIActivityIndicatorView().then {
        $0.style = .large
        $0.color = .label
    }
    private let loadingLabel = UILabel().then {
        $0.text = String(localized: "contact.database.loading")
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
    @objc private func refreshTableView(_ sender: UIRefreshControl) {
        self.fetchReadingRoomData()
    }
    
    private func setupUI() {
        self.navigationItem.title = String(localized: "tabbar.readingroom")
        self.view.addSubview(self.readingRoomView)
        self.view.addSubview(self.loadingView)
        self.readingRoomView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.loadingView.snp.makeConstraints { make in
            make.edges.equalTo(self.readingRoomView)
        }
    }
    
    private func startPolling() {
        self.isLoading.onNext(true)
        self.fetchReadingRoomData()
        subscription = Observable<Int>.interval(.seconds(30), scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                self.fetchReadingRoomData()
            })
    }
    
    private func stopPolling() {
        subscription?.dispose()
    }
    
    private func fetchReadingRoomData() {
        Network.shared.client.fetch(query: ReadingRoomPageQuery(campus: 2)) { result in
            self.isLoading.onNext(false)
            if case .success(let response) = result {
                self.refreshControl.endRefreshing()
                self.roomSubject.onNext(response.data?.readingRoom ?? [])
            } else if case .failure(let error) = result {

            }
        }
    }
    
    private func observeSubjects() {
        self.isLoading.subscribe(onNext: { isLoading in
            if (isLoading) {
                self.loadingView.isHidden = false
                self.loadingSpinner.startAnimating()
            } else {
                self.loadingView.isHidden = true
                self.loadingSpinner.stopAnimating()
            }
        }).disposed(by: disposeBag)
        self.roomSubject.subscribe(onNext: { [weak self] items in
            self?.readingRoomView.reloadData()
        }).disposed(by: disposeBag)
        observeUserDefaultsStringArray(forKey: "readingRoomNotificationArray")
            .subscribe(onNext: { updatedArray in
                self.readingRoomView.reloadData()
            })
            .disposed(by: disposeBag)
    }
}

extension ReadingRoomVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let items = try? self.roomSubject.value() else { return 0 }
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let items = try? self.roomSubject.value() else { return UITableViewCell() }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReadingRoomCellView.reuseIdentifier) as? ReadingRoomCellView else { return ReadingRoomCellView() }
        cell.setupUI(item: items[indexPath.row])
        return cell
    }
}
