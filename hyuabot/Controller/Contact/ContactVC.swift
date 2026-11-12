//
//  ContactVC.swift
//  hyuabot
//

import Api
import RealmSwift
import SnapKit
import UIKit

final class ContactVC: UIViewController, SettingsStyledScreen {
    var allEntries: [ContactEntry] = []
    var query = ""
    var selectedDepartment: String?
    var sections: [ContactSection] = []
    var isLoading = false
    var pendingItemCoachMark = false
    var loadsContactsOnLoad = true
    private var notificationToken: NotificationToken?

    let campusPill = ContactCampusPillView()
    let searchField = ContactSearchFieldView()
    let chipBar = ContactFilterChipBarView()
    let tableView = UITableView(frame: .zero, style: .grouped)
    let loadingView = ContactLoadingView()
    let summaryView = ContactSummaryView()
    let footerView = ContactListFooterView()
    private let headerView = UIView()

    deinit { notificationToken?.invalidate() }

    var campusID: Int {
        let value = UserDefaults.standard.integer(forKey: "campusID")
        return value == 0 ? 2 : value
    }

    var campusName: String {
        String(localized: campusID == 1 ? "campus.seoul" : "campus.erica")
    }

    var isFiltering: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedDepartment != nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SettingsStyle.Color.background
        SettingsNavigationStyle.apply(to: self, largeTitle: true)
        navigationItem.title = String(localized: "contact.title")
        let pillItem = UIBarButtonItem(customView: campusPill)
        if #available(iOS 26.0, *) { pillItem.hidesSharedBackground = true }
        navigationItem.rightBarButtonItem = pillItem
        campusPill.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        layoutViews()
        searchField.onTextChange = { [weak self] text in
            self?.query = text
            self?.applyFilter()
        }
        chipBar.onSelect = { [weak self] department in
            self?.selectedDepartment = department
            self?.applyFilter()
        }
        if loadsContactsOnLoad {
            observeContacts()
            updateContactVersion()
        }
    }

    @objc
    private func openSettings() {
        navigationController?.pushViewController(SettingVC(), animated: true)
    }

    func layoutViews() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        setContentScrollView(tableView, for: .top)
        let searchWrapper = UIView()
        let summaryWrapper = UIView()
        searchWrapper.addSubview(searchField)
        searchField.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
        summaryWrapper.addSubview(summaryView)
        summaryView.snp.makeConstraints { $0.edges.equalToSuperview() }
        let headerStack = UIStackView(arrangedSubviews: [searchWrapper, chipBar, summaryWrapper])
        headerStack.axis = .vertical
        headerStack.spacing = 12
        headerStack.setCustomSpacing(4, after: chipBar)
        headerView.addSubview(headerStack)
        headerStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = SettingsStyle.Color.background
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 0
        tableView.sectionFooterHeight = .leastNonzeroMagnitude
        tableView.keyboardDismissMode = .onDrag
        tableView.estimatedRowHeight = 64
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset.bottom = 32
        tableView.showsVerticalScrollIndicator = false
        tableView.register(ContactSearchResultCellView.self, forCellReuseIdentifier: ContactSearchResultCellView.reuseIdentifier)
        tableView.register(ContactSearchEmptyCellView.self, forCellReuseIdentifier: ContactSearchEmptyCellView.reuseIdentifier)
        tableView.register(ContactSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: "ContactSectionHeaderView")
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.contactLayoutAccessoryViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        SettingsNavigationStyle.screenWillAppear(self)
        campusPill.setCampusName(campusName)
        reloadEntries()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SettingsToastView.dismiss(in: navigationController?.view ?? view)
        SettingsNavigationStyle.screenWillDisappear(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.contact)
        showCoachMarksIfNeeded()
    }

    func observeContacts() {
        notificationToken = Database.shared.database.objects(Contact.self).observe { [weak self] _ in
            self?.reloadEntries()
        }
    }

    func reloadEntries() {
        let other = String(localized: "contact.filter.other")
        let currentCampusID = campusID
        allEntries = ContactDirectory.sortedByPhone(Contact.fetchAll().filter { $0.campusID == currentCampusID }.map {
            let parsedName = ContactDirectory.split(name: $0.name)
            return ContactEntry(
                id: $0.id,
                department: parsedName.department ?? other,
                name: parsedName.title,
                phoneNumber: $0.phoneNumber
            )
        })
        let departments = ContactDirectory.departments(in: allEntries)
        if let selectedDepartment, !departments.contains(selectedDepartment) { self.selectedDepartment = nil }
        chipBar.setDepartments(departments, selected: selectedDepartment)
        applyFilter()
    }

    func applyFilter() {
        let filtered = ContactDirectory.filter(allEntries, query: query, department: selectedDepartment)
        sections = ContactDirectory.sections(for: filtered)
        summaryView.setText(isFiltering
            ? String(format: String(localized: "contact.summary.results.%lld"), filtered.count)
            : String(format: String(localized: "contact.summary.all.%@.%lld"), campusName, allEntries.count))
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = isLoading ? loadingView : ((isFiltering || sections.isEmpty) ? nil : footerView)
        footerView.setVersion(UserDefaults.standard.string(forKey: "contactVersion"))
        tableView.reloadData()
        view.setNeedsLayout()
        if pendingItemCoachMark, !sections.isEmpty {
            pendingItemCoachMark = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in self?.presentContactItemCoachMark() }
        }
    }

    func resetSearch() {
        query = ""
        selectedDepartment = nil
        searchField.setText("")
        chipBar.setDepartments(ContactDirectory.departments(in: allEntries), selected: nil)
        applyFilter()
    }

    func setLoading(_ loading: Bool, message: String) {
        isLoading = loading
        loadingView.setMessage(message)
        tableView.tableFooterView = loading ? loadingView : ((isFiltering || sections.isEmpty) ? nil : footerView)
        tableView.contactLayoutAccessoryViews()
        tableView.reloadData()
    }

    func updateContactVersion() {
        setLoading(true, message: String(localized: "contact.loading.checking"))
        Task {
            let response = try? await Network.shared.client.fetch(query: ContactPageVersionQuery())
            if let data = response?.data {
                let isEmpty = Database.shared.database.objects(Contact.self).isEmpty
                if isEmpty || data.phonebook.version != UserDefaults.standard.string(forKey: "contactVersion") {
                    updateContact(version: data.phonebook.version)
                } else {
                    setLoading(false, message: "")
                }
            } else {
                setLoading(false, message: "")
            }
        }
    }

    func updateContact(version: String) {
        setLoading(true, message: String(format: String(localized: "contact.loading.downloading.%@"), version))
        Task {
            let response = try? await Network.shared.client.fetch(query: ContactPageQuery())
            if let data = response?.data {
                let contacts = await Contact.transformTranslated(from: data.phonebook.categories)
                await Contact.replaceAll(with: contacts)
                UserDefaults.standard.set(data.phonebook.version, forKey: "contactVersion")
            }
            setLoading(false, message: "")
            applyFilter()
        }
    }
}

extension ContactVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { sections.isEmpty ? 1 : sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections.isEmpty ? (isLoading ? 0 : 1) : sections[section].entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !sections.isEmpty else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ContactSearchEmptyCellView.reuseIdentifier,
                for: indexPath
            ) as? ContactSearchEmptyCellView else { return UITableViewCell() }
            if isFiltering {
                let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
                let title = trimmedQuery.isEmpty ? (selectedDepartment ?? "") : trimmedQuery
                let action = StateAction(title: String(localized: "contact.empty.reset")) { [weak self] in
                    self?.resetSearch()
                }
                cell.configure(.empty(
                    title: String(format: String(localized: "contact.empty.title.%@"), title),
                    message: String(localized: "contact.empty.message"),
                    symbolName: "magnifyingglass",
                    action: action
                ))
            } else {
                cell.configure(.empty(message: String(localized: "contact.search.empty")))
            }
            return cell
        }
        let section = sections[indexPath.section]
        let entry = section.entries[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ContactSearchResultCellView.reuseIdentifier,
            for: indexPath
        ) as? ContactSearchResultCellView else { return UITableViewCell() }
        cell.configure(entry: entry, query: query, isFirst: indexPath.row == 0, isLast: indexPath.row == section.entries.count - 1)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !sections.isEmpty,
              let header = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: "ContactSectionHeaderView"
              ) as? ContactSectionHeaderView else { return nil }
        let value = sections[section]
        header.configure(department: value.department, count: value.entries.count, isFirstSection: section == 0)
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { sections.isEmpty ? .leastNormalMagnitude : UITableView.automaticDimension }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard sections.indices.contains(indexPath.section),
              sections[indexPath.section].entries.indices.contains(indexPath.row) else { return }
        let entry = sections[indexPath.section].entries[indexPath.row]
        AnalyticsManager.logSelect(.contactSelectRow, type: .listItem, name: entry.name)
        callContact(entry)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard sections.indices.contains(indexPath.section),
              sections[indexPath.section].entries.indices.contains(indexPath.row) else { return nil }
        let entry = sections[indexPath.section].entries[indexPath.row]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self, weak tableView] _ in
            let call = UIAction(
                title: String(localized: "contact.action.call"),
                image: UIImage(systemName: "phone.fill")
            ) { [weak self] _ in self?.callContact(entry) }
            let copy = UIAction(
                title: String(localized: "contact.action.copy"),
                image: UIImage(systemName: "doc.on.doc")
            ) { [weak self] _ in self?.copyPhone(entry) }
            let share = UIAction(
                title: String(localized: "contact.action.share"),
                image: UIImage(systemName: "square.and.arrow.up")
            ) { [weak self] _ in
                self?.shareContact(entry, sourceView: tableView?.cellForRow(at: indexPath))
            }
            return UIMenu(children: [call, copy, share])
        }
    }
}
