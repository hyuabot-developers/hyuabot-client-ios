//
//  ShuttleLostItemNoticeView.swift
//  hyuabot
//

import MapKit
import SnapKit
import Then
import UIKit

final class ShuttleLostItemNoticeView: UIView {
    private static let officeCoordinate = CLLocationCoordinate2D(latitude: 37.29275316695924, longitude: 126.83714484865253)

    init() {
        super.init(frame: .zero)
        let card = InquiryAnswerCardView(
            title: String(localized: "inquiry.shuttleLost.title"),
            detail: String(localized: "inquiry.shuttleLost.detail")
        )
        addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }

        card.addContent(makeMapPreview(officeName: String(localized: "inquiry.shuttleLost.office")))
        card.addContent(InquiryUI.infoGrid([
            InquiryInfoRow(
                String(localized: "inquiry.shuttleLost.locationLabel"),
                String(localized: "inquiry.shuttleLost.location")
            ),
            InquiryInfoRow(String(localized: "inquiry.phoneLabel"), "031-400-4412")
        ]))
        let mapButton = InquiryUI.actionButton(
            title: String(localized: "inquiry.shuttleLost.map"),
            systemImage: "map",
            filled: false
        )
        mapButton.accessibilityIdentifier = "inquiry.shuttle_lost.open_map"
        mapButton.addTarget(self, action: #selector(openOfficeMap), for: .touchUpInside)
        let callButton = InquiryUI.actionButton(
            title: String(localized: "inquiry.shuttleLost.call"),
            systemImage: "phone",
            filled: true
        )
        callButton.accessibilityIdentifier = "inquiry.shuttle_lost.call"
        callButton.addTarget(self, action: #selector(callOffice), for: .touchUpInside)
        card.addContent(InquiryUI.actionRow([mapButton, callButton]))
    }

    private func makeMapPreview(officeName: String) -> UIView {
        let map = MKMapView()
        map.layer.cornerRadius = 12
        map.layer.cornerCurve = .continuous
        map.clipsToBounds = true
        map.isUserInteractionEnabled = false
        map.isScrollEnabled = false
        map.isZoomEnabled = false
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.accessibilityIdentifier = "inquiry.shuttle_lost.map_preview"
        map.setRegion(MKCoordinateRegion(
            center: Self.officeCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        ), animated: false)
        let annotation = MKPointAnnotation()
        annotation.coordinate = Self.officeCoordinate
        annotation.title = officeName
        map.addAnnotation(annotation)

        let container = UIView()
        container.layer.cornerRadius = 12
        container.layer.cornerCurve = .continuous
        container.clipsToBounds = true
        container.addSubview(map)
        map.snp.makeConstraints { $0.edges.equalToSuperview() }
        let overlay = UIButton(type: .custom)
        overlay.accessibilityLabel = officeName
        overlay.addTarget(self, action: #selector(openOfficeMap), for: .touchUpInside)
        container.addSubview(overlay)
        overlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        container.snp.makeConstraints { $0.height.equalTo(112) }
        return container
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc
    private func openOfficeMap() {
        let officeName = String(localized: "inquiry.shuttleLost.office")
        let chooser = CommuterMapChooserVC(
            stopName: officeName,
            choices: InquiryMapChoices.choices(name: officeName, coordinate: Self.officeCoordinate)
        )
        var responder: UIResponder? = self
        while let current = responder {
            if let viewController = current as? UIViewController {
                viewController.present(chooser, animated: true)
                return
            }
            responder = current.next
        }
    }

    @objc
    private func callOffice() {
        guard let url = URL(string: "tel:0314004412") else { return }
        UIApplication.shared.open(url)
    }
}
