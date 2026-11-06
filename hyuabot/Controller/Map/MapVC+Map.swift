//
//  MapVC+Map.swift
//  hyuabot
//

import Api
import MapKit
import UIKit

private struct MapBuildingIdentity: Hashable {
    let name: String
    let latitude: Double
    let longitude: Double

    init(_ building: MapPageQuery.Data.Building) {
        name = building.name
        latitude = building.latitude
        longitude = building.longitude
    }
}

private final class MapBuildingAnnotation: MKPointAnnotation {
    let identity: MapBuildingIdentity

    init(_ building: MapPageQuery.Data.Building) {
        identity = MapBuildingIdentity(building)
        super.init()
        coordinate = CLLocationCoordinate2D(latitude: building.latitude, longitude: building.longitude)
        title = building.name
    }
}

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
        let selectedBuilding: MapPageQuery.Data.Building? = {
            if case .building(let building) = mode { return building }; return nil
        }()
        let selectedIdentity = selectedBuilding.map(MapBuildingIdentity.init)
        var existing = mapView.annotations.compactMap { $0 as? MapBuildingAnnotation }
            .reduce(into: [MapBuildingIdentity: MapBuildingAnnotation]()) { $0[$1.identity] = $1 }
        var desired = Set(buildings.map(MapBuildingIdentity.init))
        // Keep the selected pin even when a pan moves it outside the fetched region.
        if let selectedIdentity { desired.insert(selectedIdentity) }
        isReconcilingAnnotations = true
        defer { isReconcilingAnnotations = false }
        mapView.removeAnnotations(mapView.annotations.filter { annotation in
            guard !(annotation is MKUserLocation), !(annotation is MKClusterAnnotation) else { return false }
            guard let building = annotation as? MapBuildingAnnotation else { return true }
            return !desired.contains(building.identity)
        })
        var additions: [MapBuildingAnnotation] = []
        for building in buildings {
            let identity = MapBuildingIdentity(building)
            if existing[identity] == nil {
                let annotation = MapBuildingAnnotation(building)
                existing[identity] = annotation
                additions.append(annotation)
            }
            if identity == selectedIdentity {
                mode = .building(building)
            }
        }
        if let selectedBuilding, let selectedIdentity, existing[selectedIdentity] == nil {
            let annotation = MapBuildingAnnotation(selectedBuilding)
            additions.append(annotation)
        }
        mapView.addAnnotations(additions)
        if let recreatedSelection = additions.first(where: { $0.identity == selectedIdentity }) {
            mapView.selectAnnotation(recreatedSelection, animated: false)
        }
        statusPill.apply(.count(buildings.count))
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
        mapView.register(MapPinAnnotationView.self, forAnnotationViewWithReuseIdentifier: MapPinAnnotationView.reuseIdentifier)
        mapView.register(MapClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MapClusterAnnotationView.reuseIdentifier)
        if annotation is MKClusterAnnotation {
            return mapView.dequeueReusableAnnotationView(withIdentifier: MapClusterAnnotationView.reuseIdentifier, for: annotation)
        }
        let view = mapView.dequeueReusableAnnotationView(
            withIdentifier: MapPinAnnotationView.reuseIdentifier,
            for: annotation
        ) as? MapPinAnnotationView
            ?? MapPinAnnotationView(annotation: annotation, reuseIdentifier: MapPinAnnotationView.reuseIdentifier)
        view.annotation = annotation
        view.clustersWithBuildings = annotation is MapBuildingAnnotation
        if case .building(let building) = mode, let pin = annotation as? MapBuildingAnnotation {
            let isSelected = pin.identity == MapBuildingIdentity(building)
            view.setSelected(isSelected, animated: false)
            view.isDimmed = !isSelected
        } else {
            view.setSelected(mapView.selectedAnnotations.contains { $0 === annotation }, animated: false)
            view.isDimmed = false
        }
        return view
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard !isReconcilingAnnotations else { return }
        guard let annotation = view.annotation else { return }
        if let cluster = annotation as? MKClusterAnnotation {
            mapView.deselectAnnotation(cluster, animated: false)
            zoomToCluster(cluster)
            return
        }
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
        guard !(view.annotation is MKClusterAnnotation) else { return }
        if case .building = mode {
            mode = .browse
            hideCard()
            updateDimming(selected: nil)
        }
    }

    private func zoomToCluster(_ cluster: MKClusterAnnotation) {
        guard !isSearchMode, !isResultMode else { return }
        let rect = cluster.memberAnnotations.reduce(MKMapRect.null) { rect, annotation in
            let point = MKMapPoint(annotation.coordinate)
            return rect.union(MKMapRect(x: point.x, y: point.y, width: 1, height: 1))
        }
        guard !rect.isNull else { return }
        mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(
            top: view.safeAreaInsets.top + 96,
            left: 48,
            bottom: view.safeAreaInsets.bottom + max(96, buildingCard.isHidden ? 0 : buildingCard.bounds.height + 24),
            right: 48
        ), animated: true)
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
