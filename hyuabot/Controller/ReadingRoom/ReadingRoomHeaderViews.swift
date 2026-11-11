//
//  ReadingRoomHeaderViews.swift
//  hyuabot
//

import SnapKit
import UIKit

final class ReadingRoomStatusRowView: UIView {
    let refreshButton = UIButton(type: .system)
    var onRefresh: (() -> Void)?
    private let dotView = UIView()
    private let statusLabel = UILabel()
    private var isBusy = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        backgroundColor = .clear
        dotView.backgroundColor = SettingsStyle.Color.levelGood
        dotView.layer.cornerRadius = 4
        addSubview(dotView)
        dotView.snp.makeConstraints { make in
            make.size.equalTo(8)
            make.leading.centerY.equalToSuperview()
        }
        statusLabel.numberOfLines = 1
        statusLabel.adjustsFontForContentSizeCategory = true
        addSubview(statusLabel)
        let image = UIImage(systemName: "arrow.clockwise", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))
        refreshButton.setImage(image, for: .normal)
        refreshButton.tintColor = SettingsStyle.Color.link
        refreshButton.accessibilityLabel = String(localized: "reading_room.refresh.accessibility")
        refreshButton.accessibilityIdentifier = "reading_room.refresh"
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        addSubview(refreshButton)
        refreshButton.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(12)
        }
        statusLabel.snp.makeConstraints { make in
            make.leading.equalTo(dotView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(refreshButton.snp.leading).offset(-8)
        }
        snp.makeConstraints { $0.height.equalTo(32) }
        setStatus(updatedAt: nil, isBusy: false)
    }

    func setStatus(updatedAt: Foundation.Date?, isBusy: Bool) {
        self.isBusy = isBusy
        if isBusy {
            statusLabel.attributedText = SettingsStyle.attributedText(
                String(localized: "reading_room.status.loading"),
                font: SettingsStyle.monospacedDigitFont(13),
                color: SettingsStyle.Color.secondaryText,
                lineHeight: 18
            )
            dotView.isHidden = false
            dotView.backgroundColor = SettingsStyle.Color.secondaryText
            dotView.layer.removeAnimation(forKey: "readingRoomLivePulse")
            if !UIAccessibility.isReduceMotionEnabled { startRefreshSpinIfNeeded() }
        } else if let updatedAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let text = String(format: String(localized: "reading_room.status.updated.%@"), formatter.string(from: updatedAt))
            statusLabel.attributedText = SettingsStyle.attributedText(
                text,
                font: SettingsStyle.monospacedDigitFont(13),
                color: SettingsStyle.Color.secondaryText,
                lineHeight: 18
            )
            dotView.isHidden = false
            dotView.backgroundColor = SettingsStyle.Color.levelGood
            stopRefreshSpin()
            if !UIAccessibility.isReduceMotionEnabled { startDotPulseIfNeeded() }
        } else {
            statusLabel.attributedText = nil
            dotView.isHidden = true
            dotView.layer.removeAnimation(forKey: "readingRoomLivePulse")
            stopRefreshSpin()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil, !UIAccessibility.isReduceMotionEnabled else { return }
        if dotView.isHidden { return }
        if isBusy {
            startRefreshSpinIfNeeded()
        } else if !dotView.isHidden {
            startDotPulseIfNeeded()
        }
    }

    private func startDotPulseIfNeeded() {
        guard dotView.layer.animation(forKey: "readingRoomLivePulse") == nil else { return }
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0.35
        animation.duration = 1
        animation.autoreverses = true
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.repeatCount = .infinity
        dotView.layer.add(animation, forKey: "readingRoomLivePulse")
    }

    private func startRefreshSpinIfNeeded() {
        guard let layer = refreshButton.imageView?.layer, layer.animation(forKey: "readingRoomRefreshSpin") == nil else { return }
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = 2 * Double.pi
        animation.duration = 0.9
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.repeatCount = .infinity
        layer.add(animation, forKey: "readingRoomRefreshSpin")
    }

    private func stopRefreshSpin() {
        refreshButton.imageView?.layer.removeAnimation(forKey: "readingRoomRefreshSpin")
    }

    @objc
    private func refreshTapped() { onRefresh?() }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        super.point(inside: point, with: event) || refreshButton.frame.contains(point)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class ReadingRoomListFooterView: UIView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.attributedText = SettingsStyle.attributedText(
            String(localized: "reading_room.footer.bell_hint"),
            font: SettingsStyle.font(12.5),
            color: SettingsStyle.Color.secondaryText,
            lineHeight: 18
        )
        addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(HYUMetrics.Layout.contentToFootnote)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
