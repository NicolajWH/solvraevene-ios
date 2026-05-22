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

            op.recordMatchedBlock = { _, result in
                if case .success(let record) = result {
                    records.append(record)
                }
            }
            op.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: records
                        .map { PackingItem(record: $0) }
                        .sorted { $0.sortOrder < $1.sortOrder })
                case .failure(let error):
                    continuation.resume(throwing: error)
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
            var savedRecord: CKRecord? = nil
            op.perRecordSaveBlock = { _, result in
                if case .success(let r) = result { savedRecord = r }
            }
            op.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: PackingItem(record: savedRecord ?? record))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            db.add(op)
        }
    }

    func deleteItem(_ item: PackingItem) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let op = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [item.id])
            op.modifyRecordsResultBlock = { result in
                switch result {
                case .success: continuation.resume()
                case .failure(let error): continuation.resume(throwing: error)
                }
            }
            db.add(op)
        }
    }
}
