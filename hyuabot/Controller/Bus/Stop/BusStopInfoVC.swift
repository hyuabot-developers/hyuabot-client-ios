import UIKit
import MapKit
import RxSwift
import QueryAPI

class BusStopInfoVC: UIViewController {
    private let stopID: Int
    private let disposeBag = DisposeBag()
    private let stopInfo = BehaviorSubject<BusStopDialogQuery.Data.Bus?>(value: nil)
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

    init(stopID: Int) {
        self.stopID = stopID
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
        Network.shared.client.fetch(query: BusStopDialogQuery(busStopID: self.stopID)) { result in
            if case .success(let response) = result {
                self.stopInfo.onNext(response.data?.bus.first)
            }
        }
    }
    
    private func observeSubjects() {
        self.stopInfo.subscribe(onNext: { [weak self] stop in
            guard let stop = stop else { return }
            self?.stopMapView.do {
                $0.removeAnnotations($0.annotations)
                $0.addAnnotation(MKPointAnnotation().with {
                    $0.coordinate = CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
                    $0.title = stop.name
                })
                $0.camera = MKMapCamera(
                    lookingAtCenter: CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude),
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
        guard let stop = try? self.stopInfo.value() else { return 0 }
        return stop.routes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let stop = try? self.stopInfo.value() else { return UITableViewCell() }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BusFirstLastCellView.reuseIdentifier, for: indexPath) as? BusFirstLastCellView else {
            return UITableViewCell()
        }
        cell.setupUI(item: stop.routes.sorted(by: {$0.info.name < $1.info.name})[indexPath.row])
        return cell
    }
}
