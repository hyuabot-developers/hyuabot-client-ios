import UIKit
import RxSwift
import RealmSwift
import Api

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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.logScreenView(.contact)
        self.showCoachMarksIfNeeded()
    }

    private func showCoachMarksIfNeeded() {
        presentCoachMarks(
            pageId: "contact",
            items: [
                CoachMarkItem(
                    id: "contact.search",
                    targetView: searchController.searchBar,
                    title: String(localized: "coach.contact.search.title"),
                    message: String(localized: "coach.contact.search.message")
                ),
            ],
            shouldMarkAsShown: false,
            onComplete: { [weak self] in self?.showContactItemCoachMarkWhenReady() }
        )
    }

    private func showContactItemCoachMarkWhenReady() {
        if let items = try? searchResultSubject.value(), !items.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.presentContactItemCoachMark()
            }
            return
        }
        searchResultSubject
            .filter { !$0.isEmpty }
            .take(1)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self?.presentContactItemCoachMark()
                }
            })
            .disposed(by: disposeBag)
    }

    private func presentContactItemCoachMark() {
        presentCoachMarks(
            pageId: "contact",
            items: [
                CoachMarkItem(
                    id: "contact.item",
                    targetViewProvider: { [weak self] in
                        self?.searchResultView.cellForRow(at: IndexPath(row: 0, section: 0))
                    },
                    title: String(localized: "coach.contact.item.title"),
                    message: String(localized: "coach.contact.item.message")
                ),
            ],
            shouldMarkAsShown: false,
            onComplete: { CoachMarkManager.shared.markPageShown("contact") }
        )
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
        Task {
            let response = try? await Network.shared.client.fetch(query: ContactPageVersionQuery())
            if let data = response?.data {
                let previousVersion = UserDefaults.standard.string(forKey: "contactVersion") ?? ""
                if data.phonebook.version != previousVersion {
                    self.updateContact()
                }
            }
        }
        self.isLoading.onNext(false)
    }
    
    private func updateContact() {
        self.loadingLabel.text = String(localized: "contact.database.loading")
        Task {
            let response = try? await Network.shared.client.fetch(query: ContactPageQuery())
            if let data = response?.data {
                Contact.replaceAll(with: data.phonebook.categories.map { Contact.transform(from: $0) }.flatMap { $0 })
                UserDefaults.standard.set(data.phonebook.version, forKey: "contactVersion")
            }
        }
    }

    private func contact(at indexPath: IndexPath) -> Contact? {
        guard let items = try? self.searchResultSubject.value() else { return nil }
        guard items.indices.contains(indexPath.row) else { return nil }
        return items[indexPath.row]
    }

    private func callContact(_ contact: Contact) {
        let url = URL(string: "tel://\(contact.phoneNumber)")
        if let url, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private func copyContactPhone(_ contact: Contact) {
        UIPasteboard.general.string = contact.phoneNumber
        showToastMessage(
            image: UIImage(systemName: "doc.on.doc.fill"),
            message: String(format: String(localized: "toast.contact.phone.copied.%@"), contact.phoneNumber)
        )
    }

    private func shareContact(_ contact: Contact, sourceView: UIView?) {
        let text = String(format: String(localized: "contact.share.format.%@.%@"), contact.name, contact.phoneNumber)
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = sourceView ?? view
        activityVC.popoverPresentationController?.sourceRect = sourceView?.bounds ?? view.bounds
        present(activityVC, animated: true)
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
        guard let contact = contact(at: indexPath) else { return }
        AnalyticsManager.logSelect(.contactSelectRow, type: .listItem, name: contact.name)
        callContact(contact)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let contact = contact(at: indexPath) else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self, weak tableView] _ in
            let callAction = UIAction(
                title: String(localized: "contact.action.call"),
                image: UIImage(systemName: "phone.fill")
            ) { _ in
                self?.callContact(contact)
            }
            let copyAction = UIAction(
                title: String(localized: "contact.action.copy"),
                image: UIImage(systemName: "doc.on.doc")
            ) { _ in
                self?.copyContactPhone(contact)
            }
            let shareAction = UIAction(
                title: String(localized: "contact.action.share"),
                image: UIImage(systemName: "square.and.arrow.up")
            ) { _ in
                self?.shareContact(contact, sourceView: tableView?.cellForRow(at: indexPath))
            }
            return UIMenu(children: [callAction, copyAction, shareAction])
        }
    }
}
