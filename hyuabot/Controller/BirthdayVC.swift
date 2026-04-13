import UIKit
import RxSwift


class BirthdayVC: UIViewController {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let disposeBag = DisposeBag()
    let currentYear = Calendar.current.component(.year, from: Date())
    var backgroundClicked: (() -> Void)?

    private let dialogTitle: UILabel = {
        let label = UILabel()
        label.text = String(localized: "birthday.title")
        label.font = UIFont.godo(size: 18, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private lazy var dialogMessage: UILabel = {
        let label = UILabel()
        label.text = String(localized: "birthday.content.\(currentYear - 2017).\(String(currentYear))")
        label.font = UIFont.godo(size: 16, weight: .regular)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private lazy var dialogMessageView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.addSubview(self.dialogMessage)
        NSLayoutConstraint.activate([
            dialogMessage.topAnchor.constraint(equalTo: $0.topAnchor, constant: 12),
            dialogMessage.leadingAnchor.constraint(equalTo: $0.leadingAnchor, constant: 12),
            dialogMessage.trailingAnchor.constraint(equalTo: $0.trailingAnchor, constant: -12),
            dialogMessage.bottomAnchor.constraint(equalTo: $0.bottomAnchor, constant: -12),
        ])
    }
    private lazy var dialogStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [dialogTitle, dialogMessageView])
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dialogMessageView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        return stackView
    }()
    private lazy var doNotShowCheckbox: UIButton = {
        var configuration = UIButton.Configuration.plain()
        
        let title = String(localized: "birthday.dont.show.again")
        configuration.title = title
        configuration.baseForegroundColor = .white
        var attributedTitle = AttributedString(title)
        attributedTitle.font = UIFont.godo(size: 14, weight: .regular)
        configuration.attributedTitle = attributedTitle
        configuration.image = UIImage(systemName: "square")
        configuration.imagePlacement = .leading
        configuration.imagePadding = 4.0
        
        let button = UIButton(configuration: configuration, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(onDoNotShowCheckboxTapped), for: .touchUpInside)
        button.configurationUpdateHandler = { button in
            var updatedConfig = button.configuration
            if button.isSelected {
                updatedConfig?.image = UIImage(systemName: "checkmark.square.fill")
            } else {
                updatedConfig?.image = UIImage(systemName: "square")
            }
            button.configuration = updatedConfig
        }
        return button
    }()
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(String(localized: "close"), for: .normal)
        button.titleLabel?.font = UIFont.godo(size: 16, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(onBackgroundClicked), for: .touchUpInside)
        return button
    }()
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.hanyangBlue
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
        view.addSubview(self.dialogStackView)
        view.addSubview(self.doNotShowCheckbox)
        view.addSubview(self.closeButton)
        NSLayoutConstraint.activate([
            dialogStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            dialogStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dialogStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dialogStackView.widthAnchor.constraint(equalTo: view.widthAnchor),
            doNotShowCheckbox.topAnchor.constraint(equalTo: dialogStackView.bottomAnchor, constant: 8),
            doNotShowCheckbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            doNotShowCheckbox.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            closeButton.centerYAnchor.constraint(equalTo: doNotShowCheckbox.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
        ])
        return view
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onBackgroundClicked)))
        self.view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            contentView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8),
        ])
    }
    
    @objc private func onBackgroundClicked() {
        self.dismiss(animated: true, completion: nil)
        if (backgroundClicked != nil) {
            backgroundClicked!()
        }
    }
    
    @objc private func onDoNotShowCheckboxTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        if sender.isSelected {
            UserDefaults.standard.set(true, forKey: "hideBirthdayPopup\(currentYear)")
        } else {
            UserDefaults.standard.set(false, forKey: "hideBirthdayPopup\(currentYear)")
        }
    }
}
