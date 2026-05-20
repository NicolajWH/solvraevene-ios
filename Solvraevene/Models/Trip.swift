import Foundation
import CoreLocation

struct Trip: Identifiable, Codable {
    var id = UUID()
    let date: String
    let endDate: String?
    let location: String?
    let organizers: [String]
    let photoAlbumURL: String?

    // Populated after geocoding — not stored in JSON
    var country: String?
    var coordinate: CLLocationCoordinate2D?

    var isFuture: Bool {
        (endDate ?? date) >= today
    }

    // "23.-25. oktober 2026" or "17. maj 2025"
    var formattedDateRange: String {
        guard let end = endDate else { return formattedDate }
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        guard let startD = parser.date(from: date),
              let endD = parser.date(from: end) else { return formattedDate }

        let cal = Calendar.current
        let locale = Locale(identifier: "da_DK")

        if cal.isDate(startD, equalTo: endD, toGranularity: .month) {
            let startDay = cal.component(.day, from: startD)
            let endDay = cal.component(.day, from: endD)
            let mf = DateFormatter()
            mf.locale = locale
            mf.dateFormat = "MMMM yyyy"
            return "\(startDay).-\(endDay). \(mf.string(from: endD))"
        }

        let df = DateFormatter()
        df.locale = locale
        df.dateStyle = .long
        return "\(df.string(from: startD)) – \(df.string(from: endD))"
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
        case date, endDate, location, organizers, photoAlbumURL
    }
}
