import Foundation

class DataService {
    static func loadTrips() -> [Trip] {
        guard let url = Bundle.main.url(forResource: "trips", withExtension: "json") else {
            print("❌ trips.json not found")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let trips = try JSONDecoder().decode([Trip].self, from: data)
            return trips.sorted { $0.date > $1.date }
        } catch {
            print("❌ Failed to load trips:", error)
            return []
        }
    }
}
