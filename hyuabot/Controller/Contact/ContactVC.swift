import UIKit
import CoreData
import RxSwift
import QueryAPI

class ContactVC: UIViewController {
    private let disposeBag = DisposeBag()
    private let searchKeywordSubject = BehaviorSubject<String>(value: "")
    private let searchResultSubject = BehaviorSubject<[ContactPageQuery.Data.Contact.Datum]>(value: [])
    private lazy var searchController = UISearchController(searchResultsController: nil).then {
        $0.searchBar.do {
            $0.placeholder = String(localized: "map.building.search.placeholder")
            $0.directionalLayoutMargins = .init(top: 20, leading: 0, bottom: 0, trailing: 20)
            $0.searchTextField.backgroundColor = .systemBackground
        }
        $0.searchResultsUpdater = self
    }
    private lazy var searchResultView = UITableView().then {
        $0.showsVerticalScrollIndicator = false
        $0.isHidden = true
        $0.delegate = self
        $0.dataSource = self
        $0.register(ContactSearchEmptyCellView.self, forCellReuseIdentifier: ContactSearchEmptyCellView.reuseIdentifier)
        $0.register(ContactSearchResultCellView.self, forCellReuseIdentifier: ContactSearchResultCellView.reuseIdentifier)
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
        
    }
    
    private func updateContact() {
        Network.shared.client.fetch(query: ContactPageQuery()) { result in
            if case let .success(response) = result {

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
        guard let items = try? self.searchResultSubject.value() else { return 0 }
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
