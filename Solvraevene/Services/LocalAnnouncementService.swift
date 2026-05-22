import Foundation

// Stores trip announcements locally in UserDefaults.
// Local data takes precedence over anything in trips.json.
struct LocalAnnouncementService {
    private static func key(for tripDate: String) -> String {
        "announcement_\(tripDate)"
    }

    static func load(for tripDate: String) -> TripAnnouncement? {
        guard let data = UserDefaults.standard.data(forKey: key(for: tripDate)) else { return nil }
        return try? JSONDecoder().decode(TripAnnouncement.self, from: data)
    }

    static func save(_ announcement: TripAnnouncement, for tripDate: String) {
        if let data = try? JSONEncoder().encode(announcement) {
            UserDefaults.standard.set(data, forKey: key(for: tripDate))
        }
    }
}
