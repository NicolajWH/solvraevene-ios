import CoreLocation

actor GeocodingService {
    private let geocoder = CLGeocoder()
    private var cache: [String: CachedResult] = [:]

    private struct CachedResult: Codable {
        let lat: Double?
        let lon: Double?
        let country: String?

        var coordinate: CLLocationCoordinate2D? {
            guard let lat, let lon else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }

    private static let persistKey = "geocode_cache_v2"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.persistKey),
           let stored = try? JSONDecoder().decode([String: CachedResult].self, from: data) {
            cache = stored
        }
    }

    func geocode(location: String) async -> (CLLocationCoordinate2D?, String?) {
        if let cached = cache[location] {
            return (cached.coordinate, cached.country)
        }

        // Respect Apple's geocoding rate limit (~1 req/sec)
        try? await Task.sleep(for: .milliseconds(500))

        do {
            let placemarks = try await geocoder.geocodeAddressString(location)
            let coordinate = placemarks.first?.location?.coordinate
            let country = placemarks.first?.isoCountryCode
            let entry = CachedResult(lat: coordinate?.latitude, lon: coordinate?.longitude, country: country)
            cache[location] = entry
            saveCache()
            return (coordinate, country)
        } catch {
            return (nil, nil)
        }
    }

    private func saveCache() {
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: Self.persistKey)
        }
    }
}
