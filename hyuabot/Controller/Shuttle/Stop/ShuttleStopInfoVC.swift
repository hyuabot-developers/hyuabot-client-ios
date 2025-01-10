import UIKit
import MapKit
import RxSwift
import QueryAPI

class ShuttleStopInfoVC: UIViewController {
    private let stop: ShuttleStopEnum
    private let stopInfo: BehaviorSubject<ShuttleStopDialogQuery.Data.Shuttle.Stop?> = BehaviorSubject(value: nil)
    private let timetable: BehaviorSubject<[ShuttleStopDialogQuery.Data.Shuttle.Timetable]> = BehaviorSubject(value: [])
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
        $0.isPitchEnabled = false
    }
    private let firstLastTitleLabel = UILabel().then {
        $0.font = .godo(size: 18, weight: .bold)
        $0.text = String(localized: "shuttle.stop.first.last")
        $0.backgroundColor = .hanyangBlue
        $0.textColor = .white
        $0.textAlignment = .center
    }
    private lazy var firstLastTimeHeaderStackView: UIStackView = {
        let destinationHeaderLabel = UILabel().then {
            $0.font = .godo(size: 16, weight: .bold)
            $0.text = String(localized: "shuttle.destination")
            $0.textAlignment = .center
        }
        let firstTimeHeaderLabel = UILabel().then {
            $0.font = .godo(size: 16, weight: .bold)
            $0.text = String(localized: "shuttle.first.time")
            $0.textAlignment = .center
        }
        let lastTimeHeaderLabel = UILabel().then {
            $0.font = .godo(size: 16, weight: .bold)
            $0.text = String(localized: "shuttle.last.time")
            $0.textAlignment = .center
        }
        let stackView = UIStackView(arrangedSubviews: [destinationHeaderLabel, firstTimeHeaderLabel, lastTimeHeaderLabel]).then {
            $0.axis = .horizontal
            $0.distribution = .fillEqually
            $0.alignment = .fill
            $0.spacing = 0
        }
        return stackView
    }()
    private let stationWeekdaysFirstTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.first.last.weekdays.na")
    }
    private let stationWeekdaysLastTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.first.last.weekdays.na")
    }
    private let stationWeekendsFirstTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.first.last.weekends.na")
    }
    private let stationWeekendsLastTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.first.last.weekends.na")
    }
    private lazy var stationFirstLastTimeStackView: UIStackView = {
        let destinationLabel = UILabel().then {
            $0.font = .godo(size: 16, weight: .bold)
            $0.text = String(localized: "shuttle.destination.shorten.station")
            $0.textAlignment = .center
        }
        let firstStackView = UIStackView(arrangedSubviews: [self.stationWeekdaysFirstTimeLabel, self.stationWeekendsFirstTimeLabel]).then {
            $0.axis = .vertical
            $0.distribution = .fillEqually
            $0.alignment = .fill
            $0.spacing = 15
        }
        let lastStackView = UIStackView(arrangedSubviews: [self.stationWeekdaysLastTimeLabel, self.stationWeekendsLastTimeLabel]).then {
            $0.axis = .vertical
            $0.distribution = .fillEqually
            $0.alignment = .fill
            $0.spacing = 15
        }
        let stackView = UIStackView(arrangedSubviews: [destinationLabel, firstStackView, lastStackView]).then {
            $0.axis = .horizontal
            $0.distribution = .fillEqually
            $0.alignment = .fill
            $0.spacing = 0
        }
        return stackView
    }()
    private let campusWeekdaysFirstTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.first.last.weekdays.na")
    }
    private let campusWeekdaysLastTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.first.last.weekdays.na")
    }
    private let campusWeekendsFirstTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.first.last.weekends.na")
    }
    private let campusWeekendsLastTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.first.last.weekends.na")
    }
    private lazy var campusFirstLastTimeStackView: UIStackView = {
        let destinationLabel = UILabel().then {
            $0.font = .godo(size: 16, weight: .bold)
            $0.text = String(localized: "shuttle.destination.shorten.campus")
            $0.textAlignment = .center
        }
        let firstStackView = UIStackView(arrangedSubviews: [self.campusWeekdaysFirstTimeLabel, self.campusWeekendsFirstTimeLabel]).then {
            $0.axis = .vertical
            $0.distribution = .fillEqually
            $0.alignment = .fill
            $0.spacing = 15
        }
        let lastStackView = UIStackView(arrangedSubviews: [self.campusWeekdaysLastTimeLabel, self.campusWeekendsLastTimeLabel]).then {
            $0.axis = .vertical
            $0.distribution = .fillEqually
            $0.alignment = .fill
            $0.spacing = 15
        }
        let stackView = UIStackView(arrangedSubviews: [destinationLabel, firstStackView, lastStackView]).then {
            $0.axis = .horizontal
            $0.distribution = .fillEqually
            $0.alignment = .fill
            $0.spacing = 0
        }
        return stackView
    }()
    private let terminalWeekdaysFirstTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.first.last.weekdays.na")
    }
    private let terminalWeekdaysLastTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.first.last.weekdays.na")
    }
    private let terminalWeekendsFirstTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.first.last.weekends.na")
    }
    private let terminalWeekendsLastTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.first.last.weekends.na")
    }
    private lazy var terminalFirstLastTimeStackView: UIStackView = {
        let destinationLabel = UILabel().then {
            $0.font = .godo(size: 16, weight: .bold)
            $0.text = String(localized: "shuttle.destination.shorten.terminal")
            $0.textAlignment = .center
        }
        let firstStackView = UIStackView(arrangedSubviews: [self.terminalWeekdaysFirstTimeLabel, self.terminalWeekendsFirstTimeLabel]).then {
            $0.axis = .vertical
            $0.distribution = .fillEqually
            $0.alignment = .fill
            $0.spacing = 15
        }
        let lastStackView = UIStackView(arrangedSubviews: [self.terminalWeekdaysLastTimeLabel, self.terminalWeekendsLastTimeLabel]).then {
            $0.axis = .vertical
            $0.distribution = .fillEqually
            $0.alignment = .fill
            $0.spacing = 15
        }
        let stackView = UIStackView(arrangedSubviews: [destinationLabel, firstStackView, lastStackView]).then {
            $0.axis = .horizontal
            $0.distribution = .fillEqually
            $0.alignment = .fill
            $0.spacing = 0
        }
        return stackView
    }()
    private let jungangStationWeekdaysFirstTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.first.last.weekdays.na")
    }
    private let jungangStationWeekdaysLastTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.first.last.weekdays.na")
    }
    private let jungangStationWeekendsFirstTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.first.last.weekends.na")
    }
    private let jungangStationWeekendsLastTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.first.last.weekends.na")
    }
    private lazy var jungangStationFirstLastTimeStackView: UIStackView = {
        let destinationLabel = UILabel().then {
            $0.font = .godo(size: 16, weight: .bold)
            $0.text = String(localized: "shuttle.destination.shorten.jungang_station")
            $0.textAlignment = .center
        }
        let firstStackView = UIStackView(arrangedSubviews: [self.jungangStationWeekdaysFirstTimeLabel, self.jungangStationWeekendsFirstTimeLabel]).then {
            $0.axis = .vertical
            $0.distribution = .fillEqually
            $0.alignment = .fill
            $0.spacing = 15
        }
        let lastStackView = UIStackView(arrangedSubviews: [self.jungangStationWeekdaysLastTimeLabel, self.jungangStationWeekendsLastTimeLabel]).then {
            $0.axis = .vertical
            $0.distribution = .fillEqually
            $0.alignment = .fill
            $0.spacing = 15
        }
        let stackView = UIStackView(arrangedSubviews: [destinationLabel, firstStackView, lastStackView]).then {
            $0.axis = .horizontal
            $0.distribution = .fillEqually
            $0.alignment = .fill
            $0.spacing = 0
        }
        return stackView
    }()
    private lazy var firstLastTimeStackView = UIStackView().then {
        $0.addArrangedSubview(self.firstLastTimeHeaderStackView)
        $0.addArrangedSubview(self.stationFirstLastTimeStackView)
        $0.addArrangedSubview(self.campusFirstLastTimeStackView)
        $0.addArrangedSubview(self.terminalFirstLastTimeStackView)
        $0.addArrangedSubview(self.jungangStationFirstLastTimeStackView)
        $0.axis = .vertical
        $0.spacing = 10
        $0.setCustomSpacing(25, after: self.stationFirstLastTimeStackView)
        $0.setCustomSpacing(25, after: self.campusFirstLastTimeStackView)
        $0.setCustomSpacing(25, after: self.terminalFirstLastTimeStackView)
    }
    private lazy var firstLastTimeView = UIView().then {
        $0.addSubview(self.firstLastTimeStackView)
        $0.backgroundColor = .systemBackground
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
        self.view.addSubview(self.firstLastTitleLabel)
        self.view.addSubview(self.firstLastTimeView)
        self.stopMapView.delegate = self
        if self.stop == .dormiotryOut {
            self.titleLabel.text = String(localized: "shuttle.stop.dormitory.out")
            self.campusFirstLastTimeStackView.isHidden = true
        } else if self.stop == .shuttlecockOut {
            self.titleLabel.text = String(localized: "shuttle.stop.shuttlecock.out")
            self.campusFirstLastTimeStackView.isHidden = true
        } else if self.stop == .station {
            self.titleLabel.text = String(localized: "shuttle.stop.station")
            self.stationFirstLastTimeStackView.isHidden = true
        } else if self.stop == .terminal {
            self.titleLabel.text = String(localized: "shuttle.stop.terminal")
            self.stationFirstLastTimeStackView.isHidden = true
            self.terminalFirstLastTimeStackView.isHidden = true
            self.jungangStationFirstLastTimeStackView.isHidden = true
        } else if self.stop == .jungangStation {
            self.titleLabel.text = String(localized: "shuttle.stop.jungang.station")
            self.stationFirstLastTimeStackView.isHidden = true
            self.terminalFirstLastTimeStackView.isHidden = true
            self.jungangStationFirstLastTimeStackView.isHidden = true
        } else if self.stop == .shuttlecockIn {
            self.titleLabel.text = String(localized: "shuttle.stop.shuttlecock.in")
            self.stationFirstLastTimeStackView.isHidden = true
            self.terminalFirstLastTimeStackView.isHidden = true
            self.jungangStationFirstLastTimeStackView.isHidden = true
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
        self.firstLastTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.stopMapView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        self.firstLastTimeStackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        self.firstLastTimeHeaderStackView.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        self.firstLastTimeView.snp.makeConstraints { make in
            make.top.equalTo(self.firstLastTitleLabel.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
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
                self.timetable.onNext(response.data?.shuttle.timetable.sorted(by: { $0.time < $1.time }) ?? [])
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
        self.timetable.subscribe(onNext: { timetableItems in
            if (self.stop == .dormiotryOut || self.stop == .shuttlecockOut) {
                let stationWeekdayItems = timetableItems.filter({ $0.weekdays && ($0.tag == "DH" || $0.tag == "DJ" || $0.tag == "C") })
                let stationWeekendItems = timetableItems.filter({ !$0.weekdays && ($0.tag == "DH" || $0.tag == "DJ" || $0.tag == "C") })
                let terminalWeekdayItems = timetableItems.filter({ $0.weekdays && ($0.tag == "DY" || $0.tag == "C") })
                let terminalWeekendItems = timetableItems.filter({ !$0.weekdays && ($0.tag == "DY" || $0.tag == "C") })
                let jungangStationWeekdayItems = timetableItems.filter({ $0.weekdays && $0.tag == "DJ" })
                let jungangStationWeekendItems = timetableItems.filter({ !$0.weekdays && $0.tag == "DJ" })
                if (!stationWeekdayItems.isEmpty) {
                    self.stationWeekdaysFirstTimeLabel.text = String(localized: "shuttle.first.last.weekdays.format.\(stationWeekdayItems.first!.time.substring(from: 0, to: 4))")
                    self.stationWeekdaysLastTimeLabel.text = String(localized: "shuttle.first.last.weekdays.format.\(stationWeekdayItems.last!.time.substring(from: 0, to: 4))")
                }
                if (!stationWeekendItems.isEmpty) {
                    self.stationWeekendsFirstTimeLabel.text = String(localized: "shuttle.first.last.weekends.format.\(stationWeekendItems.first!.time.substring(from: 0, to: 4))")
                    self.stationWeekendsLastTimeLabel.text = String(localized: "shuttle.first.last.weekends.format.\(stationWeekendItems.last!.time.substring(from: 0, to: 4))")
                }
                if (!terminalWeekdayItems.isEmpty) {
                    self.terminalWeekdaysFirstTimeLabel.text = String(localized: "shuttle.first.last.weekdays.format.\(terminalWeekdayItems.first!.time.substring(from: 0, to: 4))")
                    self.terminalWeekdaysLastTimeLabel.text = String(localized: "shuttle.first.last.weekdays.format.\(terminalWeekdayItems.last!.time.substring(from: 0, to: 4))")
                }
                if (!terminalWeekendItems.isEmpty) {
                    self.terminalWeekendsFirstTimeLabel.text = String(localized: "shuttle.first.last.weekends.format.\(terminalWeekendItems.first!.time.substring(from: 0, to: 4))")
                    self.terminalWeekendsLastTimeLabel.text = String(localized: "shuttle.first.last.weekends.format.\(terminalWeekendItems.last!.time.substring(from: 0, to: 4))")
                }
                if (!jungangStationWeekdayItems.isEmpty) {
                    self.jungangStationWeekdaysFirstTimeLabel.text = String(localized: "shuttle.first.last.weekdays.format.\(jungangStationWeekdayItems.first!.time.substring(from: 0, to: 4))")
                    self.jungangStationWeekdaysLastTimeLabel.text = String(localized: "shuttle.first.last.weekdays.format.\(jungangStationWeekdayItems.last!.time.substring(from: 0, to: 4))")
                }
                if (!jungangStationWeekendItems.isEmpty) {
                    self.jungangStationWeekendsFirstTimeLabel.text = String(localized: "shuttle.first.last.weekends.format.\(jungangStationWeekendItems.first!.time.substring(from: 0, to: 4))")
                    self.jungangStationWeekendsLastTimeLabel.text = String(localized: "shuttle.first.last.weekends.format.\(jungangStationWeekendItems.last!.time.substring(from: 0, to: 4))")
                }
            }
            else if (self.stop == .station) {
                let campusWeekdayItems = timetableItems.filter({ $0.weekdays })
                let campusWeekendItems = timetableItems.filter({ !$0.weekdays })
                let terminalWeekdayItems = timetableItems.filter({ $0.weekdays && $0.tag == "C" })
                let terminalWeekendItems = timetableItems.filter({ !$0.weekdays && $0.tag == "C" })
                let jungangStationWeekdayItems = timetableItems.filter({ $0.weekdays && $0.tag == "DJ" })
                let jungangStationWeekendItems = timetableItems.filter({ !$0.weekdays && $0.tag == "DJ" })
                if (!campusWeekdayItems.isEmpty) {
                    self.campusWeekdaysFirstTimeLabel.text = String(localized: "shuttle.first.last.weekdays.format.\(campusWeekdayItems.first!.time.substring(from: 0, to: 4))")
                    self.campusWeekdaysLastTimeLabel.text = String(localized: "shuttle.first.last.weekdays.format.\(campusWeekdayItems.last!.time.substring(from: 0, to: 4))")
                }
                if (!campusWeekendItems.isEmpty) {
                    self.campusWeekendsFirstTimeLabel.text = String(localized: "shuttle.first.last.weekends.format.\(campusWeekendItems.first!.time.substring(from: 0, to: 4))")
                    self.campusWeekendsLastTimeLabel.text = String(localized: "shuttle.first.last.weekends.format.\(campusWeekendItems.last!.time.substring(from: 0, to: 4))")
                }
                if (!terminalWeekdayItems.isEmpty) {
                    self.terminalWeekdaysFirstTimeLabel.text = String(localized: "shuttle.first.last.weekdays.format.\(terminalWeekdayItems.first!.time.substring(from: 0, to: 4))")
                    self.terminalWeekdaysLastTimeLabel.text = String(localized: "shuttle.first.last.weekdays.format.\(terminalWeekdayItems.last!.time.substring(from: 0, to: 4))")
                }
                if (!terminalWeekendItems.isEmpty) {
                    self.terminalWeekendsFirstTimeLabel.text = String(localized: "shuttle.first.last.weekends.format.\(terminalWeekendItems.first!.time.substring(from: 0, to: 4))")
                    self.terminalWeekendsLastTimeLabel.text = String(localized: "shuttle.first.last.weekends.format.\(terminalWeekendItems.last!.time.substring(from: 0, to: 4))")
                }
                if (!jungangStationWeekdayItems.isEmpty) {
                    self.jungangStationWeekdaysFirstTimeLabel.text = String(localized: "shuttle.first.last.weekdays.format.\(jungangStationWeekdayItems.first!.time.substring(from: 0, to: 4))")
                    self.jungangStationWeekdaysLastTimeLabel.text = String(localized: "shuttle.first.last.weekdays.format.\(jungangStationWeekdayItems.last!.time.substring(from: 0, to: 4))")
                }
                if (!jungangStationWeekendItems.isEmpty) {
                    self.jungangStationWeekendsFirstTimeLabel.text = String(localized: "shuttle.first.last.weekends.format.\(jungangStationWeekendItems.first!.time.substring(from: 0, to: 4))")
                    self.jungangStationWeekendsLastTimeLabel.text = String(localized: "shuttle.first.last.weekends.format.\(jungangStationWeekendItems.last!.time.substring(from: 0, to: 4))")
                }
            }
            else {
                let weekdayItems = timetableItems.filter({ $0.weekdays })
                let weekendItems = timetableItems.filter({ !$0.weekdays })
                if (!weekdayItems.isEmpty) {
                    self.campusWeekdaysFirstTimeLabel.text = String(localized: "shuttle.first.last.weekdays.format.\(weekdayItems.first!.time.substring(from: 0, to: 4))")
                    self.campusWeekdaysLastTimeLabel.text = String(localized: "shuttle.first.last.weekdays.format.\(weekdayItems.last!.time.substring(from: 0, to: 4))")
                }
                if (!weekendItems.isEmpty) {
                    self.campusWeekendsFirstTimeLabel.text = String(localized: "shuttle.first.last.weekends.format.\(weekendItems.first!.time.substring(from: 0, to: 4))")
                    self.campusWeekendsLastTimeLabel.text = String(localized: "shuttle.first.last.weekends.format.\(weekendItems.last!.time.substring(from: 0, to: 4))")
                }
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
