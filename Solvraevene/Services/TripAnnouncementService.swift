import CloudKit

struct TripAnnouncement {
    var message: String
    var meetingPlace: String
    var departureDateTime: Date?
    var returnDateTime: Date?
    var recordID: CKRecord.ID?

    static let empty = TripAnnouncement(message: "", meetingPlace: "", departureDateTime: nil, returnDateTime: nil, recordID: nil)

    var isEmpty: Bool {
        message.isEmpty && meetingPlace.isEmpty && departureDateTime == nil && returnDateTime == nil
    }

    init(message: String, meetingPlace: String, departureDateTime: Date?, returnDateTime: Date?, recordID: CKRecord.ID?) {
        self.message = message
        self.meetingPlace = meetingPlace
        self.departureDateTime = departureDateTime
        self.returnDateTime = returnDateTime
        self.recordID = recordID
    }

    init(record: CKRecord) {
        self.message = record["message"] as? String ?? ""
        self.meetingPlace = record["meetingPlace"] as? String ?? ""
        // "departureDateTime" was accidentally created as STRING in CloudKit — use "departureAt" (DATE) instead
        self.departureDateTime = record["departureAt"] as? Date
        self.returnDateTime = record["returnDateTime"] as? Date
        self.recordID = record.recordID
    }
}

actor TripAnnouncementService {
    static let shared = TripAnnouncementService()

    private let db = CKContainer.default().publicCloudDatabase

    func fetch(for tripDate: String) async throws -> TripAnnouncement? {
        try await withCheckedThrowingContinuation { continuation in
            let pred = NSPredicate(format: "tripDate == %@", tripDate)
            let query = CKQuery(recordType: "TripAnnouncement", predicate: pred)
            let op = CKQueryOperation(query: query)
            op.resultsLimit = 1
            var found: CKRecord? = nil

            op.recordFetchedBlock = { record in
                if found == nil { found = record }
            }
            op.queryCompletionBlock = { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: found.map { TripAnnouncement(record: $0) })
                }
            }
            db.add(op)
        }
    }

    func save(_ announcement: TripAnnouncement, for tripDate: String) async throws -> TripAnnouncement {
        let record: CKRecord
        if let id = announcement.recordID {
            record = try await fetchRecord(id: id)
        } else {
            record = CKRecord(recordType: "TripAnnouncement")
            record["tripDate"] = tripDate
        }
        record["message"] = announcement.message
        record["meetingPlace"] = announcement.meetingPlace
        record["departureAt"] = announcement.departureDateTime as CKRecordValue?
        record["returnDateTime"] = announcement.returnDateTime as CKRecordValue?

        return try await withCheckedThrowingContinuation { continuation in
            let op = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
            op.modifyRecordsCompletionBlock = { saved, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: TripAnnouncement(record: saved?.first ?? record))
                }
            }
            db.add(op)
        }
    }

    private func fetchRecord(id: CKRecord.ID) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            let op = CKFetchRecordsOperation(recordIDs: [id])
            op.fetchRecordsCompletionBlock = { records, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let record = records?[id] {
                    continuation.resume(returning: record)
                } else {
                    continuation.resume(throwing: CKError(.unknownItem))
                }
            }
            db.add(op)
        }
    }
}
