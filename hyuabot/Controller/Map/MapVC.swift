import UIKit
import MapKit
import RxSwift
import QueryAPI

class MapVC: UIViewController {
    private let disposeBag = DisposeBag()
    private lazy var searchController = UISearchController(searchResultsController: nil).then {
        $0.searchBar.do {
            $0.placeholder = String(localized: "map.building.search.placeholder")
            $0.directionalLayoutMargins = .init(top: 20, leading: 0, bottom: 0, trailing: 20)
            $0.searchTextField.do {
                $0.backgroundColor = .systemBackground
                $0.delegate = self
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
    }
    private lazy var searchResultView = UITableView().then {
        $0.showsVerticalScrollIndicator = false
        $0.isHidden = true
        $0.delegate = self
        $0.dataSource = self
        $0.register(SearchEmptyCellView.self, forCellReuseIdentifier: SearchEmptyCellView.reuseIdentifier)
        $0.register(SearchResultCellView.self, forCellReuseIdentifier: SearchResultCellView.reuseIdentifier)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.observeSubjects()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func setupUI() {
        self.view.addSubview(self.mapView)
        self.view.addSubview(self.searchResultView)
        self.navigationItem.do {
            $0.title = String(localized: "tabbar.map")
            $0.searchController = self.searchController
            $0.hidesSearchBarWhenScrolling = false
        }
        self.mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.searchResultView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func observeSubjects() {
        MapData.shared.searchKeyword.subscribe(onNext: { keyword in
            guard let keyword = keyword else { return }
            Network.shared.client.fetch(query: MapPageSearchQuery(keyword: keyword)) { result in
                if case .success(let response) = result {
                    MapData.shared.searchResult.onNext(response.data?.room ?? [])
                }
            }
        }).disposed(by: self.disposeBag)
        MapData.shared.searchResult.subscribe(onNext: { result in
            self.searchResultView.reloadData()
        }).disposed(by: self.disposeBag)
        MapData.shared.searchMode.subscribe(onNext: { isSearching in
            if (!isSearching) {
                self.searchController.isActive = false
                let nw = self.mapView.northWestCoordinate
                let se = self.mapView.southEastCoordinate
                Network.shared.client.fetch(query: MapPageQuery(
                    north: nw.latitude, south: se.latitude, west: nw.longitude, east: se.longitude
                )) { result in
                    if case .success(let response) = result {
                        MapData.shared.buildingResult.onNext(response.data?.building ?? [])
                    }
                }
            }
        }).disposed(by: self.disposeBag)
        MapData.shared.buildingResult.subscribe(onNext: { result in
            self.mapView.removeAnnotations(self.mapView.annotations)
            result.forEach { building in
                self.mapView.addAnnotation(MKPointAnnotation().with {
                    $0.coordinate = CLLocationCoordinate2D(latitude: building.latitude, longitude: building.longitude)
                    $0.title = building.name
                })
            }
        }).disposed(by: self.disposeBag)
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
        self.searchResultView.isHidden = searchKeyword.isEmpty
        MapData.shared.searchKeyword.onNext(searchKeyword.isEmpty ? nil : searchKeyword)
    }
}

extension MapVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let items = try? MapData.shared.searchResult.value() else { return 0 }
        return max(1, items.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let items = try? MapData.shared.searchResult.value() else { return SearchEmptyCellView() }
        if (items.isEmpty) {
            return tableView.dequeueReusableCell(withIdentifier: SearchEmptyCellView.reuseIdentifier, for: indexPath)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultCellView.reuseIdentifier, for: indexPath) as! SearchResultCellView
        cell.setupUI(item: items[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = try? MapData.shared.searchResult.value()[indexPath.row] else { return }
        MapData.shared.searchMode.onNext(true)
        self.mapView.do {
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
        self.searchResultView.isHidden = true
        self.searchController.isActive = false
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
        if (searchMode) { return }
        let nw = mapView.northWestCoordinate
        let se = mapView.southEastCoordinate
        Network.shared.client.fetch(query: MapPageQuery(
            north: nw.latitude, south: se.latitude, west: nw.longitude, east: se.longitude
        )) { result in
            if case .success(let response) = result {
                MapData.shared.buildingResult.onNext(response.data?.building ?? [])
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
        self.present(vc, animated: true, completion: nil)
    }
}
