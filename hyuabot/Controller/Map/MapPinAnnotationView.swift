//
//  MapPinAnnotationView.swift
//  hyuabot
//

import MapKit
import SnapKit
import UIKit

final class MapPinAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "MapPinAnnotationView"

    private let ringView = UIView()
    private let dotView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private var dotSizeConstraint: Constraint?
    private var iconSizeConstraint: Constraint?

    var clustersWithBuildings = false {
        didSet { updateClustering() }
    }

    var isDimmed = false {
        didSet { alpha = isDimmed ? 0.55 : 1 }
    }

    override var annotation: (any MKAnnotation)? {
        didSet { updateTitle() }
    }

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        configureAnnotation()
        configureSubviews()
        applySelectedLook(false)
        updateTitle()
        updateLayerColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _: UITraitCollection) in
            view.updateLayerColors()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        clustersWithBuildings = false
        applySelectedLook(false)
        updateTitle()
        isDimmed = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        applySelectedLook(selected)
        updateClustering()
        if animated {
            UIView.animate(withDuration: 0.2) { self.layoutIfNeeded() }
        }
    }

    private func updateClustering() {
        clusteringIdentifier = clustersWithBuildings && !isSelected ? "map.buildings" : nil
        displayPriority = isSelected || !clustersWithBuildings ? .required : .defaultHigh
    }

    private func configureAnnotation() {
        bounds = CGRect(x: 0, y: 0, width: 100, height: 70)
        // The circle's bottom (y = 44) stays anchored to the map coordinate.
        centerOffset = CGPoint(x: 0, y: -9)
        canShowCallout = false
        collisionMode = .circle
        displayPriority = .required
    }

    private func configureSubviews() {
        addSubview(ringView)
        ringView.backgroundColor = SettingsStyle.Color.accentFill
        ringView.layer.cornerRadius = 24
        ringView.layer.cornerCurve = .continuous
        ringView.isHidden = true

        addSubview(dotView)
        dotView.backgroundColor = SettingsStyle.Color.accent
        dotView.layer.cornerRadius = 15
        dotView.layer.cornerCurve = .continuous
        dotView.layer.borderWidth = 2
        dotView.layer.shadowOpacity = 0.22
        dotView.layer.shadowRadius = 3
        dotView.layer.shadowOffset = CGSize(width: 0, height: 2)
        dotView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(snp.top).offset(44)
            dotSizeConstraint = make.size.equalTo(30).constraint
        }
        ringView.snp.makeConstraints { $0.size.equalTo(48); $0.center.equalTo(dotView) }

        configureIcon()
        configureTitle()
    }

    private func configureIcon() {
        let image = UIImage(systemName: "building.2", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .regular))
        iconView.image = image
        iconView.tintColor = SettingsStyle.Color.onAccent
        iconView.contentMode = .scaleAspectFit
        dotView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            iconSizeConstraint = make.size.equalTo(16).constraint
        }
    }

    private func configureTitle() {
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.font = SettingsStyle.font(12, bold: true)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = SettingsStyle.Color.text
        titleLabel.layer.shadowRadius = 1.5
        titleLabel.layer.shadowOpacity = 1
        titleLabel.layer.shadowOffset = .zero
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(dotView.snp.bottom).offset(3)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(4)
            make.trailing.lessThanOrEqualToSuperview().inset(4)
            make.width.lessThanOrEqualTo(100)
        }
    }

    private func applySelectedLook(_ selected: Bool) {
        ringView.isHidden = !selected
        dotSizeConstraint?.update(offset: selected ? 40 : 30)
        iconSizeConstraint?.update(offset: selected ? 20 : 16)
        dotView.layer.cornerRadius = selected ? 20 : 15
        dotView.layer.shadowOpacity = selected ? 0.25 : 0.22
        dotView.layer.shadowRadius = selected ? 5 : 3
        dotView.layer.shadowOffset = CGSize(width: 0, height: selected ? 4 : 2)
        titleLabel.font = SettingsStyle.font(selected ? 13 : 12, bold: true)
        titleLabel.adjustsFontForContentSizeCategory = true
    }

    private func updateTitle() {
        // swiftlint:disable:next redundant_nil_coalescing
        let title = annotation?.title ?? nil
        titleLabel.text = title
        accessibilityLabel = title
    }

    private func updateLayerColors() {
        let traits = traitCollection
        dotView.layer.borderColor = SettingsStyle.Color.card.resolvedColor(with: traits).cgColor
        dotView.layer.shadowColor = UIColor.black.resolvedColor(with: traits).cgColor
        titleLabel.layer.shadowColor = SettingsStyle.Color.card.resolvedColor(with: traits).cgColor
    }
}

final class MapClusterAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "MapClusterAnnotationView"

    private let countLabel = UILabel()

    override var annotation: (any MKAnnotation)? {
        didSet { updateCount() }
    }

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        bounds = CGRect(x: 0, y: 0, width: 36, height: 36)
        backgroundColor = SettingsStyle.Color.accent
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 2
        layer.shadowOpacity = 0.22
        layer.shadowRadius = 3
        layer.shadowOffset = CGSize(width: 0, height: 2)
        canShowCallout = false
        collisionMode = .circle
        displayPriority = .defaultHigh
        countLabel.font = SettingsStyle.font(15, bold: true)
        countLabel.textColor = SettingsStyle.Color.onAccent
        countLabel.textAlignment = .center
        countLabel.adjustsFontSizeToFitWidth = true
        addSubview(countLabel)
        countLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(4) }
        updateCount()
        updateLayerColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _: UITraitCollection) in
            view.updateLayerColors()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        updateCount()
    }

    private func updateCount() {
        let count = (annotation as? MKClusterAnnotation)?.memberAnnotations.count
        countLabel.text = count.map { String($0) }
        accessibilityLabel = countLabel.text
        accessibilityTraits = .button
    }

    private func updateLayerColors() {
        layer.borderColor = SettingsStyle.Color.card.resolvedColor(with: traitCollection).cgColor
        layer.shadowColor = UIColor.black.resolvedColor(with: traitCollection).cgColor
    }
}
