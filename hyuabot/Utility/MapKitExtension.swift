import MapKit

extension MKMapView {
    var northWestCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: region.center.latitude + region.span.latitudeDelta / 2,
            longitude: region.center.longitude - region.span.longitudeDelta / 2
        )
    }

    var northEastCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: region.center.latitude + region.span.latitudeDelta / 2,
            longitude: region.center.longitude + region.span.longitudeDelta / 2
        )
    }

    var southWestCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: region.center.latitude - region.span.latitudeDelta / 2,
            longitude: region.center.longitude - region.span.longitudeDelta / 2
        )
    }

    var southEastCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: region.center.latitude - region.span.latitudeDelta / 2,
            longitude: region.center.longitude + region.span.longitudeDelta / 2
        )
    }
}
