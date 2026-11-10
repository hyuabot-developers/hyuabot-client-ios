//
//  BusStopInfoVC.swift
//  hyuabot
//

import Api
import MapKit
import RxSwift
import UIKit

class BusStopInfoVC: UIViewController {
    private let input: [BusRouteStopInput]
    private let disposeBag = DisposeBag()
    private let routeStops = BehaviorSubject<[BusStopDialogQuery.Data.Bus]>(value: [])
    private let stopMapView = MKMapView().then {
        $0.isScrollEnabled = false
        $0.isZoomEnabled = false
        $0.isRotateEnabled = false
        $0.isPitchEnabled = false
        $0.isUserInteractionEnabled = false
        $0.layer.cornerRadius = 16
        $0.clipsToBounds = true
        $0.accessibilityIdentifier = "bus.stop.map"
    }
    private let stopNameLabel = UILabel().then {
        $0.font = SettingsStyle.font(20, bold: true)
        $0.textColor = SettingsStyle.Color.text
        $0.numberOfLines = 0
        $0.accessibilityIdentifier = "bus.stop.name"
    }
    private lazy var firstLastTableView = UITableView(frame: .zero, style: .plain).then {
        $0.dataSource = self
        $0.rowHeight = UITableView.automaticDimension
        $0.estimatedRowHeight = 140
        $0.separatorStyle = .none
        $0.backgroundColor = .clear
        $0.register(BusFirstLastCellView.self, forCellReuseIdentifier: BusFirstLastCellView.reuseIdentifier)
        $0.accessibilityIdentifier = "bus.stop.timetable"
    }

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
        observeSubjects()
        fetchStopInfo()
    }

    private func setupUI() {
        view.backgroundColor = SettingsStyle.Color.busSheetBackground
        let title = UILabel()
        title.accessibilityIdentifier = "bus.stop.title"
        title.attributedText = SettingsStyle.attributedText(
            String(localized: "bus.stop.title"), font: SettingsStyle.font(20, bold: true),
            color: SettingsStyle.Color.text, lineHeight: 26
        )
        view.addSubview(title)
        view.addSubview(firstLastTableView)
        title.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(11)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(52)
        }
        firstLastTableView.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(3)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        configureMapHeader()
    }

    private func configureMapHeader() {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 268))
        let sectionTitle = UILabel()
        sectionTitle.text = String(localized: "bus.stop.route_first_last")
        sectionTitle.font = SettingsStyle.font(14, bold: true)
        sectionTitle.textColor = SettingsStyle.Color.secondaryText
        header.addSubview(stopMapView)
        header.addSubview(stopNameLabel)
        header.addSubview(sectionTitle)
        stopMapView.delegate = self
        stopMapView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(184)
        }
        stopNameLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(stopMapView.snp.bottom).offset(12)
        }
        sectionTitle.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(stopNameLabel.snp.bottom).offset(12)
            make.bottom.equalToSuperview().inset(8)
        }
        firstLastTableView.tableHeaderView = header
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let header = firstLastTableView.tableHeaderView else { return }
        let width = firstLastTableView.bounds.width
        guard width > 0 else { return }
        let size = header.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel
        )
        if header.frame.size != size {
            header.frame.size = size
            firstLastTableView.tableHeaderView = header
        }
    }

    private func fetchStopInfo() {
        Task {
            let response = try? await Network.shared.client.fetch(query: BusStopDialogQuery(routeStops: input))
            if let data = response?.data {
                routeStops.onNext(data.bus.sorted(by: { $0.route.name < $1.route.name }))
            }
        }
    }

    private func observeSubjects() {
        routeStops.observe(on: MainScheduler.instance).subscribe(onNext: { [weak self] stops in
            guard let self, let stop = stops.first?.stop else { return }
            stopNameLabel.setKoreanTranslatedText(stop.name)
            stopMapView.removeAnnotations(stopMapView.annotations)
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
            annotation.title = stop.name
            stopMapView.addAnnotation(annotation)
            Task { annotation.title = await KoreanTextTranslator.shared.translate(stop.name) }
            stopMapView.camera = MKMapCamera(lookingAtCenter: annotation.coordinate, fromDistance: 750, pitch: 0, heading: 0)
            firstLastTableView.reloadData()
            view.setNeedsLayout()
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

extension BusStopInfoVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (try? routeStops.value().count) ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let stops = try? routeStops.value(),
              let cell = tableView.dequeueReusableCell(withIdentifier: BusFirstLastCellView.reuseIdentifier,
                                                       for: indexPath) as? BusFirstLastCellView else { return UITableViewCell() }
        cell.setupUI(item: stops[indexPath.row])
        return cell
    }
}
