import Api
import MapKit
import RxSwift
import UIKit

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

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.busStopInfo)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchStopInfo()
        observeSubjects()
    }

    private func setupUI() {
        view.backgroundColor = .hanyangBlue
        view.addSubview(titleLabel)
        view.addSubview(stopMapView)
        view.addSubview(firstLastTitleLabel)
        view.addSubview(firstLastView)
        stopMapView.delegate = self
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        stopMapView.snp.makeConstraints { make in
            make.height.equalTo(300)
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }
        firstLastTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.stopMapView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        firstLastView.snp.makeConstraints { make in
            make.top.equalTo(self.firstLastTitleLabel.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func fetchStopInfo() {
        Task {
            let response = try? await Network.shared.client.fetch(query: BusStopDialogQuery(routeStops: input))
            if let data = response?.data {
                self.routeStops.onNext(data.bus.sorted(by: { $0.route.name < $1.route.name }))
            }
        }
    }

    private func observeSubjects() {
        routeStops.subscribe(onNext: { [weak self] routeStops in
            guard let routeStop = routeStops.first else { return }
            self?.stopMapView.do {
                $0.removeAnnotations($0.annotations)
                $0.addAnnotation(MKPointAnnotation().with {
                    $0.coordinate = CLLocationCoordinate2D(latitude: routeStop.stop.latitude, longitude: routeStop.stop.longitude)
                    $0.title = routeStop.stop.name
                    let annotation = $0
                    Task {
                        annotation.title = await KoreanTextTranslator.shared.translate(routeStop.stop.name)
                    }
                })
                $0.camera = MKMapCamera(
                    lookingAtCenter: CLLocationCoordinate2D(latitude: routeStop.stop.latitude, longitude: routeStop.stop.longitude),
                    fromDistance: 750,
                    pitch: 0,
                    heading: 0
                )
            }
            self?.firstLastTableView.reloadData()
        }).disposed(by: disposeBag)
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
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let routeStops = try? routeStops.value() else { return 0 }
        return routeStops.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let routeStops = try? routeStops.value() else { return UITableViewCell() }
        guard let cell = tableView
            .dequeueReusableCell(withIdentifier: BusFirstLastCellView.reuseIdentifier, for: indexPath) as? BusFirstLastCellView
        else {
            return UITableViewCell()
        }
        cell.setupUI(item: routeStops[indexPath.row])
        return cell
    }
}
