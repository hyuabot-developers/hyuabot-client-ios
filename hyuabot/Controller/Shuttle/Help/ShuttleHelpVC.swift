//
//  ShuttleHelpVC.swift
//  hyuabot
//

import SnapKit
import UIKit

class ShuttleHelpVC: UIViewController {
    private let titleItems: [String.LocalizationValue] = [
        "shuttle.help.title1",
        "shuttle.help.title2",
        "shuttle.help.title3",
        "shuttle.help.title4",
        "shuttle.help.title5"
    ]
    private let contentItems: [String.LocalizationValue] = [
        "shuttle.help.content1",
        "shuttle.help.content2",
        "shuttle.help.content3",
        "shuttle.help.content4",
        "shuttle.help.content5"
    ]
    private lazy var helpTableView = UITableView().then {
        $0.dataSource = self
        $0.delegate = self
        $0.register(ShuttleHelpItemCell.self, forCellReuseIdentifier: ShuttleHelpItemCell.reuseIdentifier)
        $0.isScrollEnabled = false
        $0.backgroundColor = .clear
        $0.separatorStyle = .none
        $0.rowHeight = UITableView.automaticDimension
        $0.estimatedRowHeight = 100
    }

    private var helpTableHeightConstraint: Constraint?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.shuttleHelp)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        let sheet = HYUSheetView(title: String(localized: "shuttle.help"))
        view.addSubview(sheet)
        sheet.contentStack.addArrangedSubview(helpTableView)
        sheet.snp.makeConstraints { $0.edges.equalToSuperview() }
        helpTableView.snp.makeConstraints { make in
            helpTableHeightConstraint = make.height.equalTo(0).constraint
        }
        helpTableView.reloadData()
        view.layoutIfNeeded()
        updateHelpTableHeight()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHelpTableHeight()
    }

    private func updateHelpTableHeight() {
        helpTableView.layoutIfNeeded()
        helpTableHeightConstraint?.update(offset: helpTableView.contentSize.height)
    }
}

extension ShuttleHelpVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        5
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView
            .dequeueReusableCell(withIdentifier: ShuttleHelpItemCell.reuseIdentifier) as? ShuttleHelpItemCell ?? ShuttleHelpItemCell()
        cell.setupUI(title: titleItems[indexPath.row], content: contentItems[indexPath.row])
        return cell
    }
}
