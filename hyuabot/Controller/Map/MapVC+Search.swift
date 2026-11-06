//
//  MapVC+Search.swift
//  hyuabot
//

import Api
import MapKit
import RxSwift
import UIKit

extension MapVC: UITableViewDataSource, UITableViewDelegate {
    var searchItems: [RoomItem] { (try? MapData.shared.searchResult.value()) ?? [] }

    func onTextChange(_ keyword: String) {
        let isVisible = MapSearchLogic.isSearchResultVisible(keyword: keyword)
        resultsContainer.isHidden = !isVisible
        MapData.shared.searchKeyword.onNext(isVisible ? keyword : nil)
    }

    func onClear() {
        resultsContainer.isHidden = true
        MapData.shared.searchKeyword.onNext(nil)
        if isResultMode { showAllBuildings() }
    }

    func observeSearch() {
        MapData.shared.searchKeyword.subscribe(onNext: { [weak self] rawKeyword in
            guard let self else { return }
            guard let keyword = MapSearchLogic.searchLaunchKeyword(rawKeyword, isSearching: self.isSearchMode) else {
                self.invalidateSearch()
                self.reloadSearchResults()
                return
            }
            let token = self.searchGate.begin()
            self.isLoadingSearch = true
            self.searchFailed = false
            self.reloadSearchResults()
            Task {
                let response = try? await Network.shared.client.fetch(query: MapPageSearchQuery(keyword: keyword))
                guard self.searchGate.isCurrent(token), case .searching = self.mode else { return }
                if let data = response?.data {
                    let items = data.building.flatMap { building in
                        building.rooms.map { room in
                            RoomItem(
                                name: room.name,
                                number: room.number,
                                building: building.name,
                                latitude: building.latitude,
                                longitude: building.longitude
                            )
                        }
                    }
                    self.searchFailed = false
                    self.isLoadingSearch = false
                    MapData.shared.searchResult.onNext(items)
                } else {
                    self.searchFailed = true
                    self.isLoadingSearch = false
                    MapData.shared.searchResult.onNext([])
                }
            }
        }).disposed(by: disposeBag)
        MapData.shared.searchResult.subscribe(onNext: { [weak self] _ in self?.reloadSearchResults() }).disposed(by: disposeBag)
    }

    func reloadSearchResults() {
        let items = searchItems
        resultsCountLabel.text = isLoadingSearch
            ? String(localized: "map.search.loading")
            : ((items.isEmpty || searchFailed) ? "" : String(format: String(localized: "map.search.count"), items.count))
        searchResultView.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        MapSearchLogic.rowCount(for: searchItems, isLoading: isLoadingSearch)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isLoadingSearch {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: MapSearchSkeletonCellView.reuseIdentifier,
                for: indexPath
            ) as? MapSearchSkeletonCellView else { return UITableViewCell() }
            cell.configure(index: indexPath.row, isFirst: indexPath.row == 0, isLast: indexPath.row == MapSearchLogic.skeletonRowCount - 1)
            return cell
        }
        if searchItems.isEmpty || searchFailed {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: SearchEmptyCellView.reuseIdentifier,
                for: indexPath
            ) as? SearchEmptyCellView else { return UITableViewCell() }
            if searchFailed { cell.configureFailure() } else { cell.configure(keyword: searchBarView.text) }
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SearchResultCellView.reuseIdentifier,
            for: indexPath
        ) as? SearchResultCellView else { return UITableViewCell() }
        cell.configure(item: searchItems[indexPath.row], isFirst: indexPath.row == 0, isLast: indexPath.row == searchItems.count - 1)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isLoadingSearch, !searchFailed, searchItems.indices.contains(indexPath.row) else { return }
        let item = searchItems[indexPath.row]
        AnalyticsManager.logSelect(.mapSelectSearchResult, type: .listItem, name: item.name)
        MapData.shared.searchMode.onNext(true)
        selectResult(item)
    }

    func selectResult(_ item: RoomItem) {
        mode = .result(item)
        invalidateSearch()
        resultsContainer.isHidden = true
        searchBarView.textField.resignFirstResponder()
        let roomTitle = MapSearchLogic.cardTitle(number: item.number, name: item.name)
        let building = item.building.trimmingCharacters(in: .whitespacesAndNewlines)
        searchBarView.text = roomTitle.contains(building) ? roomTitle : "\(building) \(roomTitle)"
        searchBarView.setSearching(false)
        isReconcilingAnnotations = true
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude)
        annotation.title = "\(item.building) \(MapSearchLogic.roomNumberText(item.number))"
        mapView.addAnnotation(annotation)
        isReconcilingAnnotations = false
        mapView.camera = MKMapCamera(lookingAtCenter: annotation.coordinate, fromDistance: 2000, pitch: 0, heading: 0)
        mapView.selectAnnotation(annotation, animated: true)
        statusPill.apply(.result)
        statusPill.isHidden = false
        recenterButton.isHidden = false
        let guideURL = resultGuideURL(item)
        showCard(.init(
            title: roomTitle,
            caption: item.building,
            translatesCaption: true,
            hasGuide: guideURL != nil,
            showsShowAll: true
        ))
    }

    func resultGuideURL(_ item: RoomItem) -> URL? {
        let buildings = (try? MapData.shared.buildingResult.value())?.map { ($0.name, $0.url) } ?? []
        return MapSearchLogic.guideURL(forBuildingNamed: item.building, in: buildings)
    }
}
