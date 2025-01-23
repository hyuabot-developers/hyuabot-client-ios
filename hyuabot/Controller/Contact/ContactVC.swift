import UIKit
import RxSwift
import RealmSwift
import QueryAPI

class ContactVC: UIViewController {
    private let disposeBag = DisposeBag()
    private let isLoading = BehaviorSubject<Bool>(value: false)
    private let searchKeywordSubject = BehaviorSubject<String>(value: "")
    private let contactSubject = BehaviorSubject<[Contact]>(value: [])
    private let searchResultSubject = BehaviorSubject<[Contact]>(value: [])
    private var notificationToken: NotificationToken?
    private lazy var searchController = UISearchController(searchResultsController: nil).then {
        $0.searchBar.do {
            $0.placeholder = String(localized: "contact.search.placeholder")
            $0.directionalLayoutMargins = .init(top: 20, leading: 0, bottom: 0, trailing: 20)
            $0.searchTextField.backgroundColor = .systemBackground
        }
        $0.searchResultsUpdater = self
        $0.hidesNavigationBarDuringPresentation = false
    }
    private lazy var searchResultView = UITableView().then {
        $0.showsVerticalScrollIndicator = false
        $0.delegate = self
        $0.dataSource = self
        $0.register(ContactSearchEmptyCellView.self, forCellReuseIdentifier: ContactSearchEmptyCellView.reuseIdentifier)
        $0.register(ContactSearchResultCellView.self, forCellReuseIdentifier: ContactSearchResultCellView.reuseIdentifier)
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
    
    deinit {
        notificationToken?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.updateContactVerion()
        self.observeSubjects()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func setupUI() {
        self.view.addSubview(self.searchResultView)
        self.view.addSubview(loadingView)
        self.navigationItem.do {
            $0.title = String(localized: "tabbar.contact")
            $0.searchController = self.searchController
            $0.hidesSearchBarWhenScrolling = false
        }
        self.searchResultView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.loadingView.snp.makeConstraints { make in
            make.edges.equalTo(searchResultView)
        }
    }
    
    private func observeSubjects() {
        notificationToken = Database.shared.database.objects(Contact.self).observe { [weak self] changes in
            switch changes {
            case .initial(let results):
                self?.contactSubject.onNext(results.map { $0 })
            case .update(_, let deletions, let insertions, let modifications):
                if deletions.count > 0 || insertions.count > 0 || modifications.count > 0 {
                    self?.contactSubject.onNext(Database.shared.database.objects(Contact.self).map { $0 })
                }
            default:
                break
            }
        }
        self.contactSubject.subscribe(onNext: { [weak self] allContacts in
            let campusID = UserDefaults.standard.integer(forKey: "campusID") == 0 ? 2 : UserDefaults.standard.integer(forKey: "campusID")
            self?.searchResultSubject.onNext(allContacts.filter { $0.campusID == campusID }.sorted { $0.phoneNumber < $1.phoneNumber })
        }).disposed(by: disposeBag)
        self.searchResultSubject.subscribe(onNext: { [weak self] contacts in
            self?.searchResultView.reloadData()
        }).disposed(by: disposeBag)
        self.searchKeywordSubject.subscribe(onNext: { [weak self] searchKeyword in
            guard let allContacts = try? self?.contactSubject.value() else { return }
            let campusID = UserDefaults.standard.integer(forKey: "campusID") == 0 ? 2 : UserDefaults.standard.integer(forKey: "campusID")
            self?.searchResultSubject.onNext(allContacts.filter {
                ($0.name.contains(searchKeyword) || $0.phoneNumber.contains(searchKeyword) || searchKeyword.isEmpty) &&
                $0.campusID == campusID
            }.sorted { $0.phoneNumber < $1.phoneNumber })
        }).disposed(by: disposeBag)
        self.isLoading.subscribe(onNext: { isLoading in
            if (isLoading) {
                self.loadingView.isHidden = false
                self.loadingSpinner.startAnimating()
            } else {
                self.loadingView.isHidden = true
                self.loadingSpinner.stopAnimating()
            }
        }).disposed(by: disposeBag)
    }
    
    private func updateContactVerion() {
        self.loadingLabel.text = String(localized: "contact.version.loading")
        self.isLoading.onNext(true)
        Network.shared.client.fetch(query: ContactPageVersionQuery()) { result in
            if case let .success(response) = result {
                if let data = response.data {
                    let previousVersion = UserDefaults.standard.string(forKey: "contactVersion") ?? ""
                    if data.contact.version != previousVersion {
                        self.updateContact()
                    }
                }
            }
        }
        self.isLoading.onNext(false)
    }
    
    private func updateContact() {
        self.loadingLabel.text = String(localized: "contact.database.loading")
        Network.shared.client.fetch(query: ContactPageQuery()) { result in
            if case let .success(response) = result {
                if let data = response.data {
                    Contact.replaceAll(with: data.contact.data.map { Contact.transform(from: $0) })
                    UserDefaults.standard.set(data.contact.version, forKey: "contactVersion")
                }
            }
        }
    }
}

extension ContactVC: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchKeyword = searchController.searchBar.text else { return }
        self.searchKeywordSubject.onNext(searchKeyword)
    }
}

extension ContactVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let items = try? self.searchResultSubject.value() else { return 1 }
        return items.isEmpty ? 1 : items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let items = try? self.searchResultSubject.value() else { return UITableViewCell() }
        if items.isEmpty {
            return tableView.dequeueReusableCell(withIdentifier: ContactSearchEmptyCellView.reuseIdentifier, for: indexPath)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactSearchResultCellView.reuseIdentifier, for: indexPath) as! ContactSearchResultCellView
        cell.setupUI(item: items[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let items = try? self.searchResultSubject.value() else { return }
        guard !items.isEmpty else { return }
        let contact = items[indexPath.row]
        let url = URL(string: "tel://\(contact.phoneNumber)")
        if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
