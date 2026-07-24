//
//  ShuttleInitialStopResolver.swift
//  hyuabot
//

struct ShuttleGeoCoordinate: Equatable {
    let latitude: Double
    let longitude: Double
}

struct ShuttleInitialStopRuleCandidate {
    let sequence: Int
    let stopName: String
    let priority: Int
    let polygon: [ShuttleGeoCoordinate]
}

enum ShuttleInitialStopResolver {
    static func resolve(
        latitude: Double,
        longitude: Double,
        rules: [ShuttleInitialStopRuleCandidate]
    ) -> String? {
        guard latitude.isFinite, longitude.isFinite else { return nil }
        let location = ShuttleGeoCoordinate(latitude: latitude, longitude: longitude)
        return rules
            .sorted {
                $0.priority == $1.priority ? $0.sequence < $1.sequence : $0.priority > $1.priority
            }
            .first { contains(location, polygon: $0.polygon) }?
            .stopName
    }

    static func contains(
        _ location: ShuttleGeoCoordinate,
        polygon: [ShuttleGeoCoordinate]
    ) -> Bool {
        guard polygon.count >= 3,
              polygon.allSatisfy({ $0.latitude.isFinite && $0.longitude.isFinite })
        else { return false }

        var inside = false
        var previous = polygon[polygon.count - 1]
        for current in polygon {
            if isOnSegment(location, start: previous, end: current) {
                return true
            }
            let crossesLatitude =
                (current.latitude > location.latitude) != (previous.latitude > location.latitude)
            if crossesLatitude {
                let intersectionLongitude =
                    (previous.longitude - current.longitude) *
                    (location.latitude - current.latitude) /
                    (previous.latitude - current.latitude) +
                    current.longitude
                if location.longitude < intersectionLongitude {
                    inside.toggle()
                }
            }
            previous = current
        }
        return inside
    }

    private static func isOnSegment(
        _ point: ShuttleGeoCoordinate,
        start: ShuttleGeoCoordinate,
        end: ShuttleGeoCoordinate
    ) -> Bool {
        let cross =
            (point.latitude - start.latitude) * (end.longitude - start.longitude) -
            (point.longitude - start.longitude) * (end.latitude - start.latitude)
        guard abs(cross) <= coordinateEpsilon else { return false }
        return point.latitude >= min(start.latitude, end.latitude) - coordinateEpsilon &&
            point.latitude <= max(start.latitude, end.latitude) + coordinateEpsilon &&
            point.longitude >= min(start.longitude, end.longitude) - coordinateEpsilon &&
            point.longitude <= max(start.longitude, end.longitude) + coordinateEpsilon
    }

    private static let coordinateEpsilon = 1e-10
}
