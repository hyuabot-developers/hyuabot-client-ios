//
//  ShuttleLostItemNoticeView.swift
//  hyuabot
//

import MapKit
import SnapKit
import UIKit

final class ShuttleLostItemNoticeView: UIView {
    private static let officeCoordinate = CLLocationCoordinate2D(
        latitude: 37.29275316695924,
        longitude: 126.83714484865253
    )

    var onDismiss: (() -> Void)?

    private let card = UIView().then {
        $0.backgroundColor = .secondarySystemGroupedBackground
        $0.layer.cornerRadius = 16
        $0.layer.cornerCurve = .continuous
    }

    private let titleLabel = UILabel().then {
        $0.text = String(localized: "inquiry.shuttleLost.title")
        $0.font = .godo(size: 16, weight: .bold)
        $0.textColor = .label
        $0.numberOfLines = 0
    }

    private let detailLabel = UILabel().then {
        $0.text = String(localized: "inquiry.shuttleLost.detail")
        $0.font = .godo(size: 14, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
    }

    private let closeButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = .secondaryLabel
        $0.accessibilityLabel = String(localized: "inquiry.shuttleLost.close")
        $0.accessibilityIdentifier = "inquiry.shuttle_lost.dismiss"
    }

    private let officeMapView = MKMapView().then {
        $0.isZoomEnabled = false
        $0.isScrollEnabled = false
        $0.isPitchEnabled = false
        $0.isRotateEnabled = false
        $0.isUserInteractionEnabled = false
        $0.layer.cornerRadius = 10
        $0.layer.cornerCurve = .continuous
        $0.clipsToBounds = true
        $0.accessibilityIdentifier = "inquiry.shuttle_lost.map_preview"
    }

    private let officeMapButton = UIButton(type: .system).then {
        var configuration = UIButton.Configuration.tinted()
        configuration.title = String(localized: "inquiry.shuttleLost.map")
        configuration.baseForegroundColor = .hanyangBlue
        $0.configuration = configuration
        $0.accessibilityIdentifier = "inquiry.shuttle_lost.open_map"
    }

    private let officeCallButton = UIButton(type: .system).then {
        var configuration = UIButton.Configuration.filled()
        configuration.title = String(localized: "inquiry.shuttleLost.call")
        configuration.baseBackgroundColor = .hanyangBlue
        $0.configuration = configuration
        $0.accessibilityIdentifier = "inquiry.shuttle_lost.call"
    }

    init() {
        super.init(frame: .zero)
        configureLayout()
        configureOfficeMap()
        closeButton.addTarget(self, action: #selector(dismissNotice), for: .touchUpInside)
        officeMapButton.addTarget(self, action: #selector(openOfficeMap), for: .touchUpInside)
        officeCallButton.addTarget(self, action: #selector(callOffice), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureLayout() {
        addSubview(card)
        let titleRow = UIStackView(arrangedSubviews: [titleLabel, closeButton])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 8
        let actionRow = UIStackView(arrangedSubviews: [officeMapButton, officeCallButton])
        actionRow.axis = .horizontal
        actionRow.distribution = .fillEqually
        actionRow.spacing = 8
        card.addSubview(titleRow)
        card.addSubview(detailLabel)
        card.addSubview(officeMapView)
        card.addSubview(actionRow)
        configureCardConstraints(titleRow: titleRow, actionRow: actionRow)
    }

    private func configureCardConstraints(titleRow: UIStackView, actionRow: UIStackView) {
        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
        titleRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.equalToSuperview().inset(12)
            make.trailing.equalToSuperview().inset(4)
        }
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
        }
        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(titleRow.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        officeMapView.snp.makeConstraints { make in
            make.top.equalTo(detailLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(88)
        }
        actionRow.snp.makeConstraints { make in
            make.top.equalTo(officeMapView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(12)
            make.height.equalTo(44)
        }
    }

    private func configureOfficeMap() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = Self.officeCoordinate
        annotation.title = String(localized: "inquiry.shuttleLost.office")
        officeMapView.addAnnotation(annotation)
        officeMapView.setRegion(
            MKCoordinateRegion(
                center: Self.officeCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.0012, longitudeDelta: 0.0012)
            ),
            animated: false
        )
    }

    @objc
    private func dismissNotice() {
        isHidden = true
        onDismiss?()
    }

    @objc
    private func openOfficeMap() {
        let office = MKMapItem(placemark: MKPlacemark(coordinate: Self.officeCoordinate))
        office.name = String(localized: "inquiry.shuttleLost.office")
        office.openInMaps()
    }

    @objc
    private func callOffice() {
        guard let url = URL(string: "tel:0314004412") else { return }
        UIApplication.shared.open(url)
    }
}
