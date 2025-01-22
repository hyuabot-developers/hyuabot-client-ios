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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationItem.hidesBackButton = false
    }
    
    private func setupUI() {
        self.view.addSubview(self.mapView)
        self.view.addSubview(self.searchResultView)
        self.navigationItem.do {
            $0.title = String(localized: "tabbar.map")
            $0.searchController = self.searchController
            $0.hidesSearchBarWhenScrolling = false
            $0.hidesBackButton = true
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
}
