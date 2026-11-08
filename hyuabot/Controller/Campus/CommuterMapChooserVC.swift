//
//  CommuterMapChooserVC.swift
//  hyuabot
//

import UIKit

struct CommuterMapChoice {
    let name: String
    let symbol: String
    let brandColor: UIColor
    let action: () -> Void
}

final class CommuterMapChooserVC: UIViewController {
    private let stopName: String
    private let choices: [CommuterMapChoice]

    init(stopName: String, choices: [CommuterMapChoice]) {
        self.stopName = stopName
        self.choices = choices
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SettingsStyle.Color.sheet
        configureSheet()
        configureContent()
    }

    private func configureSheet() {
        guard let sheet = sheetPresentationController else { return }
        sheet.detents = [.custom(identifier: .init("commuterMapChooser")) { [weak self] context in
            guard let self else { return context.maximumDetentValue }
            let desiredHeight = 20 + 54 + 12 + CGFloat(self.choices.count * 56) + 16 + 48 + 34
            return min(desiredHeight, context.maximumDetentValue)
        }]
        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = 24
    }

    private func configureContent() {
        let title = makeLabel(String(localized: "commuter.map.chooser.title"), size: 20, bold: true,
                              color: SettingsStyle.Color.text)
        let subtitle = makeLabel(
            String(format: String(localized: "commuter.map.chooser.subtitle"), stopName),
            size: 14,
            bold: false,
            color: SettingsStyle.Color.secondaryText
        )
        let header = UIStackView(arrangedSubviews: [title, subtitle])
        header.axis = .vertical
        header.spacing = 4

        let rows = choices.map(makeRow)
        let appStack = UIStackView(arrangedSubviews: rows)
        appStack.axis = .vertical
        appStack.spacing = 0

        let cancel = UIButton(type: .system)
        cancel.translatesAutoresizingMaskIntoConstraints = false
        cancel.setTitle(String(localized: "commuter.map.cancel"), for: .normal)
        cancel.titleLabel?.font = SettingsStyle.font(16, bold: true)
        cancel.setTitleColor(SettingsStyle.Color.secondaryText, for: .normal)
        cancel.backgroundColor = SettingsStyle.Color.segmentBackground
        cancel.layer.cornerRadius = 14
        cancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [header, appStack, cancel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            cancel.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func makeRow(_ choice: CommuterMapChoice) -> UIView {
        let row = UIControl()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.accessibilityLabel = choice.name
        row.accessibilityTraits = .button
        row.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true) {
                choice.action()
            }
        }, for: .touchUpInside)
        row.addAction(UIAction { [weak row] _ in row?.backgroundColor = SettingsStyle.Color.segmentBackground },
                      for: .touchDown)
        row.addAction(UIAction { [weak row] _ in row?.backgroundColor = .clear },
                      for: [.touchUpInside, .touchUpOutside, .touchCancel])

        let tile = makeTile(for: choice)

        let name = makeLabel(choice.name, size: 16, bold: false, color: SettingsStyle.Color.text)
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.tintColor = SettingsStyle.Color.chevron
        chevron.contentMode = .scaleAspectFit
        let content = UIStackView(arrangedSubviews: [tile, name, chevron])
        content.translatesAutoresizingMaskIntoConstraints = false
        content.isUserInteractionEnabled = false
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 12
        row.addSubview(content)
        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 56),
            content.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            content.topAnchor.constraint(equalTo: row.topAnchor),
            content.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            tile.widthAnchor.constraint(equalToConstant: 44),
            tile.heightAnchor.constraint(equalToConstant: 44),
            chevron.widthAnchor.constraint(equalToConstant: 14)
        ])

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.isUserInteractionEnabled = false
        separator.backgroundColor = SettingsStyle.Color.separator
        row.addSubview(separator)
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 72),
            separator.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
        return row
    }

    private func makeTile(for choice: CommuterMapChoice) -> UIView {
        let tile = UIView()
        tile.translatesAutoresizingMaskIntoConstraints = false
        tile.backgroundColor = choice.brandColor
        tile.layer.cornerRadius = 12
        tile.clipsToBounds = true

        if choice.symbol == "N" || choice.symbol == "K" {
            let letter = UILabel()
            letter.translatesAutoresizingMaskIntoConstraints = false
            letter.text = choice.symbol
            letter.textAlignment = .center
            letter.font = SettingsStyle.font(20, bold: true)
            letter.textColor = choice.symbol == "K" ? UIColor(white: 0.12, alpha: 1) : .white
            letter.adjustsFontSizeToFitWidth = true
            letter.minimumScaleFactor = 0.5
            tile.addSubview(letter)
            NSLayoutConstraint.activate([
                letter.leadingAnchor.constraint(equalTo: tile.leadingAnchor),
                letter.trailingAnchor.constraint(equalTo: tile.trailingAnchor),
                letter.topAnchor.constraint(equalTo: tile.topAnchor),
                letter.bottomAnchor.constraint(equalTo: tile.bottomAnchor),
            ])
        } else {
            let symbolName = choice.symbol == "G" ? "location.fill" : "map.fill"
            let glyph = UIImageView(image: UIImage(systemName: symbolName))
            glyph.translatesAutoresizingMaskIntoConstraints = false
            glyph.tintColor = .white
            glyph.contentMode = .scaleAspectFit
            tile.addSubview(glyph)
            NSLayoutConstraint.activate([
                glyph.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
                glyph.centerYAnchor.constraint(equalTo: tile.centerYAnchor),
                glyph.widthAnchor.constraint(equalToConstant: 22),
                glyph.heightAnchor.constraint(equalToConstant: 22),
            ])
        }
        return tile
    }

    private func makeLabel(_ text: String, size: CGFloat, bold: Bool, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = SettingsStyle.font(size, bold: bold)
        label.textColor = color
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }

    @objc
    private func cancelTapped() {
        dismiss(animated: true)
    }
}
