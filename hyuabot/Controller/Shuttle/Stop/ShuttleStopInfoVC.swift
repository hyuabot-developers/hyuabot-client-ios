import UIKit
import MapKit
import RxSwift
import QueryAPI

class ShuttleStopInfoVC: UIViewController {
    private let stop: ShuttleStopEnum
    private let stopInfo: BehaviorSubject<ShuttleStopDialogQuery.Data.Shuttle.Stop?> = BehaviorSubject(value: nil)
    private let disposeBag = DisposeBag()
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 20, weight: .bold)
        $0.textColor = .white
        $0.backgroundColor = .hanyangBlue
        $0.textAlignment = .center
    }
    
    private let stopMapView = MKMapView().then {
        $0.isZoomEnabled = true
        $0.isScrollEnabled = true
        $0.showsUserLocation = true
        $0.isPitchEnabled = false
    }

    init(stop: ShuttleStopEnum) {
        self.stop = stop
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
        self.stopMapView.delegate = self
        if self.stop == .dormiotryOut {
            self.titleLabel.text = String(localized: "shuttle.stop.dormitory.out")
        } else if self.stop == .shuttlecockOut {
            self.titleLabel.text = String(localized: "shuttle.stop.shuttlecock.out")
        } else if self.stop == .station {
            self.titleLabel.text = String(localized: "shuttle.stop.station")
        } else if self.stop == .terminal {
            self.titleLabel.text = String(localized: "shuttle.stop.terminal")
        } else if self.stop == .jungangStation {
            self.titleLabel.text = String(localized: "shuttle.stop.jungang.station")
        } else if self.stop == .shuttlecockIn {
            self.titleLabel.text = String(localized: "shuttle.stop.shuttlecock.in")
        } else {
            self.titleLabel.text = String(localized: "shuttle.stop.dormitory.out")
        }
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
    }
    
    private func fetchStopInfo() {
        let now = Date.now
        let dateTimeFormatter = DateFormatter().then { $0.dateFormat = "yyyy-MM-dd HH:mm" }
        let stopID = if self.stop == .dormiotryOut {
            "dormitory_o"
        } else if self.stop == .shuttlecockOut {
            "shuttlecock_o"
        } else if self.stop == .station {
            "station"
        } else if self.stop == .terminal {
            "terminal"
        } else if self.stop == .jungangStation {
            "jungang_stn"
        } else if self.stop == .shuttlecockIn {
            "shuttlecock_i"
        } else {
            "dormitory_o"
        }
        Network.shared.client.fetch(query: ShuttleStopDialogQuery(
            shuttleStopID: stopID, shuttleDateTime: dateTimeFormatter.string(from: now)
        )) { result in
            if case .success(let response) = result {
                self.stopInfo.onNext(response.data?.shuttle.stop.first)
            }
        }
    }
    
    private func observeSubjects() {
        self.stopInfo.subscribe(onNext: { stop in
            guard let stop = stop else { return }
            self.stopMapView.do {
                $0.removeAnnotations($0.annotations)
                $0.addAnnotation(MKPointAnnotation().with {
                    $0.coordinate = CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
                    $0.title = self.titleLabel.text
                })
                $0.camera = MKMapCamera(
                    lookingAtCenter: CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude),
                    fromDistance: 750,
                    pitch: 0,
                    heading: 0
                )
            }
        }).disposed(by: self.disposeBag)
    }
}

extension ShuttleStopInfoVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "shuttleStopAnnotation")
        annotationView.markerTintColor = .hanyangBlue
        annotationView.glyphImage = UIImage(systemName: "bus.fill")
        return annotationView
    }
}
