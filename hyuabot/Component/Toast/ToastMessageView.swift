import UIKit

final class ToastMessageView: UIView {
    private let toastImageView = UIImageView().then {
        $0.tintColor = .white
    }

    private let toastLabel = UILabel().then {
        $0.font = .godo(size: 14, weight: .medium)
        $0.textColor = .white
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .gray
        addSubview(toastImageView)
        addSubview(toastLabel)
        layer.do {
            $0.cornerRadius = 10
            $0.masksToBounds = true
        }
        toastImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }
        toastLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.toastImageView.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
        }
    }

    func configure(image: UIImage?, message: String) {
        toastImageView.image = image
        toastLabel.text = message
    }
}
