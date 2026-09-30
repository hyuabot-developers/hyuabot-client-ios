//
//  TransitStatusView.swift
//  hyuabot
//

import UIKit

final class TransitStatusView: UIView {
    var onRetry: (() -> Void)?

    private let statusLabel = UILabel().then {
        $0.font = .godo(size: 13, weight: .regular)
        $0.textColor = .label
        $0.numberOfLines = 0
    }

    private lazy var retryButton = UIButton(type: .system).then {
        $0.setTitle(String(localized: "transit.retry"), for: .normal)
        $0.titleLabel?.font = .godo(size: 13, weight: .bold)
        $0.addTarget(self, action: #selector(retry), for: .touchUpInside)
        $0.isHidden = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        let stack = UIStackView(arrangedSubviews: [statusLabel, retryButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.verticalEdges.equalToSuperview().inset(4)
        }
        retryButton.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(44)
        }
        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(48)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(_ text: String, retry: Bool = false) {
        statusLabel.text = text
        retryButton.isHidden = !retry
    }

    @objc
    private func retry() {
        onRetry?()
    }
}
