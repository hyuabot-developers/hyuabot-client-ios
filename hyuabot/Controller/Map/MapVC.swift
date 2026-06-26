import Api
import MapKit
import RxSwift
import UIKit

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
                    MapData.shared.searchResult.onNext(data.building.map { building in
                        building.rooms.map { room in
                            RoomItem(
                                name: room.name,
                                number: room.name,
                                building: building.name,
                                latitude: building.latitude,
                                longitude: building.longitude
                            )
                        }
                    }.flatMap { $0 })
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
                self.mapView.addAnnotation(MKPointAnnotation().with {
                    $0.coordinate = CLLocationCoordinate2D(latitude: building.latitude, longitude: building.longitude)
                    $0.title = building.name
                })
            }
        }).disposed(by: disposeBag)
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
        guard let item = try? MapData.shared.searchResult.value()[indexPath.row] else { return }
        AnalyticsManager.logSelect(.mapSelectSearchResult, type: .listItem, name: item.name)
        MapData.shared.searchMode.onNext(true)
        mapView.do {
            $0.removeAnnotations($0.annotations)
            $0.addAnnotation(MKPointAnnotation().with {
                $0.coordinate = CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude)
                $0.title = "\(item.name) (\(item.number)호)"
            })
            $0.camera = MKMapCamera(
                lookingAtCenter: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude),
                fromDistance: 2000,
                pitch: 0,
                heading: 0
            )
        }
        searchResultView.isHidden = true
        searchController.isActive = false
    }
}

extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "marker")
        annotationView.markerTintColor = .hanyangBlue
        annotationView.glyphImage = UIImage(systemName: "building")
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
        guard let annotation = view.annotation else { return }
        guard let buildings = try? MapData.shared.buildingResult.value() else { return }
        guard let building = buildings.first(where: {
            $0.latitude == annotation.coordinate.latitude && $0.longitude == annotation.coordinate.longitude
        }) else { return }
        guard let urlString = building.url else { return }
        guard let url = URL(string: urlString) else { return }
        let vc = BuildingVC(buildingName: building.name, url: url)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true, completion: nil)
    }
}
