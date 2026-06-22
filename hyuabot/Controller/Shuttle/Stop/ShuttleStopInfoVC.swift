import UIKit
import MapKit
import RxSwift
import Api

class ShuttleStopInfoVC: UIViewController {
    private typealias StopTimetableDestination = ShuttleStopDialogQuery.Data.Shuttle.Stop.Timetable.Destination
    private typealias StopTimetableEntry = ShuttleStopDialogQuery.Data.Shuttle.Stop.Timetable.Destination.Entry

    private let stop: ShuttleStopEnum
    private let stopInfo: BehaviorSubject<ShuttleStopDialogQuery.Data.Shuttle.Stop?> = BehaviorSubject(value: nil)
    private let timetable: BehaviorSubject<[ShuttleStopDialogQuery.Data.Shuttle.Stop.Timetable.Destination]> = BehaviorSubject(value: [])
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.logScreenView(.shuttleStopInfo)
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
        let dateFormatter = DateFormatter().then {
            $0.dateFormat = "yyyy-MM-dd"
        }
        ShuttleTimetableData.shared.isLoading.onNext(true)
        Task {
            let response = try? await Network.shared.client.fetch(query: ShuttleTimetablePeriodQuery(date: dateFormatter.string(from: Foundation.Date.now)))
            guard let period = response?.data?.shuttle.period?.type else {
                publishStopInfo(nil, timetable: [])
                return
            }
            let stopResponse = try? await Network.shared.client.fetch(query: ShuttleStopDialogQuery(stopID: stopID, period: [period]))
            let stop = stopResponse?.data?.shuttle.stops.first
            publishStopInfo(stop, timetable: stop?.timetable.destination ?? [])
        }
    }

    private func publishStopInfo(
        _ stop: ShuttleStopDialogQuery.Data.Shuttle.Stop?,
        timetable: [ShuttleStopDialogQuery.Data.Shuttle.Stop.Timetable.Destination]
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.stopInfo.onNext(stop)
            self?.timetable.onNext(timetable)
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
                self.updateFirstLastTime(timetableItems, destination: "STATION", isWeekday: true, firstLabel: self.stationWeekdaysFirstTimeLabel, lastLabel: self.stationWeekdaysLastTimeLabel)
                self.updateFirstLastTime(timetableItems, destination: "STATION", isWeekday: false, firstLabel: self.stationWeekendsFirstTimeLabel, lastLabel: self.stationWeekendsLastTimeLabel)
                self.updateFirstLastTime(timetableItems, destination: "TERMINAL", isWeekday: true, firstLabel: self.terminalWeekdaysFirstTimeLabel, lastLabel: self.terminalWeekdaysLastTimeLabel)
                self.updateFirstLastTime(timetableItems, destination: "TERMINAL", isWeekday: false, firstLabel: self.terminalWeekendsFirstTimeLabel, lastLabel: self.terminalWeekendsLastTimeLabel)
                self.updateFirstLastTime(timetableItems, destination: "JUNGANG", isWeekday: true, firstLabel: self.jungangStationWeekdaysFirstTimeLabel, lastLabel: self.jungangStationWeekdaysLastTimeLabel)
                self.updateFirstLastTime(timetableItems, destination: "JUNGANG", isWeekday: false, firstLabel: self.jungangStationWeekendsFirstTimeLabel, lastLabel: self.jungangStationWeekendsLastTimeLabel)
            }
            else if (self.stop == .station) {
                self.updateFirstLastTime(timetableItems, destination: "CAMPUS", isWeekday: true, firstLabel: self.campusWeekdaysFirstTimeLabel, lastLabel: self.campusWeekdaysLastTimeLabel)
                self.updateFirstLastTime(timetableItems, destination: "CAMPUS", isWeekday: false, firstLabel: self.campusWeekendsFirstTimeLabel, lastLabel: self.campusWeekendsLastTimeLabel)
                self.updateFirstLastTime(timetableItems, destination: "TERMINAL", isWeekday: true, firstLabel: self.terminalWeekdaysFirstTimeLabel, lastLabel: self.terminalWeekdaysLastTimeLabel)
                self.updateFirstLastTime(timetableItems, destination: "TERMINAL", isWeekday: false, firstLabel: self.terminalWeekendsFirstTimeLabel, lastLabel: self.terminalWeekendsLastTimeLabel)
                self.updateFirstLastTime(timetableItems, destination: "JUNGANG", isWeekday: true, firstLabel: self.jungangStationWeekdaysFirstTimeLabel, lastLabel: self.jungangStationWeekdaysLastTimeLabel)
                self.updateFirstLastTime(timetableItems, destination: "JUNGANG", isWeekday: false, firstLabel: self.jungangStationWeekendsFirstTimeLabel, lastLabel: self.jungangStationWeekendsLastTimeLabel)
            }
            else {
                self.updateFirstLastTime(timetableItems, destination: "CAMPUS", isWeekday: true, firstLabel: self.campusWeekdaysFirstTimeLabel, lastLabel: self.campusWeekdaysLastTimeLabel)
                self.updateFirstLastTime(timetableItems, destination: "CAMPUS", isWeekday: false, firstLabel: self.campusWeekendsFirstTimeLabel, lastLabel: self.campusWeekendsLastTimeLabel)
            }
                
        }).disposed(by: self.disposeBag)
    }

    private func updateFirstLastTime(
        _ timetableItems: [StopTimetableDestination],
        destination: String,
        isWeekday: Bool,
        firstLabel: UILabel,
        lastLabel: UILabel
    ) {
        let entries = timetableItems
            .first(where: { $0.destination == destination })?
            .entries
            .filter { $0.weekday == isWeekday }
            .sorted(by: { $0.time < $1.time }) ?? []

        guard let first = entries.first,
              let last = entries.last else {
            setFirstLastTimeLabels(firstLabel: firstLabel, lastLabel: lastLabel, first: nil, last: nil, isWeekday: isWeekday)
            return
        }
        setFirstLastTimeLabels(firstLabel: firstLabel, lastLabel: lastLabel, first: first, last: last, isWeekday: isWeekday)
    }

    private func setFirstLastTimeLabels(
        firstLabel: UILabel,
        lastLabel: UILabel,
        first: StopTimetableEntry?,
        last: StopTimetableEntry?,
        isWeekday: Bool
    ) {
        firstLabel.text = firstLastTimeText(first?.time, isWeekday: isWeekday)
        lastLabel.text = firstLastTimeText(last?.time, isWeekday: isWeekday)
    }

    private func firstLastTimeText(_ time: String?, isWeekday: Bool) -> String {
        let unavailableKey = isWeekday ? "shuttle.first.last.weekdays.na" : "shuttle.first.last.weekends.na"
        guard let time else { return String(localized: String.LocalizationValue(unavailableKey)) }
        let shortened = time.substring(from: 0, to: 4)
        guard !shortened.isEmpty else { return String(localized: String.LocalizationValue(unavailableKey)) }
        let formatKey = isWeekday ? "shuttle.first.last.weekdays.format.%@" : "shuttle.first.last.weekends.format.%@"
        return String(format: String(localized: String.LocalizationValue(formatKey)), shortened)
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
