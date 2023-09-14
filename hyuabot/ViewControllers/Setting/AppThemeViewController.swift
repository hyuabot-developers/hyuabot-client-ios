import Foundation
import UIKit

class AppThemeViewController: UIViewController {
    var theme: Int = -1
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)

        return view
    }()

    private lazy var containerStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 12.0
        view.alignment = .center

        return view
    }()

    private lazy var buttonStackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 14.0
        view.distribution = .fillEqually

        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .godo(size: 18.0, weight: .bold)
        label.numberOfLines = 0
        label.textColor = .black
        label.text = String.localizedSettingsItem(resourceID: "app.theme")
        return label
    }()
    
    private lazy var lightModeButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        let button = UIButton(configuration: configuration)
        button.setTitle(String.localizedSettingsItem(resourceID: "app.theme.light"), for: .normal)
        button.addTarget(self, action: #selector(lightModeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var darkModeButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        let button = UIButton(configuration: configuration)
        button.setTitle(String.localizedSettingsItem(resourceID: "app.theme.dark"), for: .normal)
        button.addTarget(self, action: #selector(darkModeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var systemModeButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        let button = UIButton(configuration: configuration)
        button.setTitle(String.localizedSettingsItem(resourceID: "app.theme.system"), for: .normal)
        button.addTarget(self, action: #selector(systemModeButtonTapped), for: .touchUpInside)
        return button
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        addSubviews()
        makeConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut) { [weak self] in
            self?.containerView.transform = .identity
            self?.containerView.isHidden = false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseIn) { [weak self] in
            self?.containerView.transform = .identity
            self?.containerView.isHidden = true
        }
    }

    private func setupViews() {
        view.addSubview(containerView)
        containerView.addSubview(containerStackView)
        view.backgroundColor = .black.withAlphaComponent(0.2)
    }

    private func addSubviews() {
        view.addSubview(containerStackView)
        containerStackView.addArrangedSubview(titleLabel)
        containerStackView.addArrangedSubview(lightModeButton)
        containerStackView.addArrangedSubview(darkModeButton)
        containerStackView.addArrangedSubview(systemModeButton)
    }

    private func makeConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26),
            containerView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 32),
            containerView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -32),

            containerStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            containerStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            containerStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            containerStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
        ])
    }
    
    @objc func lightModeButtonTapped() {
        theme = 0
        okButtonTapped()
    }
    
    @objc func darkModeButtonTapped() {
        theme = 1
        okButtonTapped()
    }
    
    @objc func systemModeButtonTapped() {
        theme = 2
        okButtonTapped()
    }
    
    @objc func okButtonTapped() {
        dismiss(animated: true, completion: nil)
        if theme == -1 {
            return
        }
        
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        guard let window = windowScene?.windows.first else { return }
        switch theme {
            case 0:
                UserDefaults.standard.set("light", forKey: "theme")
                window.overrideUserInterfaceStyle = .light
            case 1:
                UserDefaults.standard.set("dark", forKey: "theme")
                window.overrideUserInterfaceStyle = .dark
            case 2:
                UserDefaults.standard.set("system", forKey: "theme")
                window.overrideUserInterfaceStyle = .unspecified
            default:
                break
        }
    }
    
    @objc func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}
