//
//  BusLogVC.swift
//  hyuabot
//

import Api
import UIKit

class BusLogVC: UIViewController {
    let stopID: Int32
    let routes: [Int32]
    private let routeNames: [String]
    private let stopName: String
    private var logs: [[String]] = [[], [], []]
    private var expanded = false
    private var layout = BusDepartureLogLayout(columns: [[], [], []], hiddenPastCount: 0)
    private let foldLabel = UILabel()
    private let expandButton = BusLogFoldButton(type: .system)
    private let foldRow = BusLogFoldStackView()
    private let badges = UIStackView()
    private let columns = UIStackView()
    private var tables: [UITableView] = []
    private var loading = true
    private let dates = [-7, -2, -1].map { offset in
        BusDisplayLogic.serviceCalendar.date(byAdding: .day, value: offset, to: .now) ?? .now
    }

    required init(stopID: Int32, routes: [Int32], routeNames: [String] = [], stopName: String = "") {
        self.stopID = stopID
        self.routes = routes
        self.routeNames = routeNames
        self.stopName = stopName
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.busDepartureLog)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchLog()
    }

    private func setupUI() {
        view.backgroundColor = SettingsStyle.Color.busSheetBackground
        let title = UILabel()
        title.accessibilityIdentifier = "bus.log.title"
        title.attributedText = SettingsStyle.attributedText(
            String(localized: "bus.log.title"), font: SettingsStyle.font(20, bold: true),
            color: SettingsStyle.Color.text, lineHeight: 26
        )
        let header = UIStackView(arrangedSubviews: [title])
        header.alignment = .center
        header.snp.makeConstraints { make in make.height.equalTo(52) }
        badges.spacing = 6
        badges.alignment = .center
        for route in routeNames {
            let badge = BusRouteBadgeView(size: .small)
            badge.configure(route: route)
            badges.addArrangedSubview(badge)
        }
        let name = UILabel()
        name.font = SettingsStyle.font(13)
        name.textColor = SettingsStyle.Color.secondaryText
        name.numberOfLines = 0
        name.setKoreanTranslatedText(stopName)
        badges.addArrangedSubview(name)
        badges.isHidden = routeNames.isEmpty && stopName.isEmpty
        configureFolding()
        foldRow.addArrangedSubview(foldLabel)
        foldRow.addArrangedSubview(expandButton)
        foldRow.alignment = .center
        foldRow.spacing = 8
        foldRow.isLayoutMarginsRelativeArrangement = true
        foldRow.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)
        let top = BusLogFoldStackView(arrangedSubviews: [header, badges, foldRow])
        top.axis = .vertical
        top.spacing = 0
        top.setCustomSpacing(1, after: header)
        view.addSubview(top)
        view.addSubview(columns)
        top.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(11)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        columns.axis = .horizontal
        columns.distribution = .fillEqually
        columns.spacing = 10
        columns.snp.makeConstraints { make in
            make.top.equalTo(top.snp.bottom).offset(4)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        configureColumns()
        updateLayout()
    }

    private func configureFolding() {
        foldLabel.font = SettingsStyle.font(12)
        foldLabel.textColor = SettingsStyle.Color.secondaryText
        foldLabel.numberOfLines = 0
        foldLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        foldLabel.accessibilityIdentifier = "bus.log.fold_label"
        expandButton.titleLabel?.font = SettingsStyle.font(12, bold: true)
        expandButton.tintColor = SettingsStyle.Color.accent
        expandButton.contentHorizontalAlignment = .trailing
        expandButton.setContentHuggingPriority(.required, for: .horizontal)
        expandButton.accessibilityIdentifier = "bus.log.expand"
        expandButton.addTarget(self, action: #selector(toggleExpanded), for: .touchUpInside)
        expandButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func configureColumns() {
        for (index, date) in dates.enumerated() {
            let heading = UILabel()
            heading.text = date.formatted(.dateTime.month(.twoDigits).day(.twoDigits))
            heading.font = SettingsStyle.font(14, bold: true)
            heading.textColor = SettingsStyle.Color.text
            heading.textAlignment = .center
            let day = UILabel()
            day.text = date.formatted(.dateTime.weekday(.wide))
            day.font = SettingsStyle.font(11)
            day.textColor = SettingsStyle.Color.secondaryText
            day.textAlignment = .center
            let table = UITableView()
            table.backgroundColor = .clear
            table.separatorStyle = .none
            table.rowHeight = 36
            table.dataSource = self
            table.register(BusLogCell.self, forCellReuseIdentifier: BusLogCell.reuseIdentifier)
            table.accessibilityIdentifier = "bus.log.column.\(index)"
            table.accessibilityLabel = String(format: String(localized: "bus.log.column.%@"),
                                              date.formatted(.dateTime.month().day().weekday(.wide)))
            tables.append(table)
            let stack = UIStackView(arrangedSubviews: [heading, day, table])
            stack.axis = .vertical
            stack.spacing = 4
            stack.isLayoutMarginsRelativeArrangement = true
            stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 4, bottom: 8, trailing: 4)
            stack.backgroundColor = SettingsStyle.Color.card
            stack.layer.cornerRadius = 16
            columns.addArrangedSubview(stack)
        }
    }

    @objc
    private func toggleExpanded() {
        expanded.toggle()
        updateLayout()
    }

    private func updateLayout() {
        layout = BusDisplayLogic.departureLogs(columns: logs, nowMinutes: BusDisplayLogic.serviceMinutes(of: .now), expanded: expanded)
        foldLabel.text = expanded ? String(localized: "bus.log.showing_all")
            : String(format: String(localized: "bus.log.fold.%lld"), layout.hiddenPastCount)
        expandButton.setTitle(String(localized: expanded ? "bus.log.collapse" : "bus.log.expand"), for: .normal)
        expandButton.invalidateIntrinsicContentSize()
        expandButton.isHidden = !expanded && layout.hiddenPastCount == 0
        foldLabel.isHidden = expandButton.isHidden
        foldRow.isHidden = expandButton.isHidden
        view.layoutIfNeeded()
        for (index, table) in tables.enumerated() {
            let empty = UILabel()
            empty.text = String(localized: loading ? "bus.log.loading" : "bus.log.empty")
            empty.font = SettingsStyle.font(12)
            empty.textColor = SettingsStyle.Color.secondaryText
            empty.textAlignment = .center
            empty.numberOfLines = 0
            table.backgroundView = layout.columns[index].isEmpty ? empty : nil
            table.reloadData()
        }
    }

    private func fetchLog() {
        let formatter = DateFormatter()
        formatter.calendar = BusDisplayLogic.serviceCalendar
        formatter.timeZone = BusDisplayLogic.serviceCalendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStrings = dates.map(formatter.string(from:))
        Task {
            let response = try? await Network.shared.client.fetch(query: BusDepartureLogDialogQuery(
                routeStops: routes.map { BusRouteStopInput(route: $0, stop: stopID, dates: .some(dateStrings)) }
            ))
            if let data = response?.data {
                let entries = data.bus.flatMap(\.log)
                logs = dateStrings.map { date in entries.filter { $0.date == date }.map(\.time).sorted() }
            }
            loading = false
            updateLayout()
        }
    }
}

extension BusLogVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let index = tables.firstIndex(of: tableView) else { return 0 }
        return layout.columns[index].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let index = tables.firstIndex(of: tableView),
              let cell = tableView.dequeueReusableCell(withIdentifier: BusLogCell.reuseIdentifier,
                                                       for: indexPath) as? BusLogCell else { return UITableViewCell() }
        cell.configure(layout.columns[index][indexPath.row])
        return cell
    }
}

private final class BusLogFoldButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let horizontalInset = max(0, (44 - bounds.width) / 2)
        let verticalInset = max(0, (44 - bounds.height) / 2)
        return bounds.insetBy(dx: -horizontalInset, dy: -verticalInset).contains(point)
    }
}

private final class BusLogFoldStackView: UIStackView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Forward the button's expanded target through both compact containing stacks.
        super.point(inside: point, with: event) || arrangedSubviews.contains { subview in
            !subview.isHidden && subview.isUserInteractionEnabled &&
                subview.point(inside: convert(point, to: subview), with: event)
        }
    }
}
