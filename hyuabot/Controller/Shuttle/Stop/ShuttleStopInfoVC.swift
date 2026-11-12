//
//  ShuttleStopInfoVC.swift
//  hyuabot
//

import Api
import MapKit
import RxSwift
import SnapKit
import UIKit

class ShuttleStopInfoVC: UIViewController {
    private typealias StopTimetableDestination = ShuttleStopDialogQuery.Data.Shuttle.Stop.Timetable.Destination
    private typealias StopTimetableEntry = ShuttleStopDialogQuery.Data.Shuttle.Stop.Timetable.Destination.Entry

    private let stop: ShuttleStopEnum
    private let stopInfo: BehaviorSubject<ShuttleStopDialogQuery.Data.Shuttle.Stop?> = BehaviorSubject(value: nil)
    private let timetable: BehaviorSubject<[ShuttleStopDialogQuery.Data.Shuttle.Stop.Timetable.Destination]> = BehaviorSubject(value: [])
    private let disposeBag = DisposeBag()
    private let titleLabel = UILabel().then {
        $0.font = SettingsStyle.font(20, bold: true)
        $0.textColor = .white
        $0.backgroundColor = SettingsStyle.Color.accent
        $0.textAlignment = .center
    }

    private lazy var sheetView = HYUSheetView(title: String(localized: "shuttle.destination"))

    private let stopMapView = MKMapView().then {
        $0.isZoomEnabled = false
        $0.isScrollEnabled = false
        $0.isRotateEnabled = false
        $0.isPitchEnabled = false
    }

    private let rowsCard = HYUSheetView.card()
    private var destinations: [StopDestination] {
        switch stop {
        case .dormiotryOut, .shuttlecockOut: [.station, .terminal, .jungang]
        case .station: [.campus, .terminal, .jungang]
        default: [.campus]
        }
    }

    private enum StopDestination {
        case campus, station, terminal, jungang

        var apiKey: String {
            switch self {
            case .campus: "CAMPUS"
            case .station: "STATION"
            case .terminal: "TERMINAL"
            case .jungang: "JUNGANG"
            }
        }

        var title: String {
            switch self {
            case .campus: String(localized: "shuttle.destination.shorten.campus")
            case .station: String(localized: "shuttle.destination.shorten.station")
            case .terminal: String(localized: "shuttle.destination.shorten.terminal")
            case .jungang: String(localized: "shuttle.destination.shorten.jungang_station")
            }
        }
    }

    init(stop: ShuttleStopEnum) {
        self.stop = stop
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.shuttleStopInfo)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchStopInfo()
        observeSubjects()
    }

    private var stopTitle: String {
        switch stop {
        case .dormiotryOut: String(localized: "shuttle.stop.dormitory.out")
        case .shuttlecockOut: String(localized: "shuttle.stop.shuttlecock.out")
        case .station: String(localized: "shuttle.stop.station")
        case .terminal: String(localized: "shuttle.stop.terminal")
        case .jungangStation: String(localized: "shuttle.stop.jungang.station")
        case .shuttlecockIn: String(localized: "shuttle.stop.shuttlecock.in")
        default: String(localized: "shuttle.stop.dormitory.out")
        }
    }

    var sheetHeight: CGFloat {
        view.layoutIfNeeded()
        return sheetView.contentHeight
    }

    private func setupUI() {
        view.backgroundColor = SettingsStyle.Color.sheet
        view.addSubview(sheetView)
        stopMapView.delegate = self
        stopMapView.layer.cornerRadius = 16
        stopMapView.layer.cornerCurve = .continuous
        stopMapView.clipsToBounds = true
        titleLabel.text = stopTitle
        sheetView.setTitle(String(format: String(localized: "shuttle.stop.info.title.%@"), stopTitle))
        sheetView.contentStack.addArrangedSubview(stopMapView)
        stopMapView.snp.makeConstraints { $0.height.equalTo(184) }
        sheetView.contentStack.addArrangedSubview(HYUSheetView.sectionHeader(String(localized: "shuttle.stop.info.section")))
        sheetView.contentStack.addArrangedSubview(rowsCard)
        renderRows([])
        sheetView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func fetchStopInfo() {
        let stopID = if stop == .dormiotryOut {
            "dormitory_o"
        } else if stop == .shuttlecockOut {
            "shuttlecock_o"
        } else if stop == .station {
            "station"
        } else if stop == .terminal {
            "terminal"
        } else if stop == .jungangStation {
            "jungang_stn"
        } else if stop == .shuttlecockIn {
            "shuttlecock_i"
        } else {
            "dormitory_o"
        }
        let dateFormatter = DateFormatter().then {
            $0.dateFormat = "yyyy-MM-dd"
        }
        ShuttleTimetableData.shared.isLoading.onNext(true)
        Task {
            var stop: ShuttleStopDialogQuery.Data.Shuttle.Stop?
            var merged: [StopTimetableDestination] = []
            for date in Self.sampleDates() {
                let response = try? await Network.shared.client.fetch(query: ShuttleStopDialogQuery(
                    date: dateFormatter.string(from: date),
                    stopID: stopID
                ))
                guard let fetched = response?.data?.shuttle.stops.first else { continue }
                stop = stop ?? fetched
                merged.append(contentsOf: fetched.timetable.destination)
            }
            publishStopInfo(stop, timetable: merged)
        }
    }

    /// The API only returns the schedule of the requested day, so sample one weekday and one weekend day.
    private static func sampleDates() -> [Foundation.Date] {
        let calendar = Calendar.current
        let today = Foundation.Date.now
        var weekday: Foundation.Date?
        var weekend: Foundation.Date?
        for offset in 0 ..< 7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let isWeekend = calendar.isDateInWeekend(day)
            if isWeekend, weekend == nil {
                weekend = day
            }
            if !isWeekend, weekday == nil {
                weekday = day
            }
        }
        return [weekday, weekend].compactMap(\.self)
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
        stopInfo.subscribe(onNext: { [weak self] stop in
            guard let self, let stop else { return }
            stopMapView.do {
                $0.removeAnnotations($0.annotations)
                $0.addAnnotation(MKPointAnnotation().with {
                    $0.coordinate = CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
                    $0.title = self.titleLabel.text
                })
                $0.camera = MKMapCamera(
                    lookingAtCenter: CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude),
                    fromDistance: 320,
                    pitch: 0,
                    heading: 0
                )
            }
        }).disposed(by: disposeBag)
        timetable.subscribe(onNext: { [weak self] items in
            self?.renderRows(items)
            self?.sheetPresentationController?.invalidateDetents()
        }).disposed(by: disposeBag)
    }

    private func renderRows(_ items: [StopTimetableDestination]) {
        rowsCard.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, destination) in destinations.enumerated() {
            if index > 0 {
                rowsCard.addArrangedSubview(HYUSheetView.separator())
            }
            let entries = items.filter { $0.destination == destination.apiKey }.flatMap(\.entries)
            rowsCard.addArrangedSubview(makeRow(
                title: destination.title,
                weekday: spanText(entries.filter(\.weekday)),
                weekend: spanText(entries.filter { !$0.weekday })
            ))
        }
    }

    private func spanText(_ entries: [StopTimetableEntry]) -> String {
        let times = entries.map(\.time).sorted()
        guard let first = times.first, let last = times.last else { return "—" }
        return "\(first.substring(from: 0, to: 4)) – \(last.substring(from: 0, to: 4))"
    }

    private func makeRow(title: String, weekday: String, weekend: String) -> UIView {
        let titleLabel = UILabel().then {
            $0.font = SettingsStyle.font(15, bold: true)
            $0.textColor = SettingsStyle.Color.text
            $0.text = title
        }
        return UIStackView(arrangedSubviews: [
            titleLabel,
            makeSpan(String(localized: "shuttle.stop.info.weekdays"), weekday),
            makeSpan(String(localized: "shuttle.stop.info.weekends"), weekend)
        ]).then {
            $0.axis = .vertical
            $0.alignment = .leading
            $0.spacing = 4
            $0.isLayoutMarginsRelativeArrangement = true
            $0.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        }
    }

    private func makeSpan(_ day: String, _ span: String) -> UIView {
        let dayLabel = UILabel().then {
            $0.font = SettingsStyle.font(14)
            $0.textColor = SettingsStyle.Color.secondaryText
            $0.text = day
            $0.setContentHuggingPriority(.required, for: .horizontal)
        }
        let spanLabel = UILabel().then {
            $0.font = SettingsStyle.monospacedDigitFont(14)
            $0.textColor = span == "—" ? SettingsStyle.Color.secondaryText : SettingsStyle.Color.text
            $0.text = span
        }
        return UIStackView(arrangedSubviews: [dayLabel, spanLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 8
        }
    }
}

extension ShuttleStopInfoVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "shuttleStopAnnotation")
        annotationView.markerTintColor = SettingsStyle.Color.accent
        annotationView.glyphImage = UIImage(systemName: "bus.fill")
        return annotationView
    }
}
