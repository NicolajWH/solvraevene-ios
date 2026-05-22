import Foundation

struct PackingItem: Identifiable, Codable {
    var id = UUID()
    var text: String
    var sortOrder: Int
}

// Local storage only — no CloudKit, no network required.
// Items are stored per trip date in UserDefaults as JSON.
struct PackingListService {
    private static func key(for tripDate: String) -> String { "packing_items_\(tripDate)" }

    static func loadItems(for tripDate: String) -> [PackingItem] {
        guard let data = UserDefaults.standard.data(forKey: key(for: tripDate)),
              let items = try? JSONDecoder().decode([PackingItem].self, from: data) else {
            return []
        }
        return items.sorted { $0.sortOrder < $1.sortOrder }
    }

    static func saveItems(_ items: [PackingItem], for tripDate: String) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key(for: tripDate))
        }
    }
}
