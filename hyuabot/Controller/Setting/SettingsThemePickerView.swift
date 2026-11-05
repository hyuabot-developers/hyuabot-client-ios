//
//  SettingsThemePickerView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class SettingsThemePickerView: UIView {
    var onSelectTheme: ((Int) -> Void)?
    private let options = (0...2).map { themeID in
        let isDark = themeID == 2
        let isSystem = themeID == 0
        return ThemeOptionControl(
            themeID: themeID,
            screenColor: isDark ? ThemePreviewColors.darkScreen : ThemePreviewColors.lightScreen,
            barColor: isDark ? ThemePreviewColors.darkBar : ThemePreviewColors.lightBar,
            lineColor: isDark ? ThemePreviewColors.darkLine : ThemePreviewColors.lightLine,
            splitColor: isSystem ? ThemePreviewColors.darkScreen : nil
        )
    }

    init() {
        super.init(frame: .zero)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(11)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
        }
        let header = UIStackView()
        header.spacing = 12
        header.alignment = .center
        header.addArrangedSubview(SettingsIconTileView(symbolName: "circle.lefthalf.filled", color: SettingsStyle.Tile.indigo))
        let title = UILabel()
        title.font = SettingsStyle.font(16)
        title.textColor = SettingsStyle.Color.text
        title.text = String(localized: "setting.theme")
        header.addArrangedSubview(title)
        stack.addArrangedSubview(header)
        let row = UIStackView(arrangedSubviews: options)
        row.axis = .horizontal
        row.spacing = 10
        row.distribution = .fillEqually
        stack.addArrangedSubview(row)
        for option in options {
            option.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
        }
        setThemeID(0)
    }

    func setThemeID(_ themeID: Int) {
        options.forEach { $0.isSelected = $0.themeID == themeID }
    }

    @objc
    private func optionTapped(_ sender: ThemeOptionControl) {
        setThemeID(sender.themeID)
        onSelectTheme?(sender.themeID)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum ThemePreviewColors {
    static let lightScreen = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    static let darkScreen = UIColor(red: 22 / 255, green: 27 / 255, blue: 34 / 255, alpha: 1)
    static let lightBar = UIColor(red: 14 / 255, green: 74 / 255, blue: 132 / 255, alpha: 1)
    static let darkBar = UIColor(red: 127 / 255, green: 178 / 255, blue: 229 / 255, alpha: 1)
    static let lightLine = UIColor(red: 203 / 255, green: 213 / 255, blue: 225 / 255, alpha: 1)
    static let darkLine = UIColor(red: 58 / 255, green: 67 / 255, blue: 78 / 255, alpha: 1)
}

private final class ThemePreviewScreenView: UIView {
    private let splitLayer = CAShapeLayer()

    init(splitColor: UIColor?) {
        super.init(frame: .zero)
        layer.cornerRadius = 9
        layer.masksToBounds = true
        if let splitColor {
            splitLayer.fillColor = splitColor.cgColor
            layer.insertSublayer(splitLayer, at: 0)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard layer.sublayers?.contains(splitLayer) == true else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        splitLayer.frame = bounds
        // Overdraw by 1pt so the clipped edges never expose a seam.
        let path = UIBezierPath()
        path.move(to: CGPoint(x: bounds.maxX + 1, y: -1))
        path.addLine(to: CGPoint(x: bounds.maxX + 1, y: bounds.maxY + 1))
        path.addLine(to: CGPoint(x: -1, y: bounds.maxY + 1))
        path.close()
        splitLayer.path = path.cgPath
        CATransaction.commit()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class ThemeOptionControl: UIControl {
    let themeID: Int
    private let screenColor: UIColor
    private let barColor: UIColor
    private let lineColor: UIColor
    private let splitColor: UIColor?
    private let frameView = UIView()
    private let screen: ThemePreviewScreenView
    private let label = UILabel()
    private let labels = ["theme.system", "theme.light", "theme.dark"]

    init(themeID: Int, screenColor: UIColor, barColor: UIColor, lineColor: UIColor, splitColor: UIColor?) {
        self.themeID = themeID
        self.screenColor = screenColor
        self.barColor = barColor
        self.lineColor = lineColor
        self.splitColor = splitColor
        screen = ThemePreviewScreenView(splitColor: splitColor)
        super.init(frame: .zero)
        isAccessibilityElement = true
        let themeNames = ["system", "light", "dark"]
        accessibilityIdentifier = "setting.theme_option.\(themeNames[themeID])"
        accessibilityLabel = String(localized: String.LocalizationValue(labels[themeID]))
        accessibilityTraits = .button
        frameView.backgroundColor = SettingsStyle.Color.segmentBackground
        frameView.layer.cornerRadius = 14
        frameView.clipsToBounds = true
        addSubview(frameView)
        frameView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(frameView.snp.width).multipliedBy(1.05)
        }
        screen.backgroundColor = screenColor
        frameView.addSubview(screen)
        screen.snp.makeConstraints { $0.edges.equalToSuperview().inset(6) }
        let preview = UIStackView()
        preview.axis = .vertical
        preview.alignment = .center
        preview.spacing = 6
        screen.addSubview(preview)
        preview.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(10)
            make.leading.trailing.equalToSuperview().inset(8)
        }
        let bar = block(height: 7, radius: 4, color: barColor)
        let line = block(height: 5, radius: 3, color: lineColor)
        let line2 = block(height: 5, radius: 3, color: lineColor)
        preview.addArrangedSubview(bar)
        preview.addArrangedSubview(line)
        preview.addArrangedSubview(line2)
        bar.snp.makeConstraints { $0.width.equalTo(preview.snp.width).multipliedBy(0.6) }
        line.snp.makeConstraints { $0.width.equalTo(preview.snp.width).multipliedBy(0.85) }
        line2.snp.makeConstraints { $0.width.equalTo(preview.snp.width).multipliedBy(0.5) }
        label.text = String(localized: String.LocalizationValue(labels[themeID]))
        label.textAlignment = .center
        label.font = SettingsStyle.font(14)
        label.textColor = SettingsStyle.Color.secondaryText
        addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(frameView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.updateSelection()
            self.setNeedsLayout()
        }
        updateSelection()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha >= 0.01, bounds.contains(point) else { return nil }
        return self
    }

    override var isSelected: Bool {
        didSet {
            updateSelection()
            accessibilityTraits = isSelected ? [.button, .selected] : .button
        }
    }

    private func updateSelection() {
        frameView.layer.borderWidth = isSelected ? 2.5 : 1
        frameView.layer.borderColor = (isSelected ? SettingsStyle.Color.accent : SettingsStyle.Color.separator)
            .resolvedColor(with: traitCollection).cgColor
        label.font = SettingsStyle.font(14, bold: isSelected)
        label.textColor = isSelected ? SettingsStyle.Color.link : SettingsStyle.Color.secondaryText
    }

    private func block(height: CGFloat, radius: CGFloat, color: UIColor) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.layer.cornerRadius = radius
        view.snp.makeConstraints { $0.height.equalTo(height) }
        return view
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
