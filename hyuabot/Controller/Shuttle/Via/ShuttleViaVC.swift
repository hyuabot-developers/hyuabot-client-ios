//
//  ShuttleViaVC.swift
//  hyuabot
//

import Api
import UIKit

class ShuttleViaVC: UIViewController {
    private var itemByOrder: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order?
    private var itemByDestination: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry?
    private var timetableItem: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order?
    private let sheetView = HYUSheetView(title: String(localized: "shuttle.via.stop"))
    private let card = HYUSheetView.card()

    private lazy var tableView = UITableView().then {
        $0.backgroundColor = .clear
        $0.separatorStyle = .none
        $0.isScrollEnabled = false
        $0.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
        $0.rowHeight = 44
        $0.register(ShuttleViaCellView.self, forCellReuseIdentifier: ShuttleViaCellView.reuseIdentifier)
        $0.dataSource = self
        $0.delegate = self
    }

    init(item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) {
        super.init(nibName: nil, bundle: nil)
        itemByOrder = item
    }

    init(item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) {
        super.init(nibName: nil, bundle: nil)
        itemByDestination = item
    }

    init(item: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order) {
        super.init(nibName: nil, bundle: nil)
        timetableItem = item
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.shuttleVia)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    var sheetHeight: CGFloat {
        view.layoutIfNeeded()
        return sheetView.contentHeight
    }

    private var routeStopCount: Int {
        if let itemByOrder {
            return itemByOrder.stops.count
        } else if let itemByDestination {
            return itemByDestination.stops.count
        } else if let timetableItem {
            return timetableItem.stops.count
        }
        return 0
    }

    private func setupUI() {
        view.backgroundColor = SettingsStyle.Color.busSheetBackground
        view.addSubview(sheetView)
        sheetView.snp.makeConstraints { $0.edges.equalToSuperview() }

        card.addArrangedSubview(tableView)
        tableView.snp.makeConstraints { $0.height.equalTo(CGFloat(routeStopCount) * 44 + 12) }
        sheetView.contentStack.addArrangedSubview(card)
    }

    private func formatTime(_ time: String) -> String {
        guard let date = time.toLocalTimeOrNil() else { return time.substring(from: 0, to: 4) }
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return time.substring(from: 0, to: 4) }
        return String(format: String(localized: "shuttle.shorten.time.%lld.%lld"), hour, minute)
    }
}

extension ShuttleViaVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        routeStopCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView
            .dequeueReusableCell(withIdentifier: ShuttleViaCellView.reuseIdentifier) as? ShuttleViaCellView ?? ShuttleViaCellView()
        if let itemByOrder, itemByOrder.stops.indices.contains(indexPath.row) {
            cell.setupUI(startStop: itemByOrder, item: itemByOrder.stops[indexPath.row])
        } else if let itemByDestination, itemByDestination.stops.indices.contains(indexPath.row) {
            cell.setupUI(startStop: itemByDestination, item: itemByDestination.stops[indexPath.row])
        } else if let timetableItem, timetableItem.stops.indices.contains(indexPath.row) {
            cell.setupUI(startStop: timetableItem, item: timetableItem.stops[indexPath.row])
        }
        cell.setTimelinePosition(isFirst: indexPath.row == 0, isLast: indexPath.row == routeStopCount - 1)
        return cell
    }
}
