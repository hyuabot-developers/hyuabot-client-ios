import SnapKit
import Then
import UIKit

final class TodayHomeVC: UIViewController {
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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.home)
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        navigationItem.title = String(localized: "tabbar.home")

        view.addSubview(legacyBar)
        legacyBar.addSubview(legacyBarLabel)
        legacyBar.addSubview(legacyButton)

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
    }

    @objc private func openLegacyShuttle() {
        AnalyticsManager.logSelect(.homeOpenLegacyShuttle)
        (navigationController as? ShuttleNC)?.showLegacyShuttle()
    }
}
