//
//  SubwayTransferRouteView.swift
//  hyuabot
//
import SnapKit
import UIKit

final class SubwayTransferRouteView: UIView {
    private let stack = UIStackView()
    private let separator = UIView()
    private var transferNode: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        stack.axis = .vertical
        stack.spacing = 0
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        }
        separator.backgroundColor = SettingsStyle.Color.separator
        addSubview(separator)
        separator.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    func configure(_ model: SubwayTransferRouteModel, showsSeparator: Bool) {
        accessibilityLabel = model.accessibilityLabel
        separator.isHidden = !showsSeparator
        transferNode = nil
        for view in stack.arrangedSubviews {
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        stack.addArrangedSubview(legRow(model.first, isFirst: true, hasSecond: model.second != nil))
        if let second = model.second {
            stack.addArrangedSubview(transferRow(
                station: model.transferStation ?? "",
                wait: model.waitText,
                first: model.first,
                second: second
            ))
            stack.addArrangedSubview(legRow(second, isFirst: false, hasSecond: true))
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        transferNode?.layer.borderColor = SettingsStyle.Color.secondaryText.resolvedColor(with: traitCollection).cgColor
    }

    private func legRow(_ leg: SubwayTransferLegModel, isFirst: Bool, hasSecond: Bool) -> UIView {
        let row = UIView()
        let rail = railView(line: leg.line, isFirst: isFirst, hasSecond: hasSecond)
        let destination = UILabel()
        destination.font = SettingsStyle.font(15, bold: true)
        destination.textColor = SettingsStyle.Color.text
        destination.setKoreanTranslatedText(leg.destination)
        destination.attributedText = SettingsStyle.attributedText(
            destination.text ?? leg.destination,
            font: SettingsStyle.font(15, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 20,
            lineBreakMode: .byTruncatingTail
        )
        destination.lineBreakMode = .byTruncatingTail
        destination.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let lineName = UILabel()
        lineName.attributedText = SettingsStyle.attributedText(
            leg.lineName, font: SettingsStyle.font(13), color: SettingsStyle.Color.secondaryText, lineHeight: 18
        )
        lineName.setContentHuggingPriority(.required, for: .horizontal)
        let labels = UIStackView(arrangedSubviews: [destination, lineName])
        labels.spacing = 6
        labels.alignment = .firstBaseline
        let trailing = UILabel()
        trailing.text = leg.trailingText
        trailing.font = leg.isStrong ? SettingsStyle.monospacedDigitFont(15, bold: true) : SettingsStyle.font(13)
        trailing.textColor = leg.isStrong && leg.isSoon ? SettingsStyle.Color
            .subwaySoon : (leg.isStrong ? SettingsStyle.Color.text : SettingsStyle.Color.secondaryText)
        trailing.setContentHuggingPriority(.required, for: .horizontal)
        trailing.setContentCompressionResistancePriority(.required, for: .horizontal)
        row.addSubview(rail)
        row.addSubview(labels)
        row.addSubview(trailing)
        rail.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.width.equalTo(12)
            make.top.bottom.equalToSuperview()
        }
        labels.snp.makeConstraints { make in
            make.leading.equalTo(rail.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(6)
        }
        trailing.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(labels.snp.trailing).offset(8)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        row.snp.makeConstraints { $0.height.greaterThanOrEqualTo(32) }
        return row
    }

    private func transferRow(station: String, wait: String?, first: SubwayTransferLegModel, second: SubwayTransferLegModel) -> UIView {
        let row = UIView()
        let rail = transferRailView(first: first.line, second: second.line)
        let stationLabel = UILabel()
        stationLabel.attributedText = SettingsStyle.attributedText(
            station, font: SettingsStyle.font(13, bold: true), color: SettingsStyle.Color.secondaryText, lineHeight: 18
        )
        let waitLabel = UILabel()
        waitLabel.attributedText = wait.map {
            SettingsStyle.attributedText(
                $0, font: SettingsStyle.monospacedDigitFont(13), color: SettingsStyle.Color.secondaryText, lineHeight: 18
            )
        }
        let content = UIStackView(arrangedSubviews: [stationLabel, waitLabel])
        content.spacing = 4
        row.addSubview(rail)
        row.addSubview(content)
        rail.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.width.equalTo(12)
            make.top.bottom.equalToSuperview()
        }
        content.snp.makeConstraints { make in
            make.leading.equalTo(rail.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        row.snp.makeConstraints { $0.height.greaterThanOrEqualTo(36) }
        return row
    }

    private func transferRailView(first: SubwayRouteLine, second: SubwayRouteLine) -> UIView {
        let rail = UIView()
        let top = UIView()
        top.backgroundColor = first.color
        let node = UIView()
        node.backgroundColor = SettingsStyle.Color.card
        node.layer.cornerRadius = 6
        node.layer.borderWidth = 2
        node.layer.borderColor = SettingsStyle.Color.secondaryText.resolvedColor(with: traitCollection).cgColor
        transferNode = node
        let bottom = UIView()
        bottom.backgroundColor = second.color
        [top, node, bottom].forEach(rail.addSubview)
        top.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.equalTo(2)
            make.bottom.equalTo(node.snp.top)
        }
        node.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(12) }
        bottom.snp.makeConstraints { make in
            make.bottom.centerX.equalToSuperview()
            make.width.equalTo(2)
            make.top.equalTo(node.snp.bottom)
        }
        return rail
    }

    private func railView(line: SubwayRouteLine, isFirst: Bool, hasSecond: Bool) -> UIView {
        let rail = UIView()
        let top = UIView()
        top.backgroundColor = isFirst ? .clear : line.color
        let dot = UIView()
        dot.backgroundColor = line.color
        dot.layer.cornerRadius = 5
        let bottom = UIView()
        bottom.backgroundColor = isFirst && hasSecond ? line.color : .clear
        [top, dot, bottom].forEach(rail.addSubview)
        top.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.equalTo(2)
            make.bottom.equalTo(dot.snp.top)
        }
        dot.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(10) }
        bottom.snp.makeConstraints { make in
            make.bottom.centerX.equalToSuperview()
            make.width.equalTo(2)
            make.top.equalTo(dot.snp.bottom)
        }
        return rail
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
