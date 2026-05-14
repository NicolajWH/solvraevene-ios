import Foundation
import CoreLocation

struct Trip: Identifiable, Codable {
    var id = UUID()
    let date: String
    let location: String
    let country: String?
    let lat: Double?
    let lng: Double?
    let organizers: [String]

    var coordinate: CLLocationCoordinate2D? {
        guard let lat, let lng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var isFuture: Bool {
        date >= today
    }

    private var today: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    enum CodingKeys: String, CodingKey {
        case date, location, country, lat, lng, organizers
    }
}
