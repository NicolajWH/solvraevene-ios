import CloudKit

struct PackingItem: Identifiable {
    let id: CKRecord.ID
    var text: String
    var sortOrder: Int

    init(record: CKRecord) {
        self.id = record.recordID
        self.text = record["text"] as? String ?? ""
        self.sortOrder = (record["sortOrder"] as? NSNumber)?.intValue ?? 0
    }
}

actor PackingListService {
    static let shared = PackingListService()

    private let db = CKContainer(identifier: "iCloud.dk.haugaard.solvraevene").publicCloudDatabase

    // MARK: - Items

    func fetchItems(for tripDate: String) async throws -> [PackingItem] {
        let pred = NSPredicate(format: "tripDate == %@", tripDate)
        let query = CKQuery(recordType: "PackingItem", predicate: pred)
        let result = try await db.records(matching: query)
        return result.matchResults
            .compactMap { try? $0.1.get() }
            .map { PackingItem(record: $0) }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func addItem(tripDate: String, text: String, order: Int) async throws -> PackingItem {
        let record = CKRecord(recordType: "PackingItem")
        record["tripDate"] = tripDate as CKRecordValue
        record["text"] = text as CKRecordValue
        record["sortOrder"] = NSNumber(value: order)
        let saved = try await db.save(record)
        return PackingItem(record: saved)
    }

    func deleteItem(_ item: PackingItem) async throws {
        try await db.deleteRecord(withID: item.id)
    }

    // MARK: - Subscriptions

    func subscribeIfNeeded(for tripDate: String, tripTitle: String) async {
        let subKey = "ck_subscribed_\(tripDate)"
        guard !UserDefaults.standard.bool(forKey: subKey) else { return }

        let pred = NSPredicate(format: "tripDate == %@", tripDate)
        let sub = CKQuerySubscription(
            recordType: "PackingItem",
            predicate: pred,
            subscriptionID: "packing-\(tripDate)",
            options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate]
        )
        let info = CKSubscription.NotificationInfo()
        info.title = "Huskeliste opdateret"
        info.alertBody = "Huskelisten til \(tripTitle) er blevet ændret"
        info.soundName = "default"
        info.shouldBadge = false
        sub.notificationInfo = info

        do {
            _ = try await db.save(sub)
            UserDefaults.standard.set(true, forKey: subKey)
        } catch {
            // Mark as done to avoid hammering the server on repeated opens
            UserDefaults.standard.set(true, forKey: subKey)
        }
    }
}
