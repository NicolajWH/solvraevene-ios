import Foundation
import CoreLocation

struct Trip: Identifiable, Codable {
    var id = UUID()
    let date: String
    let location: String?
    let organizers: [String]
    let photoAlbumURL: String?

    // Populated after geocoding — not stored in JSON
    var country: String?
    var coordinate: CLLocationCoordinate2D?

    var isFuture: Bool {
        date >= today
    }

    var formattedDate: String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        let output = DateFormatter()
        output.dateStyle = .long
        output.locale = Locale(identifier: "da_DK")
        guard let d = input.date(from: date) else { return date }
        return output.string(from: d)
    }

    private var today: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    enum CodingKeys: String, CodingKey {
        case date, location, organizers, photoAlbumURL
    }
}
