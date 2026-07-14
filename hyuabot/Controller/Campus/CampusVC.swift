//
//  CampusVC.swift
//  hyuabot
//

import UIKit

enum CampusDestination: String {
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

    func open(_ destination: CampusDestination, animated: Bool) {
        popToRootViewController(animated: false)
        guard let campusViewController = viewControllers.first as? CampusVC else { return }
        campusViewController.open(destination, animated: animated, logSelection: false)
    }
}

final class CampusVC: UIViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
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

        let viewController: UIViewController = switch destination {
        case .map:
            MapVC()
        case .readingRoom:
            ReadingRoomVC()
        case .calendar:
            CalendarVC()
        case .contact:
            ContactVC()
        case .setting:
            SettingVC()
        case .inquiry:
            WebViewVC(url: URL(string: "https://open.kakao.com/o/sW2kAinb")!)
        case .donate:
            WebViewVC(url: URL(string: "https://qr.kakaopay.com/FWxVPo8iO")!)
        }
        navigationController?.pushViewController(viewController, animated: animated)
    }

    private func configureView() {
        title = String(localized: "tabbar.campus")
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground
        scrollView.alwaysBounceVertical = true
        scrollView.accessibilityIdentifier = "campus.scroll"
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        configureHierarchy()
        configureContent()
        configureConstraints()
    }

    private func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
    }

    private func configureContent() {
        configureHeader()
        let finalToolRow = configurePrimaryTools()
        configureSupportSection(after: finalToolRow)
    }

    private func configureHeader() {
        let titleLabel = makeLabel(
            text: String(localized: "campus.tools.title"),
            size: 24,
            weight: .bold,
            color: .label,
            textStyle: .title2
        )
        let subtitleLabel = makeLabel(
            text: String(localized: "campus.tools.subtitle"),
            size: 15,
            weight: .regular,
            color: .secondaryLabel,
            textStyle: .subheadline
        )
        contentStack.addArrangedSubview(titleLabel)
        contentStack.setCustomSpacing(4, after: titleLabel)
        contentStack.addArrangedSubview(subtitleLabel)
        contentStack.setCustomSpacing(20, after: subtitleLabel)
    }

    private func configurePrimaryTools() -> UIStackView {
        let firstToolRow = makeToolRow(
            first: makeTool(
                destination: .map,
                titleKey: "campus.map.title",
                subtitleKey: "campus.map.subtitle",
                symbol: "map.fill"
            ),
            second: makeTool(
                destination: .readingRoom,
                titleKey: "campus.reading_room.title",
                subtitleKey: "campus.reading_room.subtitle",
                symbol: "book.fill"
            )
        )
        let secondToolRow = makeToolRow(
            first: makeTool(
                destination: .calendar,
                titleKey: "campus.calendar.title",
                subtitleKey: "campus.calendar.subtitle",
                symbol: "calendar"
            ),
            second: makeTool(
                destination: .contact,
                titleKey: "campus.contact.title",
                subtitleKey: "campus.contact.subtitle",
                symbol: "phone.fill"
            )
        )
        contentStack.addArrangedSubview(firstToolRow)
        contentStack.addArrangedSubview(secondToolRow)
        return secondToolRow
    }

    private func configureSupportSection(after finalToolRow: UIStackView) {
        let supportLabel = makeLabel(
            text: String(localized: "campus.support.title"),
            size: 17,
            weight: .bold,
            color: .label,
            textStyle: .headline
        )
        contentStack.setCustomSpacing(24, after: finalToolRow)
        contentStack.addArrangedSubview(supportLabel)
        contentStack.setCustomSpacing(4, after: supportLabel)

        let supportStack = UIStackView(arrangedSubviews: [
            makeSupportRow(destination: .setting, titleKey: "campus.setting.title", symbol: "gearshape.fill"),
            makeSupportRow(destination: .inquiry, titleKey: "campus.inquiry.title", symbol: "message.fill"),
            makeSupportRow(destination: .donate, titleKey: "tabbar.donate", symbol: "heart.fill")
        ])
        supportStack.axis = .vertical
        supportStack.spacing = 1
        supportStack.layer.cornerRadius = 16
        supportStack.layer.cornerCurve = .continuous
        supportStack.clipsToBounds = true
        contentStack.addArrangedSubview(supportStack)
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32)
        ])
    }

    private func makeToolRow(first: CampusToolControl, second: CampusToolControl) -> UIStackView {
        let row = UIStackView(arrangedSubviews: [first, second])
        row.axis = .horizontal
        row.alignment = .fill
        row.distribution = .fillEqually
        row.spacing = 12
        row.heightAnchor.constraint(greaterThanOrEqualToConstant: 154).isActive = true
        return row
    }

    private func makeTool(
        destination: CampusDestination,
        titleKey: LocalizedStringResource,
        subtitleKey: LocalizedStringResource,
        symbol: String
    ) -> CampusToolControl {
        let control = CampusToolControl(
            title: String(localized: titleKey),
            subtitle: String(localized: subtitleKey),
            symbol: symbol
        )
        control.accessibilityIdentifier = "campus.tool.\(destination.rawValue)"
        control.addAction(UIAction { [weak self] _ in
            self?.open(destination, animated: true)
        }, for: .touchUpInside)
        return control
    }

    private func makeSupportRow(
        destination: CampusDestination,
        titleKey: LocalizedStringResource,
        symbol: String
    ) -> CampusSupportControl {
        let control = CampusSupportControl(title: String(localized: titleKey), symbol: symbol)
        control.accessibilityIdentifier = "campus.tool.\(destination.rawValue)"
        control.addAction(UIAction { [weak self] _ in
            self?.open(destination, animated: true)
        }, for: .touchUpInside)
        return control
    }

    private func makeLabel(
        text: String,
        size: CGFloat,
        weight: UIFont.Weight,
        color: UIColor,
        textStyle: UIFont.TextStyle
    ) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFontMetrics(forTextStyle: textStyle).scaledFont(for: .godo(size: size, weight: weight))
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.numberOfLines = 0
        return label
    }
}

private final class CampusToolControl: UIControl {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    init(title: String, subtitle: String, symbol: String) {
        super.init(frame: .zero)
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = title
        accessibilityValue = subtitle
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 1 / UIScreen.main.scale
        layer.borderColor = UIColor.separator.cgColor

        let imageContainer = UIView()
        imageContainer.backgroundColor = .campusIconBackground
        imageContainer.layer.cornerRadius = 12
        imageContainer.layer.cornerCurve = .continuous
        imageContainer.isUserInteractionEnabled = false
        imageContainer.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(image: UIImage(systemName: symbol))
        imageView.tintColor = .campusIconTint
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.addSubview(imageView)

        titleLabel.text = title
        titleLabel.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .godo(size: 16, weight: .bold))
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2

        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .godo(size: 13, weight: .regular))
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 3

        let stack = UIStackView(arrangedSubviews: [imageContainer, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.setCustomSpacing(12, after: imageContainer)
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            imageContainer.widthAnchor.constraint(equalToConstant: 40),
            imageContainer.heightAnchor.constraint(equalToConstant: 40),
            imageView.widthAnchor.constraint(equalToConstant: 21),
            imageView.heightAnchor.constraint(equalToConstant: 21),
            imageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 154)
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.alpha = self.isHighlighted ? 0.65 : 1
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = UIColor.separator.cgColor
        }
    }
}

private final class CampusSupportControl: UIControl {
    init(title: String, symbol: String) {
        super.init(frame: .zero)
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = title
        backgroundColor = .secondarySystemGroupedBackground

        let imageView = UIImageView(image: UIImage(systemName: symbol))
        imageView.tintColor = .campusIconTint
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.textColor = .label
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .godo(size: 16, weight: .regular))
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false

        for subview in [imageView, label, chevron] {
            subview.isUserInteractionEnabled = false
            addSubview(subview)
        }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 54),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 22),
            imageView.heightAnchor.constraint(equalToConstant: 22),
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 14),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevron.leadingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor, constant: 12),
            chevron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 8),
            chevron.heightAnchor.constraint(equalToConstant: 14)
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .tertiarySystemFill : .secondarySystemGroupedBackground
        }
    }
}

extension UIColor {
    static let campusIconBackground = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 23 / 255, green: 50 / 255, blue: 77 / 255, alpha: 1)
            : UIColor(red: 228 / 255, green: 239 / 255, blue: 248 / 255, alpha: 1)
    }

    static let campusIconTint = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 214 / 255, green: 236 / 255, blue: 1, alpha: 1)
            : UIColor(red: 14 / 255, green: 74 / 255, blue: 132 / 255, alpha: 1)
    }
}
