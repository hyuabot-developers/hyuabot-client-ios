import MapKit

extension MKMapView {
    var northWestCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.region.center.latitude + self.region.span.latitudeDelta / 2, longitude: self.region.center.longitude - self.region.span.longitudeDelta / 2)
    }
    
    var northEastCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.region.center.latitude + self.region.span.latitudeDelta / 2, longitude: self.region.center.longitude + self.region.span.longitudeDelta / 2)
    }
    
    var southWestCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.region.center.latitude - self.region.span.latitudeDelta / 2, longitude: self.region.center.longitude - self.region.span.longitudeDelta / 2)
    }
    
    var southEastCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.region.center.latitude - self.region.span.latitudeDelta / 2, longitude: self.region.center.longitude + self.region.span.longitudeDelta / 2)
    }
}
