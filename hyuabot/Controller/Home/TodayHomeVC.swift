import Api
import ApolloAPI
import SnapKit
import Then
import UIKit

private enum HomeDestination: Int, CaseIterable {
    case station
    case terminal
    case jungang
    case gwangmyeong
    case campus

    var title: String {
        switch self {
        case .station: String(localized: "home.destination.station")
        case .terminal: String(localized: "home.destination.terminal")
        case .jungang: String(localized: "home.destination.jungang")
        case .gwangmyeong: String(localized: "home.destination.gwangmyeong")
        case .campus: String(localized: "home.destination.campus")
        }
    }

    var routeTitle: String {
        switch self {
        case .station: String(localized: "home.route.station")
        case .terminal: String(localized: "home.route.terminal")
        case .jungang: String(localized: "home.route.jungang")
        case .gwangmyeong: String(localized: "home.route.gwangmyeong")
        case .campus: String(localized: "home.route.campus")
        }
    }
}

private struct HomeTransitOption {
    enum Kind {
        case shuttle
        case alternative
        case transfer
    }

    let kind: Kind
    let title: String
    let subtitle: String
    let minutes: Int?
    let badge: String
    let tintColor: UIColor
}

private struct HomeMealItem {
    let menu: String
    let price: String
}

private struct HomeMealSection {
    let cafeteria: String
    let runningTime: String?
    let items: [HomeMealItem]
}

private struct HomeMealPeriod {
    let marker: String
    let title: String
    let queryDate: Foundation.Date
    let iconName: String
    let mealIndex: Int
}

final class TodayHomeVC: UIViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let destinationControl = UISegmentedControl(items: HomeDestination.allCases.map(\.title))
    private let movementCard = UIStackView()
    private let movementStateLabel = UILabel()
    private let shuttleOptionStack = UIStackView()
    private let supportingOptionStack = UIStackView()
    private let cafeteriaCard = UIStackView()
    private let cafeteriaIconView = UIImageView()
    private let cafeteriaTitleLabel = UILabel()
    private let mealStack = UIStackView()
    private let refreshControl = UIRefreshControl()
    private lazy var legacyBar = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.borderWidth = 1 / UIScreen.main.scale
        $0.layer.borderColor = UIColor.separator.cgColor
    }
    private lazy var legacyBarLabel = UILabel().then {
        $0.text = String(localized: "home.action_bar.title")
        $0.textColor = .secondaryLabel
        $0.font = .godo(size: 13, weight: .bold)
    }
    private lazy var legacyButton = UIButton(type: .system).then {
        var config = UIButton.Configuration.tinted()
        config.baseForegroundColor = .hanyangBlue
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "bus.fill")?.withConfiguration(UIImage.SymbolConfiguration(
            pointSize: 16,
            weight: .semibold
        ))
        config.attributedTitle = AttributedString(String(localized: "home.legacy"), attributes: AttributeContainer([
            .font: UIFont.godo(size: 14, weight: .bold)
        ]))
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 12)
        $0.configuration = config
        $0.addTarget(self, action: #selector(openLegacyShuttle), for: .touchUpInside)
        $0.accessibilityIdentifier = "home.open_legacy"
    }

    private var selectedDestination: HomeDestination = .station
    private var shuttleData: ShuttleRealtimePageQuery.Data?
    private var busAlternatives: [String: [HomeTransitOption]] = [:]
    private var mealSections: [HomeMealSection] = []
    private var displayedMealPeriod: HomeMealPeriod?
    private var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchHomeData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.home)
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        navigationItem.title = String(localized: "home.title.today")

        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        view.addSubview(scrollView)
        view.addSubview(legacyBar)
        legacyBar.addSubview(legacyBarLabel)
        legacyBar.addSubview(legacyButton)
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(legacyBar.snp.top)
        }
        legacyBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(54)
        }
        legacyBarLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        legacyButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
        }

        scrollView.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.layoutMargins = UIEdgeInsets(top: 18, left: 16, bottom: 28, right: 16)
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        contentStack.addArrangedSubview(makeHeaderView())
        contentStack.addArrangedSubview(makeMovementCard())
        contentStack.addArrangedSubview(makeCafeteriaCard())
        renderLoadingState()
    }

    private func makeHeaderView() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12

        let topRow = UIStackView()
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 10

        let eyebrow = UILabel()
        eyebrow.text = formattedToday()
        eyebrow.font = .godo(size: 13, weight: .regular)
        eyebrow.textColor = .secondaryLabel

        topRow.addArrangedSubview(eyebrow)
        topRow.addArrangedSubview(UIView())

        let title = UILabel()
        title.text = String(localized: "home.hero.title")
        title.font = .godo(size: 28, weight: .bold)
        title.textColor = .label

        let subtitle = UILabel()
        subtitle.text = String(localized: "home.hero.subtitle")
        subtitle.font = .godo(size: 15, weight: .regular)
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 0

        destinationControl.selectedSegmentIndex = selectedDestination.rawValue
        destinationControl.setTitleTextAttributes([
            .font: UIFont.godo(size: 13, weight: .regular)
        ], for: .normal)
        destinationControl.setTitleTextAttributes([
            .font: UIFont.godo(size: 13, weight: .bold)
        ], for: .selected)
        destinationControl.addTarget(self, action: #selector(destinationChanged), for: .valueChanged)

        stack.addArrangedSubview(topRow)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(subtitle)
        stack.addArrangedSubview(destinationControl)
        return stack
    }

    private func makeMovementCard() -> UIView {
        let card = cardView()
        movementCard.axis = .vertical
        movementCard.spacing = 14
        movementCard.layoutMargins = UIEdgeInsets(top: 18, left: 16, bottom: 16, right: 16)
        movementCard.isLayoutMarginsRelativeArrangement = true

        let header = makeSectionHeader(
            icon: "bus.fill",
            title: String(localized: "home.movement.title"),
            buttonTitle: String(localized: "home.movement.detail"),
            action: #selector(openLegacyShuttle)
        )
        movementStateLabel.font = .godo(size: 15, weight: .regular)
        movementStateLabel.textColor = .secondaryLabel
        movementStateLabel.numberOfLines = 0

        shuttleOptionStack.axis = .vertical
        shuttleOptionStack.spacing = 10
        supportingOptionStack.axis = .vertical
        supportingOptionStack.spacing = 8

        movementCard.addArrangedSubview(header)
        movementCard.addArrangedSubview(movementStateLabel)
        movementCard.addArrangedSubview(shuttleOptionStack)
        movementCard.addArrangedSubview(supportingOptionStack)

        card.addSubview(movementCard)
        movementCard.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return card
    }

    private func makeCafeteriaCard() -> UIView {
        let card = cardView()
        cafeteriaCard.axis = .vertical
        cafeteriaCard.spacing = 14
        cafeteriaCard.layoutMargins = UIEdgeInsets(top: 18, left: 16, bottom: 16, right: 16)
        cafeteriaCard.isLayoutMarginsRelativeArrangement = true

        cafeteriaCard.addArrangedSubview(makeSectionHeader(
            icon: activeMealPeriod().iconName,
            iconView: cafeteriaIconView,
            title: activeMealPeriod().title,
            titleLabel: cafeteriaTitleLabel,
            buttonTitle: String(localized: "home.cafeteria.detail"),
            action: #selector(openCafeteria)
        ))

        mealStack.axis = .vertical
        mealStack.spacing = 10
        cafeteriaCard.addArrangedSubview(mealStack)

        card.addSubview(cafeteriaCard)
        cafeteriaCard.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return card
    }

    private func makeSectionHeader(
        icon: String,
        iconView providedIconView: UIImageView? = nil,
        title: String,
        titleLabel providedTitleLabel: UILabel? = nil,
        buttonTitle: String,
        action: Selector
    ) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 10

        let imageView = providedIconView ?? UIImageView()
        imageView.image = UIImage(systemName: icon)
        imageView.tintColor = .hanyangBlue
        imageView.contentMode = .scaleAspectFit
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(22)
        }

        let label = providedTitleLabel ?? UILabel()
        label.text = title
        label.font = .godo(size: 20, weight: .bold)
        label.textColor = .label

        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString(buttonTitle, attributes: AttributeContainer([
            .font: UIFont.godo(size: 13, weight: .bold)
        ]))
        config.image = UIImage(systemName: "chevron.right")?.withConfiguration(UIImage.SymbolConfiguration(
            pointSize: 13,
            weight: .bold
        ))
        config.imagePlacement = .trailing
        config.imagePadding = 3
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 4)
        button.configuration = config
        button.addTarget(self, action: action, for: .touchUpInside)

        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(UIView())
        stack.addArrangedSubview(button)
        return stack
    }

    private func cardView() -> UIView {
        UIView().then {
            $0.backgroundColor = .secondarySystemGroupedBackground
            $0.layer.cornerRadius = 8
            $0.layer.borderWidth = 1
            $0.layer.borderColor = UIColor.separator.withAlphaComponent(0.35).cgColor
        }
    }

    private func renderLoadingState() {
        movementStateLabel.text = String(localized: "home.loading")
        replaceSubviews(in: shuttleOptionStack, with: [makeSkeletonRow(widthRatio: 0.72), makeSkeletonRow(widthRatio: 0.54)])
        replaceSubviews(in: supportingOptionStack, with: [])
        replaceSubviews(in: mealStack, with: [makeSkeletonRow(widthRatio: 0.82), makeSkeletonRow(widthRatio: 0.64)])
    }

    private func render() {
        renderMovement()
        renderMeals()
    }

    private func renderMovement() {
        let options = movementOptions(for: selectedDestination)
        let shuttleOptions = options.filter { $0.kind == .shuttle }
        let supportOptions = options.filter { $0.kind != .shuttle }
        let nextShuttleMinutes = shuttleOptions.first?.minutes
        let shouldEmphasizeSupport = nextShuttleMinutes.map { $0 > 20 } ?? true

        movementStateLabel.text = selectedDestination.routeTitle
        if shuttleOptions.isEmpty {
            replaceSubviews(in: shuttleOptionStack, with: [
                makeEmptyView(
                    title: String(localized: "home.empty.shuttle.title"),
                    message: String(localized: "home.empty.shuttle.message")
                )
            ])
        } else {
            replaceSubviews(in: shuttleOptionStack, with: shuttleOptions.prefix(2).map { makeTransitRow($0, emphasized: true) })
        }

        let supportHeader = UILabel()
        supportHeader.font = .godo(size: 13, weight: .bold)
        supportHeader.textColor = shouldEmphasizeSupport ? .label : .secondaryLabel
        supportHeader.text = shouldEmphasizeSupport ? String(localized: "home.support.emphasized") : String(localized: "home.support.default")

        let rows = supportOptions.prefix(shouldEmphasizeSupport ? 4 : 2).map { makeTransitRow($0, emphasized: shouldEmphasizeSupport) }
        replaceSubviews(in: supportingOptionStack, with: rows.isEmpty ? [] : [supportHeader] + rows)
    }

    private func renderMeals() {
        let mealPeriod = activeMealPeriod()
        cafeteriaIconView.image = UIImage(systemName: mealPeriod.iconName)
        cafeteriaTitleLabel.text = mealPeriod.title
        if mealSections.isEmpty {
            replaceSubviews(in: mealStack, with: [
                makeEmptyView(
                    title: String(format: String(localized: "home.empty.meal.title"), currentMealTitle()),
                    message: String(localized: "home.empty.meal.message")
                )
            ])
            return
        }
        replaceSubviews(in: mealStack, with: mealSections.map(makeMealSection))
    }

    private func movementOptions(for destination: HomeDestination) -> [HomeTransitOption] {
        var options: [HomeTransitOption] = []
        switch destination {
        case .station:
            options.append(contentsOf: shuttleOptions(stop: "dormitory_o", destination: "STATION", subtitle: String(localized: "home.transit.free_station_transfer")))
            options.append(contentsOf: busAlternatives["dormitory_station"] ?? [])
            options.append(HomeTransitOption(
                kind: .transfer,
                title: String(localized: "home.transit.station_transfer.title"),
                subtitle: String(localized: "home.transit.station_transfer.subtitle"),
                minutes: nil,
                badge: String(localized: "home.badge.transfer"),
                tintColor: .systemIndigo
            ))
        case .terminal:
            options.append(contentsOf: shuttleOptions(stop: "dormitory_o", destination: "TERMINAL", subtitle: String(localized: "home.transit.free_terminal")))
            options.append(contentsOf: busAlternatives["dormitory_terminal"] ?? [])
            options.append(contentsOf: busAlternatives["shuttlecock_terminal"] ?? [])
        case .jungang:
            options.append(contentsOf: shuttleOptions(stop: "dormitory_o", destination: "JUNGANG", subtitle: String(localized: "home.transit.free_jungang")))
            options.append(contentsOf: busAlternatives["dormitory_jungang"] ?? [])
            options.append(contentsOf: busAlternatives["shuttlecock_jungang"] ?? [])
        case .gwangmyeong:
            options.append(contentsOf: shuttleOptions(stop: "dormitory_o", destination: "STATION", subtitle: String(localized: "home.transit.free_artist_50")))
            options.append(contentsOf: transferBusOptions(stopSeq: 216_000_759, title: String(localized: "home.transit.bus_50_gwangmyeong.title"), subtitle: String(localized: "home.transit.bus_50_gwangmyeong.subtitle")))
        case .campus:
            options.append(contentsOf: shuttleOptions(stop: "station", destination: "CAMPUS", subtitle: String(localized: "home.transit.free_campus")))
            options.append(contentsOf: busAlternatives["station_dormitory"] ?? [])
            options.append(contentsOf: transferBusOptions(stopSeq: 216_000_117, title: String(localized: "home.transit.bus_50_ansan.title"), subtitle: String(localized: "home.transit.bus_50_ansan.subtitle")))
        }
        return options
    }

    private func shuttleOptions(stop stopName: String, destination: String, subtitle: String) -> [HomeTransitOption] {
        guard let stop = shuttleData?.shuttle.stops.first(where: { $0.name == stopName }),
              let group = stop.timetable.destination.first(where: { $0.destination == destination }) else { return [] }
        return group.entries.prefix(2).map { entry in
            HomeTransitOption(
                kind: .shuttle,
                title: String(format: String(localized: "home.shuttle.departure.title"), compactTime(entry.time)),
                subtitle: subtitle,
                minutes: minutesUntil(entry.time),
                badge: String(localized: "home.badge.free"),
                tintColor: .hanyangBlue
            )
        }
    }

    private func transferBusOptions(stopSeq: Int, title: String, subtitle: String) -> [HomeTransitOption] {
        guard let bus = shuttleData?.transferBus.first(where: { $0.stop.seq == stopSeq }) else { return [] }
        return bus.arrival.prefix(2).compactMap { arrival in
            guard let minutes = arrival.minutes else { return nil }
            return HomeTransitOption(
                kind: .transfer,
                title: title,
                subtitle: subtitle,
                minutes: minutes,
                badge: String(localized: "home.badge.transfer"),
                tintColor: UIColor(named: "busGreen") ?? .systemGreen
            )
        }
    }

    private func buildBusAlternatives(_ busList: [ShuttleBusAlternativeQuery.Data.Bus]) -> [String: [HomeTransitOption]] {
        func item(routeSeq: Int, stopSeq: Int) -> ShuttleBusAlternativeQuery.Data.Bus? {
            busList.first { $0.route.seq == routeSeq && $0.stop.seq == stopSeq }
        }

        func option(_ bus: ShuttleBusAlternativeQuery.Data.Bus?, route: String, subtitle: String, color: UIColor) -> HomeTransitOption? {
            guard let bus, let minutes = bus.arrival.first?.minutes else { return nil }
            return HomeTransitOption(kind: .alternative, title: route, subtitle: subtitle, minutes: minutes, badge: String(localized: "home.badge.alternative"), tintColor: color)
        }

        func best(_ options: [HomeTransitOption?]) -> HomeTransitOption? {
            options.compactMap { $0 }.min { ($0.minutes ?? Int.max) < ($1.minutes ?? Int.max) }
        }

        let green = UIColor(named: "busGreen") ?? .systemGreen
        let blue = UIColor(named: "busBlue") ?? .systemBlue
        let route80A = best([
            option(item(routeSeq: 216_000_081, stopSeq: 216_000_028), route: "80A", subtitle: String(localized: "home.alt.gyeonggi_technopark"), color: blue),
            option(item(routeSeq: 216_000_101, stopSeq: 216_000_028), route: "N80A", subtitle: String(localized: "home.alt.gyeonggi_technopark"), color: blue)
        ])
        let route62Out = option(item(routeSeq: 216_000_016, stopSeq: 216_000_152), route: "62", subtitle: String(localized: "home.alt.seongan_entrance"), color: green)

        return [
            "dormitory_station": [
                option(item(routeSeq: 216_000_068, stopSeq: 216_000_383), route: "10-1", subtitle: String(localized: "home.alt.dormitory_nearby"), color: green)
            ].compactMap { $0 },
            "dormitory_terminal": [route80A].compactMap { $0 },
            "dormitory_jungang": [route80A].compactMap { $0 },
            "shuttlecock_terminal": [route62Out].compactMap { $0 },
            "shuttlecock_jungang": [route62Out].compactMap { $0 },
            "station_dormitory": [
                option(item(routeSeq: 216_000_068, stopSeq: 216_000_138), route: "10-1", subtitle: String(localized: "home.alt.sangnoksu"), color: green)
            ].compactMap { $0 }
        ]
    }

    private func fetchHomeData() {
        guard !isLoading else { return }
        isLoading = true
        renderLoadingState()

        let mealPeriod = currentMealPeriod()
        displayedMealPeriod = mealPeriod
        let timeFormatter = DateFormatter().then { $0.dateFormat = "HH:mm" }
        let campusID = UserDefaults.standard.integer(forKey: "campusID") == 0 ? 2 : UserDefaults.standard.integer(forKey: "campusID")

        Task {
            async let shuttleResponse = Network.shared.client.fetch(
                query: ShuttleRealtimePageQuery(
                    language: noticeLanguage(),
                    after: GraphQLNullable(stringLiteral: timeFormatter.string(from: Foundation.Date.now)),
                    weekday: currentWeekdayString()
                ),
                cachePolicy: .networkOnly
            )
            async let busResponse = Network.shared.client.fetch(query: ShuttleBusAlternativeQuery(), cachePolicy: .networkOnly)
            async let cafeteriaResponse = Network.shared.client.fetch(
                query: CafeteriaPageQuery(date: mealPeriod.queryDate.toLocalDateString(), campusID: Int32(campusID)),
                cachePolicy: .networkOnly
            )

            let responses = try? await (shuttleResponse, busResponse, cafeteriaResponse)
            await MainActor.run {
                if let responses {
                    shuttleData = responses.0.data
                    if let busData = responses.1.data {
                        busAlternatives = buildBusAlternatives(busData.bus)
                    }
                    if let cafeteriaData = responses.2.data {
                        mealSections = buildMealSections(cafeteriaData.cafeteria, mealPeriod: mealPeriod)
                    }
                }
                isLoading = false
                refreshControl.endRefreshing()
                render()
            }
        }
    }

    private func buildMealSections(
        _ cafeterias: [CafeteriaPageQuery.Data.Cafeterium],
        mealPeriod: HomeMealPeriod
    ) -> [HomeMealSection] {
        let marker = mealPeriod.marker
        return cafeterias
            .sorted { $0.seq < $1.seq }
            .compactMap { cafeteria in
                let items = cafeteria.menus
                    .filter { $0.type.contains(marker) }
                    .compactMap { menu -> HomeMealItem? in
                        let menuText = representativeMenuText(menu.food)
                        guard !menuText.isEmpty else { return nil }
                        return HomeMealItem(
                            menu: menuText,
                            price: menu.price
                        )
                    }
                guard !items.isEmpty else { return nil }
                return HomeMealSection(
                    cafeteria: cafeteriaName(seq: cafeteria.seq),
                    runningTime: runningTime(for: cafeteria, mealPeriod: mealPeriod),
                    items: items
                )
            }
    }

    private func representativeMenuText(_ text: String) -> String {
        let menuText = localizedMenuText(text)
        guard !menuText.isEmpty else { return "" }
        return menuText
            .components(separatedBy: .whitespacesAndNewlines)
            .first(where: { !$0.isEmpty }) ?? menuText
    }

    private func makeTransitRow(_ option: HomeTransitOption, emphasized: Bool) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        row.isLayoutMarginsRelativeArrangement = true
        row.backgroundColor = emphasized ? option.tintColor.withAlphaComponent(0.10) : .tertiarySystemGroupedBackground
        row.layer.cornerRadius = 8

        let badge = UILabel()
        badge.text = option.badge
        badge.font = .godo(size: 12, weight: .bold)
        badge.textColor = .white
        badge.textAlignment = .center
        badge.backgroundColor = option.tintColor
        badge.layer.cornerRadius = 12
        badge.clipsToBounds = true
        badge.snp.makeConstraints { make in
            make.width.equalTo(44)
            make.height.equalTo(24)
        }

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 4
        let title = UILabel()
        title.text = option.title
        title.font = .godo(size: emphasized ? 17 : 15, weight: .bold)
        title.textColor = .label
        title.numberOfLines = 1
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.75
        let subtitle = UILabel()
        subtitle.text = option.subtitle
        subtitle.font = .godo(size: 13, weight: .regular)
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 2
        textStack.addArrangedSubview(title)
        textStack.addArrangedSubview(subtitle)

        let minutes = UILabel()
        minutes.text = option.minutes.map { String(format: String(localized: "home.minutes"), $0) } ?? String(localized: "home.check")
        minutes.font = .godo(size: emphasized ? 22 : 17, weight: .bold)
        minutes.textColor = option.tintColor
        minutes.textAlignment = .right
        minutes.setContentCompressionResistancePriority(.required, for: .horizontal)

        row.addArrangedSubview(badge)
        row.addArrangedSubview(textStack)
        row.addArrangedSubview(minutes)
        return row
    }

    private func makeMealSection(_ section: HomeMealSection) -> UIView {
        let sectionStack = UIStackView()
        sectionStack.axis = .vertical
        sectionStack.spacing = 10
        sectionStack.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        sectionStack.isLayoutMarginsRelativeArrangement = true
        sectionStack.backgroundColor = .tertiarySystemGroupedBackground
        sectionStack.layer.cornerRadius = 8

        let header = UIStackView()
        header.axis = .vertical
        header.spacing = 3

        let title = UILabel()
        title.text = section.cafeteria
        title.font = .godo(size: 16, weight: .bold)
        title.textColor = .label

        header.addArrangedSubview(title)
        if let runningTime = section.runningTime, !runningTime.isEmpty {
            let time = UILabel()
            time.text = runningTime
            time.font = .godo(size: 12, weight: .regular)
            time.textColor = .tertiaryLabel
            header.addArrangedSubview(time)
        }
        sectionStack.addArrangedSubview(header)

        section.items.enumerated().forEach { index, item in
            if index > 0 {
                let separator = UIView()
                separator.backgroundColor = .separator.withAlphaComponent(0.35)
                separator.snp.makeConstraints { make in
                    make.height.equalTo(1 / UIScreen.main.scale)
                }
                sectionStack.addArrangedSubview(separator)
            }
            sectionStack.addArrangedSubview(makeMealMenuRow(item))
        }
        return sectionStack
    }

    private func makeMealMenuRow(_ item: HomeMealItem) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 8

        let menu = UILabel()
        menu.text = item.menu
        menu.font = .godo(size: 14, weight: .regular)
        menu.textColor = .secondaryLabel
        menu.numberOfLines = 1
        menu.adjustsFontSizeToFitWidth = true
        menu.minimumScaleFactor = 0.8

        let price = UILabel()
        price.text = item.price
        price.font = .godo(size: 14, weight: .bold)
        price.textColor = .hanyangBlue
        price.textAlignment = .right
        price.setContentCompressionResistancePriority(.required, for: .horizontal)

        row.addArrangedSubview(menu)
        row.addArrangedSubview(price)
        return row
    }

    private func makeEmptyView(title: String, message: String) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.layoutMargins = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.backgroundColor = .tertiarySystemGroupedBackground
        stack.layer.cornerRadius = 8

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .godo(size: 15, weight: .bold)
        titleLabel.textColor = .label
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = .godo(size: 13, weight: .regular)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(messageLabel)
        return stack
    }

    private func makeSkeletonRow(widthRatio: CGFloat) -> UIView {
        let view = UIView()
        view.backgroundColor = .tertiarySystemGroupedBackground
        view.layer.cornerRadius = 8
        view.snp.makeConstraints { make in
            make.height.equalTo(52)
        }

        let bar = UIView()
        bar.backgroundColor = .separator.withAlphaComponent(0.45)
        bar.layer.cornerRadius = 5
        view.addSubview(bar)
        bar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(widthRatio)
            make.height.equalTo(10)
        }
        return view
    }

    private func replaceSubviews(in stack: UIStackView, with views: [UIView]) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        views.forEach(stack.addArrangedSubview)
    }

    @objc private func destinationChanged() {
        guard let destination = HomeDestination(rawValue: destinationControl.selectedSegmentIndex) else { return }
        selectedDestination = destination
        AnalyticsManager.logSelect(.homeSelectDestination, type: .tab, name: destination.title)
        renderMovement()
    }

    @objc private func refresh() {
        AnalyticsManager.logSelect(.homeRefresh)
        fetchHomeData()
    }

    @objc private func openLegacyShuttle() {
        AnalyticsManager.logSelect(.homeOpenLegacyShuttle)
        (navigationController as? ShuttleNC)?.showLegacyShuttle()
    }

    @objc private func openCafeteria() {
        AnalyticsManager.logSelect(.homeOpenCafeteria)
        if let root = tabBarController as? RootVC {
            let mealPeriod = activeMealPeriod()
            root.selectedViewController = root.cafeteriaNC
            root.cafeteriaNC.showMeal(date: mealPeriod.queryDate, mealIndex: mealPeriod.mealIndex)
        }
    }

    private func minutesUntil(_ time: LocalTime) -> Int? {
        guard let date = time.toLocalTimeOrNil() else { return nil }
        return max(0, Int(ceil(date.timeIntervalSince(Foundation.Date.now) / 60)))
    }

    private func compactTime(_ time: LocalTime) -> String {
        String(time.prefix(5))
    }

    private func currentMealPeriod() -> HomeMealPeriod {
        let hour = Calendar.current.component(.hour, from: Foundation.Date.now)
        if hour < 10 {
            return HomeMealPeriod(
                marker: "조식",
                title: String(localized: "home.meal.breakfast"),
                queryDate: Foundation.Date.now,
                iconName: "sunrise.fill",
                mealIndex: 0
            )
        }
        if hour < 15 {
            return HomeMealPeriod(
                marker: "중식",
                title: String(localized: "home.meal.lunch"),
                queryDate: Foundation.Date.now,
                iconName: "sun.max.fill",
                mealIndex: 1
            )
        }
        if hour < 20 {
            return HomeMealPeriod(
                marker: "석식",
                title: String(localized: "home.meal.dinner"),
                queryDate: Foundation.Date.now,
                iconName: "moon.fill",
                mealIndex: 2
            )
        }
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Foundation.Date.now) ?? Foundation.Date.now
        return HomeMealPeriod(
            marker: "조식",
            title: String(localized: "home.meal.tomorrow_breakfast"),
            queryDate: tomorrow,
            iconName: "sunrise.fill",
            mealIndex: 0
        )
    }

    private func currentMealTitle() -> String {
        activeMealPeriod().title
    }

    private func activeMealPeriod() -> HomeMealPeriod {
        displayedMealPeriod ?? currentMealPeriod()
    }

    private func runningTime(
        for cafeteria: CafeteriaPageQuery.Data.Cafeterium,
        mealPeriod: HomeMealPeriod
    ) -> String? {
        switch mealPeriod.marker {
        case "조식": cafeteria.runningTime.breakfast
        case "중식": cafeteria.runningTime.lunch
        default: cafeteria.runningTime.dinner
        }
    }

    private func cafeteriaName(seq: Int) -> String {
        switch seq {
        case 1:
            String(localized: "cafeteria.title.1")
        case 2:
            String(localized: "cafeteria.title.2")
        case 4:
            String(localized: "cafeteria.title.4")
        case 6:
            String(localized: "cafeteria.title.6")
        case 7:
            String(localized: "cafeteria.title.7")
        case 8:
            String(localized: "cafeteria.title.8")
        case 11:
            String(localized: "cafeteria.title.11")
        case 12:
            String(localized: "cafeteria.title.12")
        case 13:
            String(localized: "cafeteria.title.13")
        case 14:
            String(localized: "cafeteria.title.14")
        case 15:
            String(localized: "cafeteria.title.15")
        default:
            String(localized: "cafeteria.title.1")
        }
    }

    private func localizedMenuText(_ text: String) -> String {
        let cleaned = text.replacingOccurrences(of: "\"", with: "")
        let isKorean = (Locale.current.language.languageCode?.identifier ?? "ko").hasPrefix("ko")
        let tokens = cleaned.components(separatedBy: .whitespacesAndNewlines)
        let pattern = isKorean ? #"\p{Hangul}"# : #"[A-Za-z]"#
        let hasEnglish = cleaned.range(of: #"[A-Za-z]"#, options: .regularExpression) != nil
        let shouldFilter = isKorean || hasEnglish
        let filteredTokens = shouldFilter ? tokens.filter {
            $0.range(of: pattern, options: .regularExpression) != nil
        } : tokens
        let displayTokens = filteredTokens.isEmpty ? tokens : filteredTokens
        return displayTokens
            .joined(separator: " ")
            .replacingOccurrences(of: "\n", with: " · ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func formattedToday() -> String {
        DateFormatter().then {
            $0.locale = .current
            $0.setLocalizedDateFormatFromTemplate("MdEEEE")
        }.string(from: Foundation.Date.now)
    }

    private func noticeLanguage() -> String {
        let code = Locale.current.language.languageCode?.identifier ?? "ko"
        return code.starts(with: "en") ? "ENGLISH" : "KOREAN"
    }

    private func currentWeekdayString() -> String {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? calendar.timeZone
        switch calendar.component(.weekday, from: Foundation.Date.now) {
        case 1:
            return "sunday"
        case 7:
            return "saturday"
        default:
            return "weekday"
        }
    }
}
