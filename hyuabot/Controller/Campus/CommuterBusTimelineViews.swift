//
//  CommuterBusTimelineViews.swift
//  hyuabot
//

// swiftlint:disable file_length
import UIKit

private enum CommuterDashStyle { case traveled, soft }

private final class CommuterRailView: UIView {
  private let lineTop: CommuterRailStyle?
  private let lineBottom: CommuterRailStyle?
  private let dotSize: CGFloat
  private let dotStyle: CommuterDotStyle?
  private let dashStyle: CommuterDashStyle?
  private let dashPattern: [NSNumber]
  private let topLayer = CAShapeLayer()
  private let bottomLayer = CAShapeLayer()
  private let dotLayer = CAShapeLayer()
  private let dashLayer = CAShapeLayer()

  init(
    lineTop: CommuterRailStyle? = nil, lineBottom: CommuterRailStyle? = nil,
    dotSize: CGFloat = 0, dotStyle: CommuterDotStyle? = nil,
    dashStyle: CommuterDashStyle? = nil, dashPattern: [NSNumber] = []
  ) {
    self.lineTop = lineTop
    self.lineBottom = lineBottom
    self.dotSize = dotSize
    self.dotStyle = dotStyle
    self.dashStyle = dashStyle
    self.dashPattern = dashPattern
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false
    [topLayer, bottomLayer, dotLayer, dashLayer].forEach { layer.addSublayer($0) }
    [topLayer, bottomLayer, dotLayer, dashLayer].forEach {
      $0.fillColor = UIColor.clear.cgColor
      $0.lineWidth = 2
    }
    dashLayer.lineDashPattern = dashPattern
    registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _) in
      view.refreshColors()
    }
    refreshColors()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func layoutSubviews() {
    super.layoutSubviews()
    let x = bounds.midX
    let centerY: CGFloat = 22
    if lineTop != nil {
      let path = UIBezierPath()
      path.move(to: CGPoint(x: x, y: 0))
      path.addLine(to: CGPoint(x: x, y: centerY - dotSize / 2))
      topLayer.path = path.cgPath
    }
    if lineBottom != nil {
      let path = UIBezierPath()
      path.move(to: CGPoint(x: x, y: centerY + dotSize / 2))
      path.addLine(to: CGPoint(x: x, y: bounds.height))
      bottomLayer.path = path.cgPath
    }
    if dotStyle != nil {
      let inset: CGFloat = dotStyle == .hollow ? 1 : 0
      dotLayer.path = UIBezierPath(
        ovalIn: CGRect(
          x: x - dotSize / 2 + inset, y: centerY - dotSize / 2 + inset,
          width: dotSize - inset * 2, height: dotSize - inset * 2)).cgPath
    }
    if dashStyle != nil {
      let path = UIBezierPath()
      path.move(to: CGPoint(x: x, y: 0))
      path.addLine(to: CGPoint(x: x, y: bounds.height))
      dashLayer.path = path.cgPath
    }
  }

  private func refreshColors() {
    topLayer.strokeColor = lineTop.map(railColor)?.cgColor ?? UIColor.clear.cgColor
    bottomLayer.strokeColor = lineBottom.map(railColor)?.cgColor ?? UIColor.clear.cgColor
    if let dotStyle {
      dotLayer.fillColor = dotFillColor(dotStyle).cgColor
      dotLayer.strokeColor = (dotStyle == .hollow ? SettingsStyle.Color.commuterRail : .clear).cgColor
    }
    if let dashStyle {
      dashLayer.strokeColor = (dashStyle == .traveled
        ? SettingsStyle.Color.commuterRailTraveled : SettingsStyle.Color.commuterRailSoft).cgColor
    }
    setNeedsLayout()
  }

  private func railColor(_ style: CommuterRailStyle) -> UIColor {
    switch style {
    case .hidden: return .clear
    case .normal: return SettingsStyle.Color.commuterRail
    case .traveled: return SettingsStyle.Color.commuterRailTraveled
    }
  }

  private func dotFillColor(_ style: CommuterDotStyle) -> UIColor {
    switch style {
    case .hollow: return SettingsStyle.Color.card
    case .filled: return SettingsStyle.Color.accent
    case .traveled: return SettingsStyle.Color.commuterRailTraveled
    }
  }
}

private final class CommuterPillLabel: UILabel {
  override func drawText(in rect: CGRect) { super.drawText(in: rect.insetBy(dx: 6, dy: 0)) }
  override var intrinsicContentSize: CGSize {
    let size = super.intrinsicContentSize
    return CGSize(width: size.width + 12, height: 20)
  }
}

final class CommuterTimelineCardView: UIView {
  var onExpand: (() -> Void)?
  var onOpenMap: ((CommuterStop) -> Void)?

  private let header = UIStackView()
  private let summaryLabel = UILabel()
  private let statsLabel = UILabel()
  private let chip = UIStackView()
  private let chipDot = UIView()
  private let chipLabel = UILabel()
  private let noticeStack = UIStackView()
  private let rowStack = UIStackView()

  init() {
    super.init(frame: .zero)
    layer.cornerRadius = 16
    clipsToBounds = true
    accessibilityIdentifier = "commuter.timeline"
    build()
    registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
      self.refreshColors()
    }
    refreshColors()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private func build() {
    let root = UIStackView(arrangedSubviews: [header, separator(), noticeStack, rowStack])
    root.axis = .vertical
    root.spacing = 0
    root.translatesAutoresizingMaskIntoConstraints = false
    addSubview(root)
    NSLayoutConstraint.activate([
      root.topAnchor.constraint(equalTo: topAnchor),
      root.leadingAnchor.constraint(equalTo: leadingAnchor),
      root.trailingAnchor.constraint(equalTo: trailingAnchor),
      root.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    summaryLabel.font = SettingsStyle.font(15, bold: true)
    statsLabel.font = SettingsStyle.font(13)
    let left = UIStackView(arrangedSubviews: [summaryLabel, statsLabel])
    left.axis = .vertical
    left.spacing = 2
    header.axis = .horizontal
    header.alignment = .center
    header.spacing = 12
    header.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 12, right: 16)
    header.isLayoutMarginsRelativeArrangement = true
    header.addArrangedSubview(left)
    left.setContentHuggingPriority(.defaultLow, for: .horizontal)
    summaryLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    statsLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    chip.axis = .horizontal
    chip.alignment = .center
    chip.spacing = 6
    chip.isLayoutMarginsRelativeArrangement = true
    chip.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    chip.layer.cornerRadius = 12
    chip.heightAnchor.constraint(equalToConstant: 24).isActive = true
    chip.accessibilityIdentifier = "commuter.chip"
    chipDot.layer.cornerRadius = 3
    chipDot.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      chipDot.widthAnchor.constraint(equalToConstant: 6),
      chipDot.heightAnchor.constraint(equalToConstant: 6),
    ])
    chipLabel.font = SettingsStyle.font(12, bold: true)
    chip.addArrangedSubview(chipDot)
    chip.addArrangedSubview(chipLabel)
    header.addArrangedSubview(chip)
    chip.setContentHuggingPriority(.required, for: .horizontal)
    chip.setContentCompressionResistancePriority(.required, for: .horizontal)
    chipLabel.setContentHuggingPriority(.required, for: .horizontal)
    chipLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    chipDot.setContentHuggingPriority(.required, for: .horizontal)
    chipDot.setContentCompressionResistancePriority(.required, for: .horizontal)
    noticeStack.axis = .vertical
    noticeStack.spacing = 12
    noticeStack.isLayoutMarginsRelativeArrangement = true
    noticeStack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 4, right: 16)
    rowStack.axis = .vertical
    rowStack.spacing = 0
    rowStack.isLayoutMarginsRelativeArrangement = true
    rowStack.layoutMargins = UIEdgeInsets(top: 4, left: 0, bottom: 8, right: 0)
  }

  private func separator() -> UIView {
    let separatorView = UIView()
    separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    separatorView.backgroundColor = SettingsStyle.Color.separator
    return separatorView
  }

  func configure(
    summary: CommuterRouteSummary, offNotice: CommuterOffNotice?, rows: [CommuterTimelineRow]
  ) {
    accessibilityLabel = String(localized: "commuter.timeline.accessibility.\(summary.routeName)")
    summaryLabel.attributedText = SettingsStyle.attributedText(
      String(
        localized: summary.direction == .toCampus
          ? "commuter.summary.to.\(summary.firstTime).\(summary.lastTime ?? "—")"
          : "commuter.summary.from.\(summary.firstTime)"),
      font: SettingsStyle.monospacedDigitFont(15, bold: true), color: SettingsStyle.Color.text,
      lineHeight: 20)
    let stats =
      String(localized: "commuter.summary.stops.\(summary.stopCount)")
      + (summary.durationMinutes.map { " · " + CommuterBusLogic.durationText(minutes: $0) } ?? "")
    statsLabel.attributedText = SettingsStyle.attributedText(
      stats, font: SettingsStyle.font(13), color: SettingsStyle.Color.secondaryText, lineHeight: 18)
    let statusKey: String
    switch summary.phase {
    case .running: statusKey = "commuter.status.running"
    case .off: statusKey = "commuter.status.off"
    case .beforeRun: statusKey = "commuter.status.before"
    case .finished: statusKey = "commuter.status.finished"
    }
    chipLabel.text = NSLocalizedString(statusKey, comment: "")
    chip.backgroundColor =
      summary.phase == .running
      ? SettingsStyle.Color.accentFill : SettingsStyle.Color.segmentBackground
    chipLabel.textColor =
      summary.phase == .running ? SettingsStyle.Color.link : SettingsStyle.Color.secondaryText
    chipDot.backgroundColor =
      summary.phase == .running ? SettingsStyle.Color.accent : SettingsStyle.Color.commuterFaint
    noticeStack.arrangedSubviews.forEach {
      noticeStack.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }
    if let offNotice { noticeStack.addArrangedSubview(makeNotice(offNotice)) }
    if summary.isPartial { noticeStack.addArrangedSubview(makePartialNotice()) }
    noticeStack.isHidden = noticeStack.arrangedSubviews.isEmpty
    rowStack.arrangedSubviews.forEach {
      rowStack.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }
    for row in rows { rowStack.addArrangedSubview(makeRow(row)) }
    setNeedsLayout()
  }

  private func makeNotice(_ notice: CommuterOffNotice) -> UIView {
    let title: String
    switch notice.reason {
    case .halt: title = "commuter.off.halt"
    case .vacationSession: title = "commuter.off.vacation_session"
    case .vacation: title = "commuter.off.vacation"
    case .weekend: title = "commuter.off.weekend"
    }
    let subtitle =
      (notice.reason == .halt || notice.reason == .weekend)
      ? String(localized: "commuter.off.next_run.\(CommuterBusLogic.dayText(notice.nextRunDay))")
      : String(localized: "commuter.off.resume.\(CommuterBusLogic.dayText(notice.nextRunDay))")
    return noticeBox(
      icon: "calendar", title: title, subtitle: subtitle, color: SettingsStyle.Color.text,
      background: SettingsStyle.Color.segmentBackground, id: "commuter.notice.off")
  }
  private func makePartialNotice() -> UIView {
    noticeBox(
      icon: "exclamationmark.circle", title: "commuter.partial_notice", subtitle: nil,
      color: SettingsStyle.Color.levelMidText, background: SettingsStyle.Color.levelMidFill,
      id: "commuter.notice.partial")
  }
  private func noticeBox(
    icon: String, title: String, subtitle: String?, color: UIColor, background: UIColor, id: String
  ) -> UIView {
    let box = UIView()
    box.layer.cornerRadius = 10
    box.backgroundColor = background
    box.accessibilityIdentifier = id
    let image = UIImageView(image: UIImage(systemName: icon))
    image.tintColor =
      subtitle == nil ? SettingsStyle.Color.levelMidText : SettingsStyle.Color.secondaryText
    image.contentMode = .scaleAspectFit
    image.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      image.widthAnchor.constraint(equalToConstant: 16),
      image.heightAnchor.constraint(equalToConstant: 16),
    ])
    let text = UIStackView()
    text.axis = .vertical
    text.spacing = 2
    let first = UILabel()
    first.numberOfLines = 0
    let bold = subtitle != nil
    first.attributedText = SettingsStyle.attributedText(
      NSLocalizedString(title, comment: ""), font: SettingsStyle.font(13, bold: bold), color: color,
      lineHeight: 18)
    text.addArrangedSubview(first)
    if let subtitle {
      let second = UILabel()
      second.numberOfLines = 1
      second.attributedText = SettingsStyle.attributedText(
        subtitle, font: SettingsStyle.font(13), color: SettingsStyle.Color.text, lineHeight: 18)
      text.addArrangedSubview(second)
    }
    let row = UIStackView(arrangedSubviews: [image, text])
    row.axis = .horizontal
    row.alignment = .top
    row.spacing = 8
    row.translatesAutoresizingMaskIntoConstraints = false
    box.addSubview(row)
    NSLayoutConstraint.activate([
      row.topAnchor.constraint(equalTo: box.topAnchor, constant: 10),
      row.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -10),
      row.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 12),
      row.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -12),
    ])
    image.transform = CGAffineTransform(translationX: 0, y: 1)
    return box
  }

  private func makeRow(_ item: CommuterTimelineRow) -> UIView {
    switch item {
    case .fold(let count):
      let button = UIControl()
      button.accessibilityIdentifier = "commuter.fold"
      button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
      let label = rowLabel(
        String(localized: "commuter.fold.\(count)"), size: 13, line: 18,
        color: SettingsStyle.Color.link, weight: .bold)
      let chevron = UIImageView(
        image: UIImage(
          systemName: "chevron.down",
          withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)))
      chevron.tintColor = SettingsStyle.Color.link
      let text = UIStackView(arrangedSubviews: [label, chevron])
      text.axis = .horizontal
      text.alignment = .center
      text.spacing = 4
      pin(text, in: button, leading: 96, trailing: 16)
      let dash = CommuterRailView(dashStyle: .traveled, dashPattern: [2, 2])
      pinRail(dash, in: button)
      button.addTarget(self, action: #selector(expandTapped), for: .touchUpInside)
      return button
    case .stop(let stopRow): return makeStop(stopRow)
    case .bus: return makeBus()
    case let .gap(minutes: minutes, traveled: traveled):
      let view = UIView()
      view.heightAnchor.constraint(equalToConstant: 32).isActive = true
      let label = rowLabel(
        String(localized: "commuter.gap.\(CommuterBusLogic.durationText(minutes: minutes))"),
        size: 12, line: 16, color: SettingsStyle.Color.commuterFaint)
      pin(label, in: view, leading: 96, trailing: 16)
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
      let dash = CommuterRailView(
        dashStyle: traveled ? .traveled : .soft, dashPattern: [4, 4])
      pinRail(dash, in: view)
      view.accessibilityIdentifier = "commuter.gap"
      view.accessibilityLabel = String(
        localized: "commuter.gap.accessibility.\(CommuterBusLogic.durationText(minutes: minutes))")
      return view
    }
  }

  @objc
  private func expandTapped() { onExpand?() }
  private func makeStop(_ item: CommuterStopRow) -> UIView {
    let row = UIView()
    row.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    row.accessibilityIdentifier = "commuter.stop.\(item.index)"
    if item.isNear { row.backgroundColor = SettingsStyle.Color.commuterNearRow }
    addTimeLabel(to: row, item: item)
    let map = makeMapButton(for: item, in: row)
    let column = makeStopColumn(for: item)
    column.translatesAutoresizingMaskIntoConstraints = false
    row.addSubview(column)
    NSLayoutConstraint.activate([
      column.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 96),
      column.trailingAnchor.constraint(
        equalTo: map?.leadingAnchor ?? row.trailingAnchor, constant: map == nil ? -16 : 0),
      column.topAnchor.constraint(equalTo: row.topAnchor, constant: 12),
      column.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -12),
    ])
    drawStopRail(in: row, item: item)
    if let map { row.bringSubviewToFront(map) }
    return row
  }

  private func addTimeLabel(to row: UIView, item: CommuterStopRow) {
    let color =
      item.stop.time == nil || item.isPassed
      ? SettingsStyle.Color.commuterFaint
      : (item.stop.isCampus || item.isNear ? SettingsStyle.Color.link : SettingsStyle.Color.text)
    let time = rowLabel(
      item.stop.time ?? "—", size: 15, line: 20, color: color,
      weight: item.stop.time != nil ? .bold : .regular, mono: true)
    time.translatesAutoresizingMaskIntoConstraints = false
    time.textAlignment = .right
    row.addSubview(time)
    NSLayoutConstraint.activate([
      time.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
      time.widthAnchor.constraint(equalToConstant: 44),
      time.topAnchor.constraint(equalTo: row.topAnchor, constant: 12),
    ])
  }

}

extension CommuterTimelineCardView {
  private func makeStopColumn(for item: CommuterStopRow) -> UIStackView {
    let name = rowLabel(
      item.stop.name, size: 15, line: 20,
      color: item.isPassed && !item.isNear
        ? SettingsStyle.Color.secondaryText : SettingsStyle.Color.text,
      weight: item.stop.isCampus || item.isNear ? .bold : .regular)
    name.numberOfLines = 1
    name.lineBreakMode = .byTruncatingTail
    name.setContentHuggingPriority(.defaultLow, for: .horizontal)
    name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    let nameRow = UIStackView(arrangedSubviews: [name])
    nameRow.axis = .horizontal
    nameRow.alignment = .center
    nameRow.spacing = 6
    if let tag = item.tag {
      nameRow.addArrangedSubview(
        pill(
          String(localized: tag == .departure ? "commuter.tag.departure" : "commuter.tag.arrival"),
          bg: SettingsStyle.Color.accentFill, fg: SettingsStyle.Color.link))
    }
    let column = UIStackView(arrangedSubviews: [nameRow])
    column.axis = .vertical
    column.spacing = 4
    if !item.stop.detail.isEmpty || item.isNear {
      column.addArrangedSubview(makeStopDetail(for: item))
    }
    return column
  }

  private func makeStopDetail(for item: CommuterStopRow) -> UIStackView {
    let detail = UIStackView()
    detail.axis = .horizontal
    detail.alignment = .center
    detail.spacing = 6
    if item.isNear {
      detail.addArrangedSubview(
        pill(
          String(localized: "commuter.near"), bg: SettingsStyle.Color.accent,
          fg: SettingsStyle.Color.onAccent))
    }
    if !item.stop.detail.isEmpty {
      let label = rowLabel(
        item.stop.detail, size: 13, line: 18, color: SettingsStyle.Color.secondaryText)
      label.lineBreakMode = .byTruncatingTail
      label.numberOfLines = 1
      detail.addArrangedSubview(label)
    } else if item.isNear {
      let spacer = UIView()
      spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
      spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
      detail.addArrangedSubview(spacer)
    }
    return detail
  }

  private func makeMapButton(for item: CommuterStopRow, in row: UIView) -> UIButton? {
    guard item.stop.hasCoordinate else { return nil }
    let button = UIButton(type: .system)
    let symbol = UIImage(
      systemName: "map", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .medium))
    button.setImage(symbol, for: .normal)
    button.tintColor = SettingsStyle.Color.link
    button.backgroundColor = .clear
    let tile = UIView()
    tile.translatesAutoresizingMaskIntoConstraints = false
    tile.backgroundColor = SettingsStyle.Color.accentFill
    tile.layer.cornerRadius = 16
    tile.isUserInteractionEnabled = false
    button.addSubview(tile)
    NSLayoutConstraint.activate([
      tile.widthAnchor.constraint(equalToConstant: 32),
      tile.heightAnchor.constraint(equalToConstant: 32),
      tile.centerXAnchor.constraint(equalTo: button.centerXAnchor),
      tile.centerYAnchor.constraint(equalTo: button.centerYAnchor),
    ])
    if let imageView = button.imageView { button.bringSubviewToFront(imageView) }
    button.accessibilityLabel = String(localized: "commuter.map.accessibility.\(item.stop.name)")
    button.accessibilityIdentifier = "commuter.map.\(item.index)"
    button.translatesAutoresizingMaskIntoConstraints = false
    row.addSubview(button)
    NSLayoutConstraint.activate([
      button.widthAnchor.constraint(equalToConstant: 44),
      button.heightAnchor.constraint(equalToConstant: 44),
      button.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -4),
      button.centerYAnchor.constraint(equalTo: row.centerYAnchor),
    ])
    button.addAction(UIAction { [weak self] _ in self?.onOpenMap?(item.stop) }, for: .touchUpInside)
    return button
  }

  private func makeBus() -> UIView {
    let row = UIView()
    row.heightAnchor.constraint(equalToConstant: 28).isActive = true
    row.isAccessibilityElement = true
    row.accessibilityLabel = String(localized: "commuter.bus.accessibility")
    row.accessibilityIdentifier = "commuter.bus"
    let dot = UIView()
    dot.translatesAutoresizingMaskIntoConstraints = false
    dot.backgroundColor = SettingsStyle.Color.accent
    dot.layer.cornerRadius = 12
    row.addSubview(dot)
    let bus = UIImageView(
      image: UIImage(
        systemName: "bus",
        withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)))
    bus.tintColor = SettingsStyle.Color.onAccent
    bus.translatesAutoresizingMaskIntoConstraints = false
    dot.addSubview(bus)
    NSLayoutConstraint.activate([
      dot.widthAnchor.constraint(equalToConstant: 24),
      dot.heightAnchor.constraint(equalToConstant: 24),
      dot.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 66),
      dot.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      bus.centerXAnchor.constraint(equalTo: dot.centerXAnchor),
      bus.centerYAnchor.constraint(equalTo: dot.centerYAnchor),
    ])
    let topRail = CAShapeLayer()
    topRail.name = "busRail:traveled"
    topRail.strokeColor = SettingsStyle.Color.commuterRailTraveled.cgColor
    topRail.lineWidth = 2
    topRail.path = verticalPath(from: 0, to: 2, x: 78)
    row.layer.addSublayer(topRail)
    let bottomRail = CAShapeLayer()
    bottomRail.name = "busRail:normal"
    bottomRail.strokeColor = SettingsStyle.Color.commuterRail.cgColor
    bottomRail.lineWidth = 2
    bottomRail.path = verticalPath(from: 26, to: 28, x: 78)
    row.layer.addSublayer(bottomRail)
    let ping = CALayer()
    ping.name = "busPing"
    ping.frame = CGRect(x: 66, y: 2, width: 24, height: 24)
    ping.backgroundColor = SettingsStyle.Color.accent.cgColor
    ping.cornerRadius = 12
    row.layer.insertSublayer(ping, below: dot.layer)
    let anim = CAAnimationGroup()
    let scale = CABasicAnimation(keyPath: "transform.scale")
    scale.fromValue = 1
    scale.toValue = 1.9
    let opacity = CABasicAnimation(keyPath: "opacity")
    opacity.fromValue = 0.5
    opacity.toValue = 0
    anim.animations = [scale, opacity]
    anim.duration = 1.8
    anim.repeatCount = .infinity
    anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
    ping.add(anim, forKey: "ping")
    return row
  }

  private func drawStopRail(in row: UIView, item: CommuterStopRow) {
    let rail = CommuterRailView(
      lineTop: item.lineTop, lineBottom: item.lineBottom,
      dotSize: CGFloat(item.dotSize), dotStyle: item.dotStyle)
    pinRail(rail, in: row)
  }

  private func pinRail(_ view: CommuterRailView, in row: UIView) {
    row.addSubview(view)
    NSLayoutConstraint.activate([
      view.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 72),
      view.widthAnchor.constraint(equalToConstant: 12),
      view.topAnchor.constraint(equalTo: row.topAnchor),
      view.bottomAnchor.constraint(equalTo: row.bottomAnchor),
    ])
  }
  private func pin(_ child: UIView, in parent: UIView, leading: CGFloat, trailing: CGFloat) {
    child.translatesAutoresizingMaskIntoConstraints = false
    parent.addSubview(child)
    NSLayoutConstraint.activate([
      child.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: leading),
      child.trailingAnchor.constraint(
        lessThanOrEqualTo: parent.trailingAnchor, constant: -trailing),
      child.centerYAnchor.constraint(equalTo: parent.centerYAnchor),
    ])
  }
  private func rowLabel(
    _ text: String, size: CGFloat, line: CGFloat, color: UIColor, weight: UIFont.Weight = .regular,
    mono: Bool = false
  ) -> UILabel {
    let label = UILabel()
    label.attributedText = SettingsStyle.attributedText(
      text,
      font: mono
        ? SettingsStyle.monospacedDigitFont(size, bold: weight == .bold)
        : SettingsStyle.font(size, bold: weight == .bold), color: color, lineHeight: line)
    return label
  }
  private func pill(_ text: String, bg: UIColor, fg: UIColor) -> UILabel {
    let label = CommuterPillLabel()
    label.text = text
    label.font = SettingsStyle.font(12, bold: true)
    label.textColor = fg
    label.textAlignment = .center
    label.backgroundColor = bg
    label.layer.cornerRadius = 6
    label.clipsToBounds = true
    label.heightAnchor.constraint(equalToConstant: 20).isActive = true
    label.setContentHuggingPriority(.required, for: .horizontal)
    label.setContentCompressionResistancePriority(.required, for: .horizontal)
    return label
  }
  private func verticalPath(from start: CGFloat, to end: CGFloat, x: CGFloat) -> CGPath {
    let path = UIBezierPath()
    path.move(to: CGPoint(x: x, y: start))
    path.addLine(to: CGPoint(x: x, y: end))
    return path.cgPath
  }

  private func refreshColors() {
    backgroundColor = SettingsStyle.Color.card
    updateLayerColors(in: layer)
    setNeedsLayout()
  }

  private func updateLayerColors(in layer: CALayer) {
    if let name = layer.name {
      if name == "busPing" {
        layer.backgroundColor = SettingsStyle.Color.accent.cgColor
      } else if let shape = layer as? CAShapeLayer {
        if name.hasPrefix("busRail:") {
          let state = String(name.dropFirst("busRail:".count))
          shape.strokeColor =
            state == "traveled"
            ? SettingsStyle.Color.commuterRailTraveled.cgColor
            : SettingsStyle.Color.commuterRail.cgColor
        }
      }
    }
    layer.sublayers?.forEach(updateLayerColors)
  }

}
