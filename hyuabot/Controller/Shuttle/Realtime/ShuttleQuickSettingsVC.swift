import SnapKit
import Then
import UIKit

final class ShuttleQuickSettingsVC: UIViewController {
    var openHome: (() -> Void)?
    var updateShowArrivalByTime: ((Bool) -> Void)?
    var updateShowDepartureTime: ((Bool) -> Void)?
    let preferredSheetHeight: CGFloat = 330

    private let contentStack = UIStackView()
    private let showArrivalByTimeSwitch = UISwitch()
    private let showDepartureTimeSwitch = UISwitch()

    init(showArrivalByTime: Bool, showDepartureTime: Bool) {
        showArrivalByTimeSwitch.isOn = showArrivalByTime
        showDepartureTimeSwitch.isOn = showDepartureTime
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.layoutMargins = UIEdgeInsets(top: 22, left: 20, bottom: 24, right: 20)
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide)
        }

        let title = UILabel()
        title.text = String(localized: "shuttle.quick_settings.title")
        title.font = .godo(size: 20, weight: .bold)
        title.textColor = .label

        showArrivalByTimeSwitch.addTarget(self, action: #selector(onChangeArrivalByTime), for: .valueChanged)
        showDepartureTimeSwitch.addTarget(self, action: #selector(onChangeDepartureTime), for: .valueChanged)

        contentStack.addArrangedSubview(title)
        contentStack.addArrangedSubview(settingRow(
            title: String(localized: "shuttle.realtime.showByDestination"),
            subtitle: String(localized: "shuttle.quick_settings.arrival_by_time.subtitle"),
            control: showArrivalByTimeSwitch,
            identifier: "shuttle.quick_settings.arrival_by_time_row"
        ))
        contentStack.addArrangedSubview(settingRow(
            title: String(localized: "shuttle.realtime.showDepartureTime"),
            subtitle: String(localized: "shuttle.quick_settings.departure_time.subtitle"),
            control: showDepartureTimeSwitch,
            identifier: "shuttle.quick_settings.departure_time_row"
        ))
        contentStack.addArrangedSubview(homeActionRow())
    }

    private func settingRow(title: String, subtitle: String, control: UISwitch, identifier: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.accessibilityIdentifier = identifier
        row.isAccessibilityElement = true
        row.layoutMargins = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        row.isLayoutMarginsRelativeArrangement = true
        row.backgroundColor = .secondarySystemBackground
        row.layer.cornerRadius = 8

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 4

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .godo(size: 16, weight: .bold)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .godo(size: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        row.addArrangedSubview(textStack)
        row.addArrangedSubview(control)
        row.snp.makeConstraints { make in
            make.height.equalTo(76)
        }
        row.setContentHuggingPriority(.required, for: .vertical)
        row.setContentCompressionResistancePriority(.required, for: .vertical)
        return row
    }

    private func homeActionRow() -> UIView {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.tinted()
        config.baseForegroundColor = .hanyangBlue
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "house.fill")
        config.attributedTitle = AttributedString(String(localized: "home.experience_new"), attributes: AttributeContainer([
            .font: UIFont.godo(size: 17, weight: .bold)
        ]))
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        button.configuration = config
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(onTapHome), for: .touchUpInside)
        button.accessibilityIdentifier = "shuttle.quick_settings.open_home"
        button.snp.makeConstraints { make in
            make.height.equalTo(52)
        }
        button.setContentHuggingPriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        return button
    }

    @objc private func onTapHome() {
        dismiss(animated: true) { [weak self] in
            self?.openHome?()
        }
    }

    @objc private func onChangeArrivalByTime() {
        updateShowArrivalByTime?(showArrivalByTimeSwitch.isOn)
    }

    @objc private func onChangeDepartureTime() {
        updateShowDepartureTime?(showDepartureTimeSwitch.isOn)
    }
}
