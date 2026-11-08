//
//  CommuterBusVC.swift
//  hyuabot
//
//  Created by Codex on 11/8/26.
//

import Api
import CoreLocation
import MapKit
import UIKit

@MainActor
final class CommuterBusVC: UIViewController, SettingsStyledScreen {
    private let autoLoad: Bool
    private let locationManager = CLLocationManager()
    private let scrollView = UIScrollView()
    private let content = UIStackView()
    private let subtitleLabel = UILabel()
    private let directionView = CommuterDirectionSegmentView()
    private let routeHeader = CommuterRouteSectionHeaderView()
    private let routeGrid = CommuterRouteGridView()
    private let skeleton = CommuterSkeletonCardView()
    private let timeline = CommuterTimelineCardView()
    private let errorCard = UIView()
    private let errorLabel = UILabel()
    private let disclaimerContainer = UIView()
    private let disclaimerLabel = UILabel()
    private let refreshControl = UIRefreshControl()

    private var routes: [CommuterRoute] = []
    private var context: CommuterServiceContext?
    private var selection = CommuterSelection.auto
    private var isLoading = false
    private var loadFailed = false
    private var usesFixture = false
    private var clockTimer: Timer?

    private var isReadyToLoad: Bool { !isLoading }

    init(autoLoad: Bool = true) {
        self.autoLoad = autoLoad
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "campus.commuter.title")
        view.accessibilityIdentifier = "commuter.root"
        view.backgroundColor = SettingsStyle.Color.background
        SettingsNavigationStyle.apply(to: self, largeTitle: true)
        configureScrollLayout()
        configureContentLayout()
        configureCards()
        configureDisclaimer()
        bindActions()

#if DEBUG
        if let mode = CommuterDebugFixture.activeMode {
            usesFixture = true
            let scenario = CommuterDebugFixture.scenario(mode)
            apply(routes: scenario.routes, context: scenario.context, isLoading: scenario.isLoading)
            return
        }
#endif
        if autoLoad {
            requestLocationAuthorizationIfNeeded()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appWillEnterForeground),
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
            load()
        } else {
            render()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SettingsNavigationStyle.screenWillAppear(self)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        refreshClock()
        guard autoLoad, !usesFixture else { return }
        clockTimer?.invalidate()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshClock() }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SettingsNavigationStyle.screenWillDisappear(self)
        clockTimer?.invalidate()
        clockTimer = nil
    }

    func apply(routes: [CommuterRoute], context: CommuterServiceContext, isLoading: Bool) {
        self.routes = routes
        self.context = context
        self.isLoading = isLoading
        loadFailed = false
        render()
    }

    func refreshClock(now: Foundation.Date = Foundation.Date()) {
        guard autoLoad, !usesFixture, !isLoading, !loadFailed, !routes.isEmpty, var context else { return }
        switch CommuterBusLogic.clockAction(contextDate: context.date, now: now) {
        case .tick(let minutes):
            context.date = now
            context.nowMinutes = minutes
            self.context = context
            render()
        case .reloadContext:
            load()
        }
    }

    private func configureScrollLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        refreshControl.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        content.axis = .vertical
        content.alignment = .fill
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(content)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 2),
            content.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -40),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])

    }

    private func configureContentLayout() {
        subtitleLabel.numberOfLines = 0
        subtitleLabel.accessibilityIdentifier = "commuter.subtitle"
        content.addArrangedSubview(subtitleLabel)
        content.setCustomSpacing(20, after: subtitleLabel)
        content.addArrangedSubview(directionView)
        content.setCustomSpacing(20, after: directionView)
        content.addArrangedSubview(routeHeader)
        content.setCustomSpacing(8, after: routeHeader)
        content.addArrangedSubview(routeGrid)
        content.setCustomSpacing(16, after: routeGrid)
        content.addArrangedSubview(skeleton)
        content.setCustomSpacing(12, after: skeleton)
        content.addArrangedSubview(timeline)
        content.setCustomSpacing(12, after: timeline)
        content.addArrangedSubview(errorCard)
        content.setCustomSpacing(12, after: errorCard)
        content.addArrangedSubview(disclaimerContainer)
    }

    private func configureCards() {
        errorCard.backgroundColor = SettingsStyle.Color.card
        errorCard.layer.cornerRadius = 16
        errorCard.accessibilityIdentifier = "commuter.error"
        let errorTap = UITapGestureRecognizer(target: self, action: #selector(retryLoad))
        errorCard.addGestureRecognizer(errorTap)
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorCard.addSubview(errorLabel)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            errorLabel.topAnchor.constraint(equalTo: errorCard.topAnchor, constant: 24),
            errorLabel.leadingAnchor.constraint(equalTo: errorCard.leadingAnchor, constant: 24),
            errorLabel.trailingAnchor.constraint(equalTo: errorCard.trailingAnchor, constant: -24),
            errorLabel.bottomAnchor.constraint(equalTo: errorCard.bottomAnchor, constant: -24)
        ])
    }

    private func configureDisclaimer() {
        disclaimerContainer.addSubview(disclaimerLabel)
        disclaimerLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            disclaimerLabel.topAnchor.constraint(equalTo: disclaimerContainer.topAnchor),
            disclaimerLabel.leadingAnchor.constraint(equalTo: disclaimerContainer.leadingAnchor, constant: 4),
            disclaimerLabel.trailingAnchor.constraint(equalTo: disclaimerContainer.trailingAnchor, constant: -4),
            disclaimerLabel.bottomAnchor.constraint(equalTo: disclaimerContainer.bottomAnchor)
        ])
        disclaimerLabel.numberOfLines = 1
        disclaimerLabel.lineBreakMode = .byTruncatingTail
        disclaimerLabel.accessibilityIdentifier = "commuter.disclaimer"
    }

    private func bindActions() {
        directionView.onSelect = { [weak self] direction in
            guard let self, let context = self.context else { return }
            let model = CommuterBusLogic.makeModel(routes: self.routes, context: context, selection: self.selection)
            let routeName = direction == model.autoDirection
                ? model.autoRouteName
                : self.routes.first(where: { $0.direction == direction })?.name
            self.selection = CommuterSelection(direction: direction, routeName: routeName, expanded: false)
            self.render()
        }
        routeGrid.onSelect = { [weak self] name in
            guard let self, let context = self.context else { return }
            let model = CommuterBusLogic.makeModel(routes: self.routes, context: context, selection: self.selection)
            self.selection = CommuterSelection(direction: model.selectedDirection, routeName: name, expanded: false)
            self.render()
        }
        routeHeader.onResetToNearest = { [weak self] in
            self?.selection = .auto
            self?.render()
        }
        timeline.onExpand = { [weak self] in
            guard let self else { return }
            self.selection.expanded = true
            self.render()
        }
        timeline.onOpenMap = { [weak self] stop in self?.openMap(for: stop) }
    }

    private func render() {
        let model = context.map { CommuterBusLogic.makeModel(routes: routes, context: $0, selection: selection) }
        directionView.configure(items: model?.directions ?? [])
        routeHeader.configure(showsReset: model?.showsResetToNearest ?? false)
        routeGrid.configure(items: model?.routes ?? [])
        updateLabel(subtitleLabel, text: model.map { subtitle(for: $0.subtitle) } ?? "",
                    font: SettingsStyle.font(14), color: SettingsStyle.Color.secondaryText, lineHeight: 20)
        updateLabel(errorLabel, text: String(localized: "commuter.error"),
                    font: SettingsStyle.font(15), color: SettingsStyle.Color.secondaryText, lineHeight: 20)
        updateLabel(disclaimerLabel, text: String(localized: "commuter.disclaimer"),
                    font: SettingsStyle.font(12), color: SettingsStyle.Color.commuterFaint, lineHeight: 16,
                    lineBreakMode: .byTruncatingTail)

        let showLoading = isLoading
        let showError = !isLoading && loadFailed
        let showTimeline = !isLoading && !loadFailed && model?.summary != nil
        skeleton.isHidden = !showLoading
        timeline.isHidden = !showTimeline
        errorCard.isHidden = !showError
        disclaimerContainer.isHidden = !showTimeline
        directionView.isHidden = false
        routeHeader.isHidden = false
        routeGrid.isHidden = false
        if showLoading { skeleton.startPulse() } else { skeleton.stopPulse() }
        if let model, let summary = model.summary {
            timeline.configure(summary: summary, offNotice: model.offNotice, rows: model.rows)
        }
    }

}

extension CommuterBusVC {
    private struct MapAppCandidate {
        let name: String
        let symbol: String
        let color: UIColor
        let url: URL?
    }

    private func updateLabel(
        _ label: UILabel,
        text: String,
        font: UIFont,
        color: UIColor,
        lineHeight: CGFloat,
        lineBreakMode: NSLineBreakMode = .byWordWrapping
    ) {
        label.attributedText = SettingsStyle.attributedText(
            text, font: font, color: color, lineHeight: lineHeight, alignment: label.textAlignment,
            lineBreakMode: lineBreakMode
        )
    }

    private func subtitle(for subtitle: CommuterPeriodSubtitle) -> String {
        switch subtitle {
        case .semester(let endDay):
            return String(localized: "commuter.period.semester_until.\(CommuterBusLogic.dayText(endDay))")
        case .weekdaysOnly:
            return String(localized: "commuter.period.weekdays_only")
        }
    }

    @objc
    private func appWillEnterForeground() { refreshClock() }

    @objc
    private func refreshPulled() {
        guard !usesFixture else { refreshControl.endRefreshing(); return }
        load()
    }

    @objc
    private func retryLoad() { load() }

    private func requestLocationAuthorizationIfNeeded() {
        guard locationManager.authorizationStatus == .notDetermined else { return }
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    private func load() {
        guard !isLoading else { return }
        isLoading = true
        loadFailed = false
        render()
        Task { @MainActor in
            let now = Foundation.Date()
            async
            let page = try? Network.shared.client.fetch(
                query: CommuterBusPageQuery(date: CommuterBusLogic.queryDateString(now)),
                cachePolicy: .networkOnly
            )
            async
            let location = IntentLocationProvider.currentLocation(timeout: 4)
            guard let data = await page?.data else {
                loadFailed = true
                isLoading = false
                render()
                refreshControl.endRefreshing()
                return
            }
            routes = CommuterBusLogic.routes(
                from: data.commute,
                korean: Bundle.main.preferredLocalizations.first == "ko"
            )
            let period = data.shuttle.period
            let periodType = period?.type
            let periodEndDay = period.flatMap { CommuterBusLogic.periodBoundaryDay($0.end) }
            let holidayType = data.shuttle.holiday?.type
            let nextRunDay = periodType == "semester" ? nil : await resolveNextSemesterDay(after: periodEndDay)
            let userLocation: ShuttleGeoCoordinate?
            if case .coordinate(let coordinate) = await location { userLocation = coordinate } else { userLocation = nil }
            context = CommuterServiceContext(
                date: now,
                nowMinutes: CommuterBusLogic.minutesOfDay(now),
                periodType: periodType,
                periodEndDay: periodEndDay,
                holidayType: holidayType,
                nextRunDay: nextRunDay,
                userLocation: userLocation
            )
            isLoading = false
            loadFailed = false
            render()
            refreshControl.endRefreshing()
        }
    }

    private func resolveNextSemesterDay(after periodEndDay: Foundation.Date?) async -> Foundation.Date? {
        var boundary = periodEndDay
        for _ in 0..<4 {
            guard let currentDay = boundary,
                  let next = CommuterBusLogic.calendar.date(byAdding: .day, value: 1, to: currentDay) else { return nil }
            let query = CommuterBusPeriodQuery(date: CommuterBusLogic.queryDateString(next))
            guard let data = try? await Network.shared.client.fetch(query: query, cachePolicy: .networkOnly).data,
                  let period = data.shuttle.period else { return nil }
            if period.type == "semester" {
                return CommuterBusLogic.firstWeekday(onOrAfter: CommuterBusLogic.periodBoundaryDay(period.start) ?? next)
            }
            boundary = CommuterBusLogic.periodBoundaryDay(period.end)
        }
        return nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways,
              !usesFixture else { return }
        Task { @MainActor in
            if case .coordinate(let coordinate) = await IntentLocationProvider.currentLocation(timeout: 4), var context {
                context.userLocation = coordinate
                self.context = context
                render()
            }
        }
    }

    private func openMap(for stop: CommuterStop) {
        guard stop.hasCoordinate else { return }
        let coordinate = CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = stop.name
        let apps = installedMapApps(for: stop)
        let choices = [CommuterMapChoice(
            name: String(localized: "commuter.map.apple"),
            symbol: "map.fill",
            brandColor: SettingsStyle.Color.link,
            action: { [self] in openAppleMaps(mapItem) }
        )] + apps
        present(CommuterMapChooserVC(stopName: stop.name, choices: choices), animated: true)
    }

    private func installedMapApps(for stop: CommuterStop) -> [CommuterMapChoice] {
        var naver = URLComponents(string: "nmap://route/public")
        naver?.queryItems = [
            URLQueryItem(name: "dlat", value: String(stop.latitude)),
            URLQueryItem(name: "dlng", value: String(stop.longitude)),
            URLQueryItem(name: "dname", value: stop.name),
            URLQueryItem(name: "appname", value: "net.jaram.hyuabot"),
        ]
        let coordinate = "\(stop.latitude),\(stop.longitude)"
        let candidates = [
            MapAppCandidate(
                name: String(localized: "commuter.map.naver"), symbol: "N",
                color: UIColor(red: 3 / 255, green: 199 / 255, blue: 90 / 255, alpha: 1), url: naver?.url
            ),
            MapAppCandidate(
                name: String(localized: "commuter.map.kakao"), symbol: "K",
                color: UIColor(red: 254 / 255, green: 229 / 255, blue: 0, alpha: 1),
                url: URL(string: "kakaomap://route?ep=\(coordinate)&by=PUBLICTRANSIT")
            ),
            MapAppCandidate(
                name: String(localized: "commuter.map.google"), symbol: "G",
                color: UIColor(red: 66 / 255, green: 133 / 255, blue: 244 / 255, alpha: 1),
                url: URL(string: "comgooglemaps://?daddr=\(coordinate)&directionsmode=transit")
            )
        ]
        return candidates.compactMap { candidate in
            guard let url = candidate.url, UIApplication.shared.canOpenURL(url) else { return nil }
            return CommuterMapChoice(name: candidate.name, symbol: candidate.symbol, brandColor: candidate.color) {
                UIApplication.shared.open(url) { [self] success in
                    if !success {
                        let fallbackItem = MKMapItem(placemark: MKPlacemark(
                        coordinate: CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
                        ))
                        fallbackItem.name = stop.name
                        openAppleMaps(fallbackItem)
                    }
                }
            }
        }
    }

    private func openAppleMaps(_ mapItem: MKMapItem) {
        guard !mapItem.openInMaps() else { return }
        var components = URLComponents(string: "http://maps.apple.com/")
        let coordinate = mapItem.placemark.coordinate
        components?.queryItems = [
            URLQueryItem(name: "ll", value: "\(coordinate.latitude),\(coordinate.longitude)"),
            URLQueryItem(name: "q", value: mapItem.name),
        ]
        if let url = components?.url { UIApplication.shared.open(url) }
    }
}

extension CommuterBusVC: @preconcurrency CLLocationManagerDelegate {}
