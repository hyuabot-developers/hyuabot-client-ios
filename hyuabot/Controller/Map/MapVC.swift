import UIKit
import MapKit

class MapVC: UIViewController {
    private lazy var searchController = UISearchController(searchResultsController: nil).then {
        $0.searchBar.do {
            $0.placeholder = String(localized: "map.building.search.placeholder")
            $0.directionalLayoutMargins = .init(top: 20, leading: 0, bottom: 0, trailing: 20)
            $0.searchTextField.do {
                $0.backgroundColor = .systemBackground
            }
        }
        $0.searchResultsUpdater = self
    }
    private let mapView = MKMapView().then {
        $0.camera = MKMapCamera(
            lookingAtCenter: CLLocationCoordinate2D(latitude: 37.29650544998881, longitude: 126.83513202158153),
            fromDistance: 4000,
            pitch: 0,
            heading: 0
        )
        $0.isZoomEnabled = true
        $0.isScrollEnabled = true
        $0.isPitchEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationItem.hidesBackButton = false
    }
    
    private func setupUI() {
        self.view.addSubview(self.mapView)
        self.navigationItem.do {
            $0.title = String(localized: "tabbar.map")
            $0.searchController = self.searchController
            $0.hidesSearchBarWhenScrolling = false
            $0.hidesBackButton = true
        }
        self.mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension MapVC: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchKeyword = searchController.searchBar.text else { return }
        MapData.shared.searchKeyword.onNext(searchKeyword.isEmpty ? nil : searchKeyword)
    }
}
