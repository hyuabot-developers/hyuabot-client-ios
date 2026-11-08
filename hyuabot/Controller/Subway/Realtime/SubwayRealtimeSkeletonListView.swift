//
//  SubwayRealtimeSkeletonListView.swift
//  hyuabot
//
import SnapKit
import UIKit

final class SubwayRealtimeSkeletonListView: UIView {
    private let stack = UIStackView()
    private var bars: [UIView] = []
    private var animator: UIViewPropertyAnimator?

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .vertical
        stack.spacing = 16
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        for _ in 0 ..< 2 {
            stack.addArrangedSubview(makeCard())
        }
        isAccessibilityElement = false
        accessibilityIdentifier = "subway.skeleton"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        setAnimating(window != nil)
    }

    func setAnimating(_ animating: Bool) {
        guard animating else { animator?.stopAnimation(true); animator = nil; bars.forEach { $0.alpha = 1 }; return }
        guard animator == nil else { return }
        let animation = UIViewPropertyAnimator(duration: 0.85, curve: .easeInOut) { self.bars.forEach { $0.alpha = 0.35 } }
        animation.addCompletion { [weak self] _ in
            guard let self, window != nil else { self?.animator = nil; return }
            bars.forEach { $0.alpha = 1 }
            animator = nil
            setAnimating(true)
        }
        animator = animation
        animation.startAnimation()
    }

    private func makeCard() -> UIView {
        let card = UIView()
        card.backgroundColor = SettingsStyle.Color.card
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        let header = UIView()
        card.addSubview(header)
        header.snp
            .makeConstraints {
                $0.top.equalToSuperview().offset(14); $0.leading.trailing.equalToSuperview().inset(16); $0.height.equalTo(36)
            }
        let badge = bar(width: 24, height: 24, radius: 12)
        header.addSubview(badge)
        badge.snp.makeConstraints { $0.leading.centerY.equalToSuperview() }
        let heading = UIStackView(arrangedSubviews: [bar(width: 0, height: 14, radius: 7), bar(width: 0, height: 12, radius: 6)])
        heading.axis = .vertical
        heading.spacing = 6
        header.addSubview(heading)
        heading.snp
            .makeConstraints {
                $0.leading.equalTo(badge.snp.trailing).offset(10); $0.centerY.equalToSuperview(); $0.width.equalToSuperview()
                    .multipliedBy(0.52)
            }
        (heading.arrangedSubviews[0]).snp.makeConstraints { $0.width.equalTo(heading.snp.width).multipliedBy(0.52) }
        (heading.arrangedSubviews[1]).snp.makeConstraints { $0.width.equalTo(heading.snp.width).multipliedBy(0.2) }
        let separator = UIView()
        separator.backgroundColor = SettingsStyle.Color.separator
        card.addSubview(separator)
        separator.snp
            .makeConstraints { $0.top.equalTo(header.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview(); $0.height.equalTo(1) }
        let rows = UIStackView()
        rows.axis = .vertical
        card.addSubview(rows)
        rows.snp.makeConstraints { $0.top.equalTo(separator.snp.bottom); $0.leading.trailing.bottom.equalToSuperview() }
        let widths: [(CGFloat, CGFloat)] = [(0.46, 0.30), (0.38, 0.36), (0.52, 0.26)]
        for (primaryWidth, secondaryWidth) in widths {
            let row = UIView()
            rows.addArrangedSubview(row)
            row.snp.makeConstraints { $0.height.equalTo(64) }
            let labels = UIStackView(arrangedSubviews: [bar(width: 0, height: 16, radius: 8), bar(width: 0, height: 12, radius: 6)])
            labels.axis = .vertical
            labels.spacing = 8
            row.addSubview(labels)
            labels.snp
                .makeConstraints {
                    $0.leading.equalToSuperview().inset(16); $0.centerY.equalToSuperview(); $0.width.equalToSuperview().offset(-92)
                }
            labels.arrangedSubviews[0].snp.makeConstraints { $0.width.equalTo(labels.snp.width).multipliedBy(primaryWidth) }
            labels.arrangedSubviews[1].snp.makeConstraints { $0.width.equalTo(labels.snp.width).multipliedBy(secondaryWidth) }
            let trailing = bar(width: 44, height: 20, radius: 8)
            row.addSubview(trailing)
            trailing.snp.makeConstraints { $0.trailing.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }
        }
        return card
    }

    private func bar(width: CGFloat, height: CGFloat, radius: CGFloat) -> UIView {
        let view = UIView()
        view.backgroundColor = SettingsStyle.Color.segmentBackground
        view.layer.cornerRadius = radius
        if width > 0 {
            view.snp.makeConstraints { $0.width.equalTo(width) }
        }
        view.snp.makeConstraints { $0.height.equalTo(height) }
        bars.append(view)
        return view
    }
}
