//
//  MapVC+Map.swift
//  hyuabot
//

import Api
import MapKit
import UIKit

extension MapVC: MKMapViewDelegate {
    var cachedBuildings: [MapPageQuery.Data.Building] { (try? MapData.shared.buildingResult.value()) ?? [] }

    func reloadBuildings() {
        let northWest = mapView.northWestCoordinate
        let southEast = mapView.southEastCoordinate
        guard MapRegionLogic.isUsable(
            north: northWest.latitude,
            south: southEast.latitude,
            west: northWest.longitude,
            east: southEast.longitude
        ) else { return }
        let token = buildingGate.begin()
        isLoadingBuildings = true
        if !isResultMode { statusPill.apply(.loading) }
        Task {
            let response = try? await Network.shared.client.fetch(query: MapPageQuery(
                north: northWest.latitude, south: southEast.latitude, west: northWest.longitude, east: southEast.longitude
            ))
            guard buildingGate.isCurrent(token) else { return }
            isLoadingBuildings = false
            if let data = response?.data {
                MapData.shared.buildingResult.onNext(data.building)
            } else if !isResultMode {
                statusPill.apply(.count(cachedBuildings.count))
            }
        }
    }

    func applyBuildings(_ buildings: [MapPageQuery.Data.Building]) {
        guard !isResultMode, !isSearchMode else { return }
        let selectedName: String? = { if case .building(let building) = mode { return building.name }; return nil }()
        isReconcilingAnnotations = true
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        let annotations = buildings.map { building -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: building.latitude, longitude: building.longitude)
            annotation.title = building.name
            return annotation
        }
        mapView.addAnnotations(annotations)
        isReconcilingAnnotations = false
        statusPill.apply(.count(buildings.count))
        if let selectedName {
            if let index = buildings.firstIndex(where: { $0.name == selectedName }) {
                let building = buildings[index]
                mode = .building(building)
                mapView.selectAnnotation(annotations[index], animated: false)
            } else {
                mode = .browse
                hideCard()
                updateDimming(selected: nil)
            }
        }
    }

    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        refreshBuildingsForVisibleRegion()
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        refreshBuildingsForVisibleRegion()
    }

    func refreshBuildingsForVisibleRegion() {
        guard !mapView.bounds.isEmpty,
              (try? MapData.shared.searchMode.value()) == false,
              !isResultMode, !isSearchMode else { return }
        reloadBuildings()
    }

    func reloadBuildingsIfNeeded() {
        guard !mapView.bounds.isEmpty,
              (try? MapData.shared.searchMode.value()) == false,
              !isResultMode, !isSearchMode,
              cachedBuildings.isEmpty, !isLoadingBuildings else { return }
        reloadBuildings()
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        let view = mapView.dequeueReusableAnnotationView(
            withIdentifier: MapPinAnnotationView.reuseIdentifier,
            for: annotation
        ) as? MapPinAnnotationView
            ?? MapPinAnnotationView(annotation: annotation, reuseIdentifier: MapPinAnnotationView.reuseIdentifier)
        view.annotation = annotation
        return view
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        if isSearchMode { return }
        if isResultMode { updateDimming(selected: annotation); return }
        guard let building = cachedBuildings.first(where: {
            $0.latitude == annotation.coordinate.latitude && $0.longitude == annotation.coordinate.longitude
        }) else { return }
        mode = .building(building)
        updateDimming(selected: annotation)
        let hasGuide = building.url.flatMap(URL.init(string:)) != nil
        let caption = hasGuide
            ? String(localized: "map.building.caption.available")
            : String(localized: "map.building.caption.unavailable")
        showCard(.init(
            title: building.name,
            caption: caption,
            translatesCaption: false,
            hasGuide: hasGuide,
            showsShowAll: false
        ))
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard !isReconcilingAnnotations else { return }
        if case .building = mode {
            mode = .browse
            hideCard()
            updateDimming(selected: nil)
        }
    }

    func updateDimming(selected: MKAnnotation?) {
        for annotation in mapView.annotations where !(annotation is MKUserLocation) {
            (mapView.view(for: annotation) as? MapPinAnnotationView)?.isDimmed = selected != nil && annotation !== selected
        }
    }

    func showAllBuildings() {
        searchBarView.text = ""
        MapData.shared.searchKeyword.onNext(nil)
        mode = .browse
        hideCard()
        applyBuildings(cachedBuildings)
        MapData.shared.searchMode.onNext(false)
    }

    func openGuide() {
        let buildingName: String
        let url: URL?
        switch mode {
        case .building(let building): buildingName = building.name; url = building.url.flatMap(URL.init(string:))
        case .result(let item): buildingName = item.building; url = resultGuideURL(item)
        default: return
        }
        guard let url else { return }
        let controller = BuildingVC(buildingName: buildingName, url: url)
        if let sheet = controller.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        present(controller, animated: true)
    }

    @objc
    func recenter() {
        if case .result(let item) = mode {
            let coordinate = CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude)
            mapView.camera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: 2000, pitch: 0, heading: 0)
        } else {
            mapView.camera = MKMapCamera(lookingAtCenter: Self.campusCenter, fromDistance: 4000, pitch: 0, heading: 0)
        }
    }
}
