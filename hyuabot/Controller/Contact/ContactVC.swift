import UIKit
import RxSwift
import RealmSwift
import QueryAPI

class ContactVC: UIViewController {
    private let disposeBag = DisposeBag()
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
    
    deinit {
        notificationToken?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.updateContact()
        self.observeSubjects()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func setupUI() {
        self.view.addSubview(self.searchResultView)
        self.navigationItem.do {
            $0.title = String(localized: "tabbar.contact")
            $0.searchController = self.searchController
            $0.hidesSearchBarWhenScrolling = false
        }
        self.searchResultView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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
            self?.searchResultSubject.onNext(allContacts.filter { $0.campusID == campusID })
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
            })
        }).disposed(by: disposeBag)
    }
    
    private func updateContact() {
        Network.shared.client.fetch(query: ContactPageQuery()) { result in
            if case let .success(response) = result {
                if let data = response.data {
                    Contact.replaceAll(with: data.contact.data.map { Contact.transform(from: $0) })
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
}
