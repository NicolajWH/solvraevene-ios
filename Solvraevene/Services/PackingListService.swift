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

    private let db = CKContainer.default().publicCloudDatabase

    func fetchItems(for tripDate: String) async throws -> [PackingItem] {
        try await withCheckedThrowingContinuation { continuation in
            let pred = NSPredicate(format: "tripDate == %@", tripDate)
            let query = CKQuery(recordType: "PackingItem", predicate: pred)
            let op = CKQueryOperation(query: query)
            var records: [CKRecord] = []

            op.recordFetchedBlock = { record in
                records.append(record)
            }
            op.queryCompletionBlock = { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: records
                        .map { PackingItem(record: $0) }
                        .sorted { $0.sortOrder < $1.sortOrder })
                }
            }
            db.add(op)
        }
    }

    func addItem(tripDate: String, text: String, order: Int) async throws -> PackingItem {
        let record = CKRecord(recordType: "PackingItem")
        record["tripDate"] = tripDate as CKRecordValue
        record["text"] = text as CKRecordValue
        record["sortOrder"] = NSNumber(value: order)
        return try await withCheckedThrowingContinuation { continuation in
            let op = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
            op.modifyRecordsCompletionBlock = { saved, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: PackingItem(record: saved?.first ?? record))
                }
            }
            db.add(op)
        }
    }

    func deleteItem(_ item: PackingItem) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let op = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [item.id])
            op.modifyRecordsCompletionBlock = { _, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
            db.add(op)
        }
    }
}
