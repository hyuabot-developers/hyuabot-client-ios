//
//  CafeteriaWeekStripView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class CafeteriaWeekStripView: UIView, UIGestureRecognizerDelegate {
    var onSelectDate: ((Date) -> Void)?
    var onShiftWeek: ((Int) -> Void)?

    private let track = UIView()
    private let stack = UIStackView()
    private var days: [CafeteriaWeekDay] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        accessibilityIdentifier = "cafeteria.week_strip"
        backgroundColor = SettingsStyle.Color.card
        layer.cornerRadius = SettingsStyle.Metric.cardRadius
        clipsToBounds = true
        setupTrack()
        setupConstraints()
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
        pan.delegate = self
        addGestureRecognizer(pan)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTrack() {
        addSubview(track)
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 2
        track.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func setupConstraints() {
        track.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(4)
            make.top.bottom.equalToSuperview().inset(6)
        }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(68) }
    }

    func configure(days: [CafeteriaWeekDay], accessibilityLabel: String, slideDirection: Int) {
        self.days = days
        track.layer.removeAllAnimations()
        track.transform = .identity
        track.alpha = 1
        self.accessibilityLabel = accessibilityLabel
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, day) in days.enumerated() {
            let cell = makeDayCell(day, index: index)
            stack.addArrangedSubview(cell)
        }
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(
                name: String(localized: "cafeteria.week.previous"),
                target: self,
                selector: #selector(previousWeek)
            ),
            UIAccessibilityCustomAction(name: String(localized: "cafeteria.week.next"), target: self, selector: #selector(nextWeek))
        ]
        guard slideDirection != 0 else { return }
        track.transform = .identity
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        track.transform = CGAffineTransform(translationX: CGFloat(48 * slideDirection), y: 0)
        track.alpha = 0
        UIView.animate(withDuration: 0.24, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.track.transform = .identity
            self.track.alpha = 1
        }
    }

    private func makeDayCell(_ day: CafeteriaWeekDay, index: Int) -> UIControl {
        let cell = UIControl()
        cell.accessibilityIdentifier = "cafeteria.day.\(index)"
        cell.accessibilityLabel = dayAccessibilityLabel(day)
        cell.accessibilityTraits = day.isSelected ? [.button, .selected] : .button
        cell.tag = index
        cell.addTarget(self, action: #selector(dayTapped(_:)), for: .touchUpInside)
        let weekday = UILabel()
        weekday.adjustsFontForContentSizeCategory = true
        weekday.textAlignment = .center
        let weekdayText = day.isToday ? String(localized: "cafeteria.today") : Calendar.current
            .shortStandaloneWeekdaySymbols[day.weekday - 1]
        let weekdayColor: UIColor = day.isToday ? SettingsStyle.Color
            .link :
            (day.weekday == 1 ? SettingsStyle.Color
                .sunday : (day.weekday == 7 ? SettingsStyle.Color.weekSaturday : SettingsStyle.Color.secondaryText))
        weekday.attributedText = SettingsStyle.attributedText(
            weekdayText,
            font: SettingsStyle.font(12, bold: day.isToday),
            color: weekdayColor,
            lineHeight: 16,
            alignment: .center
        )
        let number = UILabel()
        number.adjustsFontForContentSizeCategory = true
        number.textAlignment = .center
        number.attributedText = SettingsStyle.attributedText(
            String(day.day),
            font: SettingsStyle.monospacedDigitFont(17, bold: true),
            color: day.isSelected ? SettingsStyle.Color.onAccent : (day.isToday ? SettingsStyle.Color.link : SettingsStyle.Color.text),
            lineHeight: 22,
            alignment: .center
        )
        number.backgroundColor = day.isSelected ? SettingsStyle.Color.accent : (day.isToday ? SettingsStyle.Color.accentFill : .clear)
        number.layer.cornerRadius = 17
        number.clipsToBounds = true
        let content = UIStackView(arrangedSubviews: [weekday, number])
        content.axis = .vertical
        content.alignment = .center
        content.spacing = 2
        content.isUserInteractionEnabled = false
        cell.addSubview(content)
        content.snp.makeConstraints { $0.center.equalToSuperview() }
        weekday.snp.makeConstraints { $0.height.greaterThanOrEqualTo(16) }
        number.snp.makeConstraints { $0.size.equalTo(34) }
        cell.snp.makeConstraints { $0.height.greaterThanOrEqualTo(56) }
        return cell
    }

    private func dayAccessibilityLabel(_ day: CafeteriaWeekDay) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMMdE", options: 0, locale: .current)
        let label = formatter.string(from: day.date)
        return day.isToday ? String(format: String(localized: "cafeteria.day.today.a11y.format"), label) : label
    }

    @objc
    private func dayTapped(_ sender: UIControl) {
        guard days.indices.contains(sender.tag) else { return }
        onSelectDate?(days[sender.tag].date)
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: self)
        return abs(velocity.x) > abs(velocity.y)
    }

    @objc
    private func panned(_ gesture: UIPanGestureRecognizer) {
        let dx = gesture.translation(in: self).x
        switch gesture.state {
        case .changed:
            track.transform = CGAffineTransform(translationX: 0.6 * dx, y: 0)
            track.alpha = 1 - min(abs(dx), 160) / 400
        case .ended:
            if abs(dx) >= 50 {
                onShiftWeek?(dx < 0 ? 1 : -1)
            } else {
                animateBack()
            }
        case .cancelled, .failed:
            animateBack()
        default: break
        }
    }

    private func animateBack() {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.track.transform = .identity
            self.track.alpha = 1
        }
    }

    @objc
    private func previousWeek() -> Bool {
        onShiftWeek?(-1); return true
    }

    @objc
    private func nextWeek() -> Bool {
        onShiftWeek?(1); return true
    }
}
