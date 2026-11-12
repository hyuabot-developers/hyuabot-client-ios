//
//  ShuttleRealtimeHeaderView.swift
//  hyuabot
//

import UIKit

class ShuttleRealtimeHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "ShuttleRealtimeHeaderView"
    static let headerHeight: CGFloat = 48

    var onToggle: ((Bool) -> Void)?
    private(set) var isExpanded: Bool = false
    private var routeAdapter: ShuttleRouteAdapter?

    private let titleLabel = UILabel().then {
        $0.textColor = SettingsStyle.Color.text
        $0.textAlignment = .left
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
        $0.accessibilityTraits = .header
    }

    let routeToggleButton = UIButton(type: .system)
    var helpImageView: UIView {
        routeToggleButton
    }

    private let titleRow = UIView()
    private let routeTopSeparator = UIView()
    private let routeBottomSeparator = UIView()
    private let routeAdapterContainer = UIView()
    private let cardContainer = UIView()
    private let foldableView = UIStackView()

    var routeAdapterHeight: CGFloat {
        guard let routeAdapter else { return 0 }
        let width = max((superview?.bounds.width ?? UIScreen.main.bounds.width) - 32 - 32, 0)
        let fitted = routeAdapter.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        return fitted + 12 + 14 + 1
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundView = UIView()
        backgroundView?.backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardContainer.backgroundColor = SettingsStyle.Color.card
        cardContainer.layer.cornerRadius = 16
        cardContainer.layer.cornerCurve = .continuous
        cardContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardContainer.clipsToBounds = true
        contentView.addSubview(cardContainer)
        cardContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview()
        }

        foldableView.axis = .vertical
        foldableView.spacing = 0
        cardContainer.addSubview(foldableView)
        foldableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let font = SettingsStyle.font(15, bold: true)
        titleLabel.attributedText = SettingsStyle.attributedText("", font: font, color: SettingsStyle.Color.text, lineHeight: 20)
        foldableView.addArrangedSubview(titleRow)
        titleRow.snp.makeConstraints { make in
            make.height.equalTo(Self.headerHeight)
        }
        titleRow.addSubview(titleLabel)

        configureRouteToggleButton()
        routeToggleButton.accessibilityIdentifier = "shuttle.section.route_toggle"
        routeToggleButton.addTarget(self, action: #selector(toggleRouteAdapter), for: .touchUpInside)
        titleRow.addSubview(routeToggleButton)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualTo(routeToggleButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
        routeToggleButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.greaterThanOrEqualTo(44)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
        }

        routeTopSeparator.backgroundColor = SettingsStyle.Color.separator
        routeBottomSeparator.backgroundColor = SettingsStyle.Color.separator
        routeAdapterContainer.backgroundColor = SettingsStyle.Color.inset
        routeAdapterContainer.addSubview(routeTopSeparator)
        routeAdapterContainer.addSubview(routeBottomSeparator)
        foldableView.addArrangedSubview(routeAdapterContainer)
        routeAdapterContainer.isHidden = true
    }

    private func configureRouteToggleButton() {
        var configuration = UIButton.Configuration.plain()
        configuration.title = String(localized: "shuttle.realtime.route_map")
        configuration.image = UIImage(
            systemName: "chevron.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        )
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 4
        configuration.contentInsets = .zero
        var title = AttributedString(String(localized: "shuttle.realtime.route_map"))
        title.font = SettingsStyle.font(13, bold: true)
        title.foregroundColor = SettingsStyle.Color.link
        configuration.attributedTitle = title
        routeToggleButton.configuration = configuration
    }

    func setupUI(title: String, stop: ShuttleStopEnum, section: Int, isExpanded: Bool = false) {
        self.isExpanded = isExpanded
        routeAdapter?.removeFromSuperview()
        routeAdapter = nil

        let routeAdapter = ShuttleRealtimeHeaderRoutes.adapter(stop: stop, section: section)
        self.routeAdapter = routeAdapter
        routeAdapter.isHidden = false
        routeAdapterContainer.addSubview(routeAdapter)
        routeAdapter.snp.makeConstraints { make in
            make.top.equalTo(routeTopSeparator.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(routeBottomSeparator.snp.top).offset(-14)
        }
        routeTopSeparator.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        routeBottomSeparator.snp.remakeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        routeAdapterContainer.isHidden = !isExpanded
        updateToggleImage()
        titleLabel.attributedText = SettingsStyle.attributedText(
            title,
            font: SettingsStyle.font(15, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 20,
            lineBreakMode: .byTruncatingTail
        )
    }

    func collapse() {
        guard isExpanded, let routeAdapter else { return }
        isExpanded = false
        routeAdapterContainer.isHidden = true
        routeAdapter.isHidden = true
        updateToggleImage()
        onToggle?(false)
    }

    @objc
    private func toggleRouteAdapter() {
        AnalyticsManager.logSelect(.shuttleRouteToggle)
        guard let routeAdapter else { return }
        isExpanded.toggle()
        routeAdapterContainer.isHidden = !isExpanded
        routeAdapter.isHidden = false
        updateToggleImage()
        onToggle?(isExpanded)
        if let tableView = superview as? UITableView {
            UIView.performWithoutAnimation {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
    }

    private func updateToggleImage() {
        routeToggleButton.configuration?.image = UIImage(
            systemName: isExpanded ? "chevron.up" : "chevron.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        )
    }
}
