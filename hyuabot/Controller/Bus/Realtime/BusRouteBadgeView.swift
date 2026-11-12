//
//  BusRouteBadgeView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class BusRouteBadgeView: UIView {
    enum Size { case regular, small, timetable, shuttle }

    private let size: Size
    private let label = UILabel()

    init(size: Size) {
        self.size = size
        super.init(frame: .zero)
        isAccessibilityElement = false
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = size == .timetable
        label.minimumScaleFactor = 0.8
        addSubview(label)
        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }
        snp.makeConstraints { make in
            make.height.equalTo(height)
            if size == .timetable {
                make.width.equalTo(46)
            } else {
                make.width.greaterThanOrEqualTo(minimumWidth)
            }
        }
        layer.cornerRadius = cornerRadius
        if size == .shuttle { layer.cornerCurve = .continuous }
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: size == .timetable ? 46 : max(minimumWidth, label.intrinsicContentSize.width + 2 * horizontalPadding),
               height: height)
    }

    func configure(route: String) {
        label.attributedText = NSAttributedString(string: route, attributes: [.kern: -0.2])
        label.font = SettingsStyle.monospacedDigitFont(fontSize, bold: true)
        label.textColor = .white
        backgroundColor = BusDisplayLogic.routeColor(route)
        invalidateIntrinsicContentSize()
    }

    func configure(text: String, fill: UIColor) {
        label.attributedText = NSAttributedString(string: text, attributes: [.kern: -0.2])
        label.font = SettingsStyle.monospacedDigitFont(fontSize, bold: true)
        label.textColor = .white
        backgroundColor = fill
        invalidateIntrinsicContentSize()
    }

    static func shuttleFill(for kind: ShuttleDisplayLogic.RouteChipKind) -> UIColor {
        switch kind {
        case .direct: SettingsStyle.Color.shuttleRouteDirect
        case .circular: SettingsStyle.Color.shuttleRouteCircular
        case .jungang: SettingsStyle.Color.shuttleRouteJungang
        case .terminal: SettingsStyle.Color.shuttleRouteTerminal
        case .fallback: SettingsStyle.Color.shuttleRouteFallback
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var height: CGFloat { size == .regular ? 24 : 20 }
    private var minimumWidth: CGFloat { size == .regular ? 24 : size == .shuttle ? 44 : 20 }
    private var horizontalPadding: CGFloat {
        switch size {
        case .regular: 8
        case .small: 6
        case .timetable: 4
        case .shuttle: 6
        }
    }
    private var cornerRadius: CGFloat { size == .regular ? 12 : 6 }
    private var fontSize: CGFloat { size == .regular ? 13 : 12 }
}
