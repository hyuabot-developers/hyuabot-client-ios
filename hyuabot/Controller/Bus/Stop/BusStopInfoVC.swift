import UIKit
import MapKit
import RxSwift
import Api

class BusStopInfoVC: UIViewController {
    private let input: [BusRouteStopInput]
    private let disposeBag = DisposeBag()
    private let routeStops = BehaviorSubject<[BusStopDialogQuery.Data.Bus]>(value: [])
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 20, weight: .bold)
        $0.textColor = .white
        $0.backgroundColor = .hanyangBlue
        $0.textAlignment = .center
        $0.text = String(localized: "bus.stop.title")
    }
    private let stopMapView = MKMapView().then {
        $0.isZoomEnabled = true
        $0.isScrollEnabled = true
        $0.isPitchEnabled = false
    }
    private let firstLastTitleLabel = UILabel().then {
        $0.font = .godo(size: 18, weight: .bold)
        $0.text = String(localized: "bus.stop.first.last")
        $0.backgroundColor = .hanyangBlue
        $0.textColor = .white
        $0.textAlignment = .center
    }
    private lazy var firstLastTableView = UITableView().then {
        $0.dataSource = self
        $0.delegate = self
        $0.rowHeight = 65
        $0.register(BusFirstLastCellView.self, forCellReuseIdentifier: BusFirstLastCellView.reuseIdentifier)
    }
    private lazy var firstLastView: UIView = {
        let view = UIView()
        view.addSubview(self.firstLastTableView)
        view.backgroundColor = .systemBackground
        self.firstLastTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return view
    }()

    init(input: [BusRouteStopInput]) {
        self.input = input
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.fetchStopInfo()
        self.observeSubjects()
    }
    
    private func setupUI() {
        self.view.backgroundColor = .hanyangBlue
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.stopMapView)
        self.view.addSubview(self.firstLastTitleLabel)
        self.view.addSubview(self.firstLastView)
        self.stopMapView.delegate = self
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        self.stopMapView.snp.makeConstraints { make in
            make.height.equalTo(300)
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }
        self.firstLastTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.stopMapView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        self.firstLastView.snp.makeConstraints { make in
            make.top.equalTo(self.firstLastTitleLabel.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func fetchStopInfo() {
        Task {
            let response = try? await Network.shared.client.fetch(query: BusStopDialogQuery(routeStops: input))
            if let data = response?.data {
                self.routeStops.onNext(data.bus.sorted(by: {$0.route.name < $1.route.name}))
            }
        }
    }
    
    private func observeSubjects() {
        self.routeStops.subscribe(onNext: { [weak self] routeStops in
            guard let routeStop = routeStops.first else { return }
            self?.stopMapView.do {
                $0.removeAnnotations($0.annotations)
                $0.addAnnotation(MKPointAnnotation().with {
                    $0.coordinate = CLLocationCoordinate2D(latitude: routeStop.stop.latitude, longitude: routeStop.stop.longitude)
                    $0.title = routeStop.stop.name
                })
                $0.camera = MKMapCamera(
                    lookingAtCenter: CLLocationCoordinate2D(latitude: routeStop.stop.latitude, longitude: routeStop.stop.longitude),
                    fromDistance: 750,
                    pitch: 0,
                    heading: 0
                )
            }
            self?.firstLastTableView.reloadData()
        }).disposed(by: self.disposeBag)
    }
}

extension BusStopInfoVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "busStopAnnotation")
        annotationView.markerTintColor = .hanyangBlue
        annotationView.glyphImage = UIImage(systemName: "bus.doubledecker.fill")
        return annotationView
    }
}

extension BusStopInfoVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let routeStops = try? self.routeStops.value() else { return 0 }
        return routeStops.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let routeStops = try? self.routeStops.value() else { return UITableViewCell() }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BusFirstLastCellView.reuseIdentifier, for: indexPath) as? BusFirstLastCellView else {
            return UITableViewCell()
        }
        cell.setupUI(item: routeStops[indexPath.row])
        return cell
    }
}
