//
//  OpenSourceLicensesVC.swift
//  hyuabot
//

import SnapKit
import UIKit

final class OpenSourceLicensesVC: UIViewController, SettingsStyledScreen {
    private let licenses = OpenSourceLicenseCatalog.load()
    private let searchController = UISearchController(searchResultsController: nil)
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let introContainer = UIView()
    private let introLabel = UILabel()
    private let emptyContainer = UIView()
    private let emptyLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "setting.open_source_licenses")
        navigationItem.backButtonTitle = String(localized: "licenses.back")
        SettingsNavigationStyle.apply(to: self, largeTitle: true)
        view.backgroundColor = SettingsStyle.Color.background
        configureSearch()
        configureContent()
        setContentScrollView(scrollView, for: .top)
        rebuildSections(query: "")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SettingsNavigationStyle.screenWillAppear(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SettingsNavigationStyle.screenWillDisappear(self)
    }

    private func configureSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = String(localized: "licenses.search")
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func configureContent() {
        scrollView.accessibilityIdentifier = "setting.open_source_licenses.list"
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .onDrag
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        contentStack.axis = .vertical
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
            make.bottom.equalTo(scrollView.contentLayoutGuide).inset(48)
        }
        introLabel.text = String(format: String(localized: "licenses.intro.%lld"), licenses.count)
        introLabel.font = SettingsStyle.font(13.5)
        introLabel.textColor = SettingsStyle.Color.secondaryText
        introLabel.numberOfLines = 0
        introLabel.isAccessibilityElement = true
        introContainer.addSubview(introLabel)
        introLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.trailing.equalToSuperview().inset(32)
            make.bottom.equalToSuperview()
        }
        emptyContainer.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(32) }
        emptyLabel.font = SettingsStyle.font(15)
        emptyLabel.textColor = SettingsStyle.Color.secondaryText
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
    }

    private func rebuildSections(query: String) {
        contentStack.arrangedSubviews.forEach { item in
            contentStack.removeArrangedSubview(item)
            item.removeFromSuperview()
        }
        let filtered = OpenSourceLicenseCatalog.filter(licenses, query: query)
        introLabel.isHidden = !query.isEmpty
        contentStack.addArrangedSubview(introContainer)
        if filtered.isEmpty {
            emptyLabel.text = String(localized: licenses.isEmpty ? "licenses.empty" : "licenses.no_results")
            emptyLabel.isHidden = false
            contentStack.addArrangedSubview(emptyContainer)
            return
        }
        emptyLabel.isHidden = true
        for group in OpenSourceLicenseCatalog.groups(for: filtered) {
            let card = SettingsCardView()
            for license in group.licenses {
                let row = SettingsRowView(
                    symbolName: nil,
                    tileColor: nil,
                    title: license.name,
                    subtitle: "v\(license.version)",
                    accessory: .chevron,
                    minHeight: 56,
                    verticalPadding: 8,
                    subtitleMonospacedDigits: true
                )
                row.onTap = { [weak self] in self?.showDetail(for: license) }
                card.addRow(row, separatorInset: 0)
            }
            let count = String(format: String(localized: "licenses.group.count.%lld"), group.licenses.count)
            contentStack.addArrangedSubview(SettingsSectionView(
                header: group.kind.groupTitle,
                content: card,
                trailingHeader: count
            ))
        }
    }

    private func showDetail(for license: OpenSourceLicenseEntry) {
        let detail = OpenSourceLicenseDetailVC(license: license)
        detail.hidesBottomBarWhenPushed = hidesBottomBarWhenPushed
        navigationController?.pushViewController(detail, animated: true)
    }
}

extension OpenSourceLicensesVC: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        rebuildSections(query: query)
    }
}
