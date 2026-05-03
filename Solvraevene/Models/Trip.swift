import Foundation
import CoreLocation

struct Trip: Identifiable, Codable {
    var id = UUID()
    let date: String
    let location: String
    let organizers: [String]

    var coordinate: CLLocationCoordinate2D? {
        switch location {
        case "Wolfsburg":
            return CLLocationCoordinate2D(latitude: 52.4227, longitude: 10.7865)
        case "Henne Kirkeby":
            return CLLocationCoordinate2D(latitude: 55.7300, longitude: 8.2200)
        default:
            return nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case date
        case location
        case organizers
    }
}
