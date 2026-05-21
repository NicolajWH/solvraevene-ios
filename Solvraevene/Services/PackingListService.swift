import CloudKit

struct PackingItem: Identifiable {
    let id: CKRecord.ID
    var text: String
    var order: Int

    init(record: CKRecord) {
        self.id = record.recordID
        self.text = record["text"] as? String ?? ""
        self.order = record["order"] as? Int ?? 0
    }
}

actor PackingListService {
    static let shared = PackingListService()

    private let db = CKContainer(identifier: "iCloud.dk.haugaard.solvraevene").publicCloudDatabase

    func fetchItems(for tripDate: String) async throws -> [PackingItem] {
        let pred = NSPredicate(format: "tripDate == %@", tripDate)
        let query = CKQuery(recordType: "PackingItem", predicate: pred)
        query.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        let result = try await db.records(matching: query)
        return result.matchResults.compactMap { try? $0.1.get() }.map { PackingItem(record: $0) }
    }

    func addItem(tripDate: String, text: String, order: Int) async throws -> PackingItem {
        let record = CKRecord(recordType: "PackingItem")
        record["tripDate"] = tripDate
        record["text"] = text
        record["order"] = order
        let saved = try await db.save(record)
        return PackingItem(record: saved)
    }

    func updateItem(_ item: PackingItem, text: String) async throws {
        let record = try await db.record(for: item.id)
        record["text"] = text
        _ = try await db.save(record)
    }

    func deleteItem(_ item: PackingItem) async throws {
        try await db.deleteRecord(withID: item.id)
    }
}
