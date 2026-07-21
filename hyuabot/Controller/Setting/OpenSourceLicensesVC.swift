//
//  OpenSourceLicensesVC.swift
//  hyuabot
//

import SafariServices
import UIKit

private struct OpenSourceLicense: Decodable {
    let name: String
    let version: String
    let source: String
    let licenseText: String
}

final class OpenSourceLicensesVC: UITableViewController {
    private let licenses: [OpenSourceLicense]
    private var filteredLicenses: [OpenSourceLicense]
    private let searchController = UISearchController(searchResultsController: nil)

    init() {
        let loadedLicenses = Self.loadLicenses()
        licenses = loadedLicenses
        filteredLicenses = loadedLicenses
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "setting.open_source_licenses")
        navigationItem.largeTitleDisplayMode = .never

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = String(localized: "licenses.search")
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "OpenSourceLicenseCell")
        tableView.estimatedRowHeight = 68
        tableView.rowHeight = UITableView.automaticDimension
        tableView.accessibilityIdentifier = "setting.open_source_licenses.list"
        updateEmptyState()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredLicenses.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OpenSourceLicenseCell", for: indexPath)
        let license = filteredLicenses[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = license.name
        content.secondaryText = license.version
        content.textProperties.font = .preferredFont(forTextStyle: .body)
        content.textProperties.numberOfLines = 2
        content.secondaryTextProperties.font = .preferredFont(forTextStyle: .caption1)
        content.secondaryTextProperties.numberOfLines = 1
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(
            OpenSourceLicenseDetailVC(license: filteredLicenses[indexPath.row]),
            animated: true
        )
    }

    private func updateEmptyState() {
        guard filteredLicenses.isEmpty else {
            tableView.backgroundView = nil
            return
        }

        let label = UILabel()
        label.text = String(localized: licenses.isEmpty ? "licenses.empty" : "licenses.no_results")
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .body)
        label.textAlignment = .center
        label.numberOfLines = 0
        tableView.backgroundView = label
    }

    private static func loadLicenses() -> [OpenSourceLicense] {
        guard let url = Bundle.main.url(forResource: "OpenSourceLicenses", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let licenses = try? PropertyListDecoder().decode([OpenSourceLicense].self, from: data)
        else { return [] }

        return licenses.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

extension OpenSourceLicensesVC: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        filteredLicenses = query.isEmpty
            ? licenses
            : licenses.filter { $0.name.localizedCaseInsensitiveContains(query) }
        tableView.reloadData()
        updateEmptyState()
    }
}

private final class OpenSourceLicenseDetailVC: UIViewController {
    private let license: OpenSourceLicense
    private let textView = UITextView()

    init(license: OpenSourceLicense) {
        self.license = license
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = license.name
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never

        if URL(string: license.source) != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: String(localized: "licenses.source"),
                style: .plain,
                target: self,
                action: #selector(openSource)
            )
        }

        textView.isEditable = false
        textView.isSelectable = true
        textView.alwaysBounceVertical = true
        textView.adjustsFontForContentSizeCategory = true
        textView.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(
            for: .monospacedSystemFont(ofSize: 13, weight: .regular)
        )
        textView.text = license.licenseText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 16, bottom: 32, right: 16)
        textView.accessibilityIdentifier = "setting.open_source_licenses.detail"
        view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    @objc
    private func openSource() {
        guard let url = URL(string: license.source) else { return }
        present(SFSafariViewController(url: url), animated: true)
    }
}
