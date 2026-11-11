//
//  CampusVC.swift
//  hyuabot
//

import UIKit

enum CampusDestination: String {
    case commuterBus = "commuter_bus"
    case map
    case readingRoom = "reading_room"
    case calendar
    case contact
    case setting
    case inquiry
    case donate
}

final class CampusNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: CampusVC())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
    }

    func open(_ destination: CampusDestination, animated: Bool) {
        popToRootViewController(animated: false)
        guard let campusViewController = viewControllers.first as? CampusVC else { return }
        campusViewController.open(destination, animated: animated, logSelection: false)
    }

    private func configureNavigationBar() {
        let appearance = SettingsNavigationStyle.makeAppearance()
        navigationBar.standardAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.scrollEdgeAppearance = SettingsNavigationStyle.makeScrollEdgeAppearance()
        navigationBar.tintColor = SettingsStyle.Color.link
    }
}

final class CampusVC: UIViewController, SettingsStyledScreen {
    private struct ToolCardDetails {
        let title: String
        let subtitle: String
        let symbol: String
    }
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        SettingsNavigationStyle.screenWillAppear(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SettingsNavigationStyle.screenWillDisappear(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.campus)
    }

    func open(_ destination: CampusDestination, animated: Bool, logSelection: Bool = true) {
        if logSelection {
            AnalyticsManager.logSelect(
                .campusSelectTool,
                type: .listItem,
                name: destination.rawValue,
                destinationID: destination.rawValue
            )
        }
        let viewController: UIViewController
        switch destination {
        case .commuterBus:
            viewController = CommuterBusVC()
        case .map:
            viewController = MapVC()
        case .readingRoom:
            viewController = ReadingRoomVC()
        case .calendar:
            viewController = CalendarVC()
        case .contact:
            viewController = ContactVC()
        case .setting:
            viewController = SettingVC()
        case .inquiry:
            viewController = InquiryChatVC()
        case .donate:
            viewController = WebViewVC(url: URL(string: "https://qr.kakaopay.com/FWxVPo8iO")!)
        }
        navigationController?.pushViewController(viewController, animated: animated)
    }

    private func configureView() {
        title = String(localized: "tabbar.campus")
        view.backgroundColor = SettingsStyle.Color.background
        SettingsNavigationStyle.apply(to: self, largeTitle: true)
        scrollView.accessibilityIdentifier = "campus.scroll"
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .automatic
        contentStack.axis = .vertical
        contentStack.spacing = 0
    }

    private func configureLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 2),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                constant: -HYUMetrics.Layout.screenBottom
            )
        ])
        buildContent()
    }

    private func buildContent() {
        addContent(makeInsetLabel(
            String(localized: "campus.tools.subtitle"), font: SettingsStyle.font(14), lineHeight: 20
        ), spacing: HYUMetrics.Layout.controlToContent)
        addContent(makeSectionHeader(String(localized: "campus.tools.title")), spacing: 8)
        addContent(makeFeatureCard(), spacing: 10)
        addContent(makeToolRow(.map, .readingRoom), spacing: 10)
        addContent(makeToolRow(.calendar, .contact), spacing: 16)
        addContent(makeSectionHeader(String(localized: "campus.support.title")), spacing: 8)
        contentStack.addArrangedSubview(CampusSupportGroupView(rows: [
            makeSupportRow(.setting, title: String(localized: "campus.setting.title"), symbol: "gearshape.fill",
                           color: SettingsStyle.Color.supportIconGray),
            makeSupportRow(.inquiry, title: String(localized: "campus.inquiry.title"), symbol: "message.fill",
                           color: SettingsStyle.Color.supportIconBlue),
            makeSupportRow(.donate, title: String(localized: "tabbar.donate"), symbol: "heart.fill",
                           color: SettingsStyle.Color.supportIconPink, trailingSymbol: "arrow.up.right",
                           accessibilityLabel: String(localized: "campus.donate.accessibility_label"))
        ]))
    }

    private func addContent(_ view: UIView, spacing: CGFloat) {
        contentStack.addArrangedSubview(view)
        contentStack.setCustomSpacing(spacing, after: view)
    }

    private func makeInsetLabel(_ text: String, font: UIFont, lineHeight: CGFloat) -> UIView {
        let container = UIView()
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = SettingsStyle.attributedText(
            text, font: font, color: SettingsStyle.Color.secondaryText, lineHeight: lineHeight
        )
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4)
        ])
        return container
    }

    private func makeSectionHeader(_ text: String) -> UIView {
        let container = makeInsetLabel(text, font: SettingsStyle.font(13, bold: true), lineHeight: 18)
        (container.subviews.first as? UILabel)?.accessibilityTraits = .header
        return container
    }

    private func makeFeatureCard() -> CampusFeatureCardControl {
        let control = CampusFeatureCardControl(
            title: String(localized: "campus.commuter.title"),
            subtitle: String(localized: "campus.commuter.subtitle"),
            badge: String(localized: "campus.commuter.badge"),
            symbol: "point.topleft.down.to.point.bottomright.curvepath"
        )
        configure(control, for: .commuterBus)
        return control
    }

    private func makeToolRow(_ first: CampusDestination, _ second: CampusDestination) -> UIStackView {
        let row = UIStackView(arrangedSubviews: [makeToolCard(first), makeToolCard(second)])
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.alignment = .fill
        row.spacing = 10
        return row
    }

    private func makeToolCard(_ destination: CampusDestination) -> CampusToolCardControl {
        let details: ToolCardDetails
        switch destination {
        case .map:
            details = ToolCardDetails(title: String(localized: "campus.map.title"),
                                      subtitle: String(localized: "campus.map.subtitle"), symbol: "map")
        case .readingRoom:
            details = ToolCardDetails(title: String(localized: "campus.reading_room.title"),
                                      subtitle: String(localized: "campus.reading_room.subtitle"), symbol: "book")
        case .calendar:
            details = ToolCardDetails(title: String(localized: "campus.calendar.title"),
                                      subtitle: String(localized: "campus.calendar.subtitle"), symbol: "calendar")
        case .contact:
            details = ToolCardDetails(title: String(localized: "campus.contact.title"),
                                      subtitle: String(localized: "campus.contact.subtitle"), symbol: "phone")
        default:
            return CampusToolCardControl(title: "", subtitle: "", symbol: "")
        }
        let control = CampusToolCardControl(title: details.title, subtitle: details.subtitle, symbol: details.symbol)
        configure(control, for: destination)
        return control
    }

    private func makeSupportRow(_ destination: CampusDestination, title: String, symbol: String,
                                color: UIColor, trailingSymbol: String = "chevron.right",
                                accessibilityLabel: String? = nil) -> CampusSupportRowControl {
        let control = CampusSupportRowControl(title: title, symbol: symbol,
                                              iconBackground: color, trailingSymbol: trailingSymbol)
        configure(control, for: destination)
        if let accessibilityLabel { control.accessibilityLabel = accessibilityLabel }
        return control
    }

    private func configure(_ control: UIControl, for destination: CampusDestination) {
        control.accessibilityIdentifier = "campus.tool.\(destination.rawValue)"
        control.addAction(UIAction { [weak self] _ in
            self?.open(destination, animated: true)
        }, for: .touchUpInside)
    }
}
