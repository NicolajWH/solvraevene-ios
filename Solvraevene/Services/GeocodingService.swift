import CoreLocation

actor GeocodingService {
    private let geocoder = CLGeocoder()
    private var cache: [String: (CLLocationCoordinate2D?, String?)] = [:]

    func geocode(location: String) async -> (CLLocationCoordinate2D?, String?) {
        if let cached = cache[location] {
            return cached
        }

        // Respect Apple's geocoding rate limit (~1 req/sec)
        try? await Task.sleep(for: .milliseconds(500))

        do {
            let placemarks = try await geocoder.geocodeAddressString(location)
            let coordinate = placemarks.first?.location?.coordinate
            let country = placemarks.first?.isoCountryCode
            let result = (coordinate, country)
            cache[location] = result
            return result
        } catch {
            cache[location] = (nil, nil)
            return (nil, nil)
        }
    }
}
