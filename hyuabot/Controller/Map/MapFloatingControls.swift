//
//  MapFloatingControls.swift
//  hyuabot
//

import SnapKit
import UIKit

final class MapStatusPillView: UIView {
    enum Status: Equatable {
        case loading
        case count(Int)
        case result
    }

    private let dotView = UIView()
    private let label = UILabel()

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 28)
    }

    init() {
        super.init(frame: .zero)
        configureView()
        configureContent()
        apply(.loading)
        updateLayerColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _: UITraitCollection) in
            view.updateLayerColors()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(_ status: Status) {
        dotView.layer.removeAnimation(forKey: "pulse")
        switch status {
        case .count(let count):
            label.text = String(format: String(localized: "map.status.count"), count)
            dotView.backgroundColor = SettingsStyle.Color.accent
        case .result:
            label.text = String(localized: "map.status.result")
            dotView.backgroundColor = SettingsStyle.Color.accent
        case .loading:
            label.text = String(localized: "map.status.loading")
            dotView.backgroundColor = SettingsStyle.Color.secondaryText
            addPulseIfAllowed()
        }
        accessibilityLabel = label.text
    }

    private func configureView() {
        backgroundColor = SettingsStyle.Color.card
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowRadius = 2
        layer.shadowOffset = CGSize(width: 0, height: 1)
        isAccessibilityElement = true
        accessibilityTraits = .staticText
    }

    private func configureContent() {
        let stack = UIStackView(arrangedSubviews: [dotView, label])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 6
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
        }
        dotView.layer.cornerRadius = 3.5
        dotView.layer.cornerCurve = .continuous
        dotView.snp.makeConstraints { $0.size.equalTo(7) }
        label.font = SettingsStyle.monospacedDigitFont(12.5)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = SettingsStyle.Color.secondaryText
        label.numberOfLines = 1
    }

    private func addPulseIfAllowed() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0.4
        animation.duration = 0.7
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.keyPath = "opacity"
        dotView.layer.add(animation, forKey: "pulse")
    }

    private func updateLayerColors() {
        layer.shadowColor = UIColor.black.resolvedColor(with: traitCollection).cgColor
    }
}

final class MapRecenterButton: UIButton {
    override var intrinsicContentSize: CGSize {
        CGSize(width: 44, height: 44)
    }

    init() {
        super.init(frame: .zero)
        backgroundColor = SettingsStyle.Color.card
        tintColor = SettingsStyle.Color.link
        let image = UIImage(systemName: "location", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold))
        setImage(image, for: .normal)
        layer.cornerRadius = 22
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.14
        layer.shadowRadius = 5
        layer.shadowOffset = CGSize(width: 0, height: 2)
        accessibilityLabel = String(localized: "map.recenter")
        updateLayerColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (button: Self, _: UITraitCollection) in
            button.updateLayerColors()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateLayerColors() {
        layer.shadowColor = UIColor.black.resolvedColor(with: traitCollection).cgColor
    }
}
