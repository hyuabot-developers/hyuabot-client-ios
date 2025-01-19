import UIKit
import MapKit
import RxSwift
import QueryAPI

class CafeteriaInfoVC: UIViewController {
    private let cafeteriaID: Int
    private let cafeteriaInfo: BehaviorSubject<CafeteriaInfoQuery.Data.Menu?> = BehaviorSubject(value: nil)
    private let disposeBag = DisposeBag()
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 20, weight: .bold)
        $0.textColor = .white
        $0.backgroundColor = .hanyangBlue
        $0.textAlignment = .center
    }
    private let cafeteriaMapView = MKMapView().then {
        $0.isZoomEnabled = true
        $0.isScrollEnabled = true
        $0.isPitchEnabled = false
    }
    private let runningTimeTitleLabel = UILabel().then {
        $0.font = .godo(size: 18, weight: .bold)
        $0.text = String(localized: "cafeteria.running.time")
        $0.backgroundColor = .hanyangBlue
        $0.textColor = .white
        $0.textAlignment = .center
    }
    private let breakfastTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textColor = .label
        $0.textAlignment = .right
        $0.text = "08:00"
    }
    private let lunchTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textColor = .label
        $0.textAlignment = .right
        $0.text = "12:00"
    }
    private let dinnerTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textColor = .label
        $0.textAlignment = .right
        $0.text = "18:00"
    }
    private lazy var runningTimeView = UIView().then {
        $0.backgroundColor = .systemBackground
        let breakfastLabel = UILabel().then {
            $0.font = .godo(size: 16, weight: .regular)
            $0.text = String(localized: "cafeteria.breakfast")
            $0.textColor = .label
            $0.textAlignment = .left
        }
        let lunchLabel = UILabel().then {
            $0.font = .godo(size: 16, weight: .regular)
            $0.text = String(localized: "cafeteria.lunch")
            $0.textColor = .label
            $0.textAlignment = .left
        }
        let dinnerLabel = UILabel().then {
            $0.font = .godo(size: 16, weight: .regular)
            $0.text = String(localized: "cafeteria.dinner")
            $0.textColor = .label
            $0.textAlignment = .left
        }
        $0.addSubview(breakfastLabel)
        $0.addSubview(self.breakfastTimeLabel)
        $0.addSubview(lunchLabel)
        $0.addSubview(self.lunchTimeLabel)
        $0.addSubview(dinnerLabel)
        $0.addSubview(self.dinnerTimeLabel)
        breakfastLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(20)
            make.height.equalTo(30)
        }
        lunchLabel.snp.makeConstraints { make in
            make.top.equalTo(breakfastLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(20)
            make.height.equalTo(30)
        }
        dinnerLabel.snp.makeConstraints { make in
            make.top.equalTo(lunchLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(20)
            make.height.equalTo(30)
        }
        self.breakfastTimeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(breakfastLabel)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(30)
        }
        self.lunchTimeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(lunchLabel)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(30)
        }
        self.dinnerTimeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(dinnerLabel)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(30)
        }
    }
    
    init(cafeteriaID: Int) {
        self.cafeteriaID = cafeteriaID
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.fetchCafeteriaInfo()
        self.observeSubjects()
    }
    
    private func setupUI() {
        self.view.backgroundColor = .hanyangBlue
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.cafeteriaMapView)
        self.view.addSubview(self.runningTimeTitleLabel)
        self.view.addSubview(self.runningTimeView)
        self.cafeteriaMapView.delegate = self
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        self.cafeteriaMapView.snp.makeConstraints { make in
            make.height.equalTo(300)
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }
        self.runningTimeTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.cafeteriaMapView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        self.runningTimeView.snp.makeConstraints { make in
            make.top.equalTo(self.runningTimeTitleLabel.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func fetchCafeteriaInfo() {
        Network.shared.client.fetch(query: CafeteriaInfoQuery(
            id: self.cafeteriaID
        )) { result in
            if case .success(let response) = result {
                self.cafeteriaInfo.onNext(response.data?.menu.first)
            }
        }
    }
    
    private func observeSubjects() {
        self.cafeteriaInfo.subscribe(onNext: { cafeteria in
            guard let cafeteria = cafeteria else { return }
            self.titleLabel.text = cafeteria.name
            self.breakfastTimeLabel.text = cafeteria.runningTime.breakfast ?? "-"
            self.lunchTimeLabel.text = cafeteria.runningTime.lunch ?? "-"
            self.dinnerTimeLabel.text = cafeteria.runningTime.dinner ?? "-"
            self.cafeteriaMapView.do {
                $0.removeAnnotations($0.annotations)
                if (cafeteria.latitude == 0 && cafeteria.longitude == 0) {
                    return
                }
                $0.addAnnotation(MKPointAnnotation().with {
                    $0.coordinate = CLLocationCoordinate2D(latitude: cafeteria.latitude, longitude: cafeteria.longitude)
                    $0.title = self.titleLabel.text
                })
                $0.camera = MKMapCamera(
                    lookingAtCenter: CLLocationCoordinate2D(latitude: cafeteria.latitude, longitude: cafeteria.longitude),
                    fromDistance: 750,
                    pitch: 0,
                    heading: 0
                )
            }
        }).disposed(by: self.disposeBag)
    }
}

extension CafeteriaInfoVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "cafeteriaAnnotation")
        annotationView.markerTintColor = .hanyangBlue
        annotationView.glyphImage = UIImage(systemName: "fork.knife.circle")
        return annotationView
    }
}
