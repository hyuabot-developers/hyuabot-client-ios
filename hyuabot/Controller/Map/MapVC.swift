import Api
import MapKit
import RxSwift
import UIKit

private final class BuildingMapAnnotation: MKPointAnnotation {
    let buildingName: String
    let urlString: String?
    let buildingID: String?

    init(buildingName: String, urlString: String?, buildingID: String?, coordinate: CLLocationCoordinate2D, title: String) {
        self.buildingName = buildingName
        self.urlString = urlString
        self.buildingID = buildingID
        super.init()
        self.coordinate = coordinate
        self.title = title
    }
}

class MapVC: UIViewController {
    private let disposeBag = DisposeBag()
    private lazy var searchController = UISearchController(searchResultsController: nil).then {
        $0.searchBar.do {
            $0.placeholder = String(localized: "map.building.search.placeholder")
            $0.directionalLayoutMargins = .init(top: 20, leading: 0, bottom: 0, trailing: 20)
            $0.searchTextField.do {
                $0.backgroundColor = .systemBackground
                $0.delegate = self
                $0.accessibilityIdentifier = "map.search_text_field"
            }
        }
        $0.searchResultsUpdater = self
    }

    private lazy var mapView = MKMapView().then {
        $0.camera = MKMapCamera(
            lookingAtCenter: CLLocationCoordinate2D(latitude: 37.29650544998881, longitude: 126.83513202158153),
            fromDistance: 4000,
            pitch: 0,
            heading: 0
        )
        $0.isZoomEnabled = true
        $0.isScrollEnabled = true
        $0.isPitchEnabled = true
        $0.delegate = self
        $0.accessibilityIdentifier = "map.view"
    }

    private lazy var searchResultView = UITableView().then {
        $0.showsVerticalScrollIndicator = false
        $0.isHidden = true
        $0.rowHeight = UITableView.automaticDimension
        $0.estimatedRowHeight = 64
        $0.delegate = self
        $0.dataSource = self
        $0.register(SearchEmptyCellView.self, forCellReuseIdentifier: SearchEmptyCellView.reuseIdentifier)
        $0.register(SearchResultCellView.self, forCellReuseIdentifier: SearchResultCellView.reuseIdentifier)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.map)
        showCoachMarksIfNeeded()
    }

    private func showCoachMarksIfNeeded() {
        presentCoachMarks(pageId: "map", items: [
            CoachMarkItem(
                id: "map.search",
                targetView: searchController.searchBar,
                title: String(localized: "coach.map.search.title"),
                message: String(localized: "coach.map.search.message")
            ),
            CoachMarkItem(
                id: "map.map",
                targetView: mapView,
                title: String(localized: "coach.map.map.title"),
                message: String(localized: "coach.map.map.message")
            )
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeSubjects()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    private func setupUI() {
        view.addSubview(mapView)
        view.addSubview(searchResultView)
        navigationItem.do {
            $0.title = String(localized: "tabbar.map")
            $0.searchController = self.searchController
            $0.hidesSearchBarWhenScrolling = false
        }
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        searchResultView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func observeSubjects() {
        MapData.shared.searchKeyword.subscribe(onNext: { keyword in
            guard let keyword else { return }
            Task {
                let response = try? await Network.shared.client.fetch(query: MapPageSearchQuery(keyword: keyword))
                if let data = response?.data {
                    MapData.shared.searchResult.onNext(data.building.flatMap { building in
                        building.rooms.map { room in
                            RoomItem(
                                name: room.name,
                                number: room.number,
                                building: building.name,
                                latitude: building.latitude,
                                longitude: building.longitude,
                                url: building.url,
                                seq: building.seq
                            )
                        }
                    })
                }
            }
        }).disposed(by: disposeBag)
        MapData.shared.searchResult.subscribe(onNext: { _ in
            self.searchResultView.reloadData()
        }).disposed(by: disposeBag)
        MapData.shared.searchMode.subscribe(onNext: { isSearching in
            if !isSearching {
                self.searchController.isActive = false
                let nw = self.mapView.northWestCoordinate
                let se = self.mapView.southEastCoordinate
                Task {
                    let response = try? await Network.shared.client.fetch(query: MapPageQuery(
                        north: nw.latitude, south: se.latitude, west: nw.longitude, east: se.longitude
                    ))
                    if let data = response?.data {
                        MapData.shared.buildingResult.onNext(data.building)
                    }
                }
            }
        }).disposed(by: disposeBag)
        MapData.shared.buildingResult.subscribe(onNext: { result in
            self.mapView.removeAnnotations(self.mapView.annotations)
            for building in result {
                self.mapView.addAnnotation(BuildingMapAnnotation(
                    buildingName: building.name,
                    urlString: building.url,
                    buildingID: nil,
                    coordinate: CLLocationCoordinate2D(latitude: building.latitude, longitude: building.longitude),
                    title: building.name
                ))
            }
        }).disposed(by: disposeBag)
    }

    private func showBuildingDetail(_ annotation: BuildingMapAnnotation) {
        guard let urlString = annotation.urlString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !urlString.isEmpty,
              let url = URL(string: urlString),
              url.scheme != nil
        else {
            let alert = UIAlertController(
                title: annotation.buildingName,
                message: String(localized: "map.building.detail.unavailable"),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: String(localized: "common.ok"), style: .default))
            present(alert, animated: true)
            return
        }
        let vc = BuildingVC(buildingName: annotation.buildingName, url: url)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }
}

extension MapVC: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        MapData.shared.searchKeyword.onNext(nil)
        MapData.shared.searchMode.onNext(false)
        return true
    }
}

extension MapVC: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchKeyword = searchController.searchBar.text else { return }
        let isVisible = MapSearchLogic.isSearchResultVisible(keyword: searchKeyword)
        searchResultView.isHidden = !isVisible
        MapData.shared.searchKeyword.onNext(isVisible ? searchKeyword : nil)
    }
}

extension MapVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let items = try? MapData.shared.searchResult.value() else { return 0 }
        return MapSearchLogic.rowCount(for: items)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let items = try? MapData.shared.searchResult.value() else { return SearchEmptyCellView() }
        if items.isEmpty {
            return tableView.dequeueReusableCell(withIdentifier: SearchEmptyCellView.reuseIdentifier, for: indexPath)
        }
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SearchResultCellView.reuseIdentifier,
            for: indexPath
        ) as! SearchResultCellView
        cell.setupUI(item: items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let searchResults = try? MapData.shared.searchResult.value(),
              indexPath.row < searchResults.count else { return }
        let item = searchResults[indexPath.row]
        AnalyticsManager.logSelect(.mapSelectSearchResult, type: .listItem, name: item.name)
        MapData.shared.searchMode.onNext(true)
        let annotation = BuildingMapAnnotation(
            buildingName: item.building,
            urlString: item.url,
            buildingID: item.seq,
            coordinate: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude),
            title: "\(item.name) · \(item.building) · \(String(format: String(localized: "map.room.number.format"), item.number))"
        )
        mapView.do {
            $0.removeAnnotations($0.annotations)
            $0.addAnnotation(annotation)
            $0.camera = MKMapCamera(
                lookingAtCenter: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude),
                fromDistance: 2000,
                pitch: 0,
                heading: 0
            )
        }

        searchResultView.isHidden = true
        searchController.dismiss(animated: true) { [weak self] in
            self?.showBuildingDetail(annotation)
        }
    }
}

extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "marker")
        annotationView.markerTintColor = .hanyangBlue
        annotationView.glyphImage = UIImage(systemName: "building")
        if let building = annotation as? BuildingMapAnnotation {
            annotationView.accessibilityIdentifier = "map.building.\(building.buildingID ?? building.buildingName)"
        }
        return annotationView
    }

    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        guard let searchMode = try? MapData.shared.searchMode.value() else { return }
        if searchMode { return }
        let nw = mapView.northWestCoordinate
        let se = mapView.southEastCoordinate
        Task {
            let response = try? await Network.shared.client.fetch(query: MapPageQuery(
                north: nw.latitude, south: se.latitude, west: nw.longitude, east: se.longitude
            ))
            if let data = response?.data {
                MapData.shared.buildingResult.onNext(data.building)
            }
        }
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let building = view.annotation as? BuildingMapAnnotation else { return }
        showBuildingDetail(building)
    }
}
