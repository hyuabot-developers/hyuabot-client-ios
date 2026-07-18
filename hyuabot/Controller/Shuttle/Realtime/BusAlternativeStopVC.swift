import MapKit
import SnapKit
import Then
import UIKit

class BusAlternativeStopVC: UIViewController {
    private static let routeCache = BusAlternativeRouteCache()

    private let shuttleStop: StopPoint
    private let busStop: StopPoint
    private let routeCacheKey: BusAlternativeRouteCache.Key
    private var fallbackPolyline: MKPolyline?

    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 20, weight: .bold)
        $0.textColor = .white
        $0.backgroundColor = .hanyangBlue
        $0.textAlignment = .center
        $0.text = String(localized: "coach.shuttle.footer.title")
    }

    private let mapView = MKMapView().then {
        $0.isZoomEnabled = true
        $0.isScrollEnabled = true
        $0.isPitchEnabled = false
        $0.showsCompass = true
        $0.showsUserLocation = true
    }

    init(
        shuttleStopName: String,
        shuttleStopLatitude: Double,
        shuttleStopLongitude: Double,
        busStopName: String,
        busStopLatitude: Double,
        busStopLongitude: Double
    ) {
        let shuttleCoordinate = CLLocationCoordinate2D(latitude: shuttleStopLatitude, longitude: shuttleStopLongitude)
        let busCoordinate = CLLocationCoordinate2D(latitude: busStopLatitude, longitude: busStopLongitude)
        shuttleStop = StopPoint(
            name: shuttleStopName,
            subtitle: String(localized: "shuttle.bus.alternative.shuttle.stop"),
            coordinate: shuttleCoordinate,
            kind: .shuttle
        )
        busStop = StopPoint(
            name: busStopName,
            subtitle: String(localized: "shuttle.bus.alternative.bus.stop"),
            coordinate: busCoordinate,
            kind: .bus
        )
        routeCacheKey = BusAlternativeRouteCache.Key(source: shuttleCoordinate, destination: busCoordinate)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        renderStops()
    }

    private func setupUI() {
        view.backgroundColor = .hanyangBlue
        view.addSubview(titleLabel)
        view.addSubview(mapView)
        mapView.delegate = self

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        mapView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func renderStops() {
        mapView.addAnnotations([shuttleStop, busStop])
        Task {
            shuttleStop.title = await KoreanTextTranslator.shared.translate(shuttleStop.title ?? "")
            busStop.title = await KoreanTextTranslator.shared.translate(busStop.title ?? "")
        }
        fitMapToStopCoordinates()
        drawWalkingRoute()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            mapView.selectAnnotation(shuttleStop, animated: true)
            mapView.selectAnnotation(busStop, animated: true)
        }
    }

    private func drawWalkingRoute() {
        if let cachedCoordinates = Self.routeCache.coordinates(for: routeCacheKey) {
            drawRoute(with: cachedCoordinates)
            return
        }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: shuttleStop.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: busStop.coordinate))
        request.transportType = .walking
        request.requestsAlternateRoutes = false

        MKDirections(request: request).calculate { [weak self] response, _ in
            guard let route = response?.routes.first else {
                DispatchQueue.main.async { [weak self] in
                    self?.drawFallbackRoute()
                }
                return
            }
            let coordinates = route.polyline.coordinates
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                Self.routeCache.set(coordinates, for: routeCacheKey)
                drawRoute(with: coordinates)
            }
        }
    }

    private func drawRoute(with coordinates: [CLLocationCoordinate2D]) {
        guard coordinates.count >= 2 else {
            drawFallbackRoute()
            return
        }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
        mapView.setVisibleMapRect(
            polyline.boundingMapRect,
            edgePadding: UIEdgeInsets(top: 90, left: 40, bottom: 70, right: 40),
            animated: false
        )
    }

    private func drawFallbackRoute() {
        let polyline = MKPolyline(coordinates: [shuttleStop.coordinate, busStop.coordinate], count: 2)
        fallbackPolyline = polyline
        mapView.addOverlay(polyline)
        fitMapToStopCoordinates()
    }

    private func fitMapToStopCoordinates() {
        let shuttlePoint = MKMapPoint(shuttleStop.coordinate)
        let busPoint = MKMapPoint(busStop.coordinate)
        let minX = min(shuttlePoint.x, busPoint.x)
        let minY = min(shuttlePoint.y, busPoint.y)
        let width = max(abs(shuttlePoint.x - busPoint.x), 200)
        let height = max(abs(shuttlePoint.y - busPoint.y), 200)
        mapView.setVisibleMapRect(
            MKMapRect(x: minX, y: minY, width: width, height: height),
            edgePadding: UIEdgeInsets(top: 90, left: 40, bottom: 70, right: 40),
            animated: false
        )
    }
}

extension BusAlternativeStopVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        guard let stopPoint = annotation as? StopPoint else { return nil }
        let reuseIdentifier = "busAlternativeStopAnnotation"
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        annotationView.annotation = annotation
        annotationView.canShowCallout = true
        annotationView.markerTintColor = stopPoint.kind == .shuttle ? .hanyangBlue : .busGreen
        annotationView.glyphImage = UIImage(systemName: stopPoint.kind == .shuttle ? "bus.doubledecker.fill" : "bus.fill")
        return annotationView
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = .hanyangBlue
        renderer.lineWidth = 5
        renderer.lineJoin = .round
        renderer.lineCap = .round
        if polyline === fallbackPolyline {
            renderer.strokeColor = .secondaryLabel
            renderer.lineDashPattern = [8, 6]
        }
        return renderer
    }
}

private final class StopPoint: NSObject, MKAnnotation {
    enum Kind {
        case shuttle
        case bus
    }

    var title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let kind: Kind

    init(name: String, subtitle: String, coordinate: CLLocationCoordinate2D, kind: Kind) {
        title = name
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.kind = kind
    }
}

private final class BusAlternativeRouteCache {
    struct Key: Hashable {
        let sourceLatitude: Int
        let sourceLongitude: Int
        let destinationLatitude: Int
        let destinationLongitude: Int

        init(source: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) {
            sourceLatitude = Self.normalize(source.latitude)
            sourceLongitude = Self.normalize(source.longitude)
            destinationLatitude = Self.normalize(destination.latitude)
            destinationLongitude = Self.normalize(destination.longitude)
        }

        private static func normalize(_ value: CLLocationDegrees) -> Int {
            Int((value * 1_000_000).rounded())
        }

        var rawValue: String {
            "\(sourceLatitude),\(sourceLongitude),\(destinationLatitude),\(destinationLongitude)"
        }
    }

    private let lock = NSLock()
    private let cacheURL: URL?
    private var storage: [String: [CachedCoordinate]]

    init() {
        cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("bus-alternative-routes.json")
        storage = Self.loadStorage(from: cacheURL)
    }

    func coordinates(for key: Key) -> [CLLocationCoordinate2D]? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key.rawValue]?.map(\.coordinate)
    }

    func set(_ coordinates: [CLLocationCoordinate2D], for key: Key) {
        let cachedCoordinates = coordinates.map(CachedCoordinate.init)
        let snapshot: [String: [CachedCoordinate]]
        lock.lock()
        storage[key.rawValue] = cachedCoordinates
        snapshot = storage
        lock.unlock()

        save(snapshot)
    }

    private static func loadStorage(from url: URL?) -> [String: [CachedCoordinate]] {
        guard let url, let data = try? Data(contentsOf: url) else { return [:] }
        return (try? JSONDecoder().decode([String: [CachedCoordinate]].self, from: data)) ?? [:]
    }

    private func save(_ storage: [String: [CachedCoordinate]]) {
        guard let cacheURL else { return }
        DispatchQueue.global(qos: .utility).async {
            guard let data = try? JSONEncoder().encode(storage) else { return }
            try? data.write(to: cacheURL, options: .atomic)
        }
    }

    private struct CachedCoordinate: Codable {
        let latitude: CLLocationDegrees
        let longitude: CLLocationDegrees

        init(_ coordinate: CLLocationCoordinate2D) {
            latitude = coordinate.latitude
            longitude = coordinate.longitude
        }

        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}

private extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coordinates = Array(repeating: CLLocationCoordinate2D(), count: pointCount)
        getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
        return coordinates
    }
}
