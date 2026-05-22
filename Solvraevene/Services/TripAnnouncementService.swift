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

            op.recordMatchedBlock = { _, result in
                if case .success(let record) = result, found == nil { found = record }
            }
            op.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: found.map { TripAnnouncement(record: $0) })
                case .failure(let error):
                    continuation.resume(throwing: error)
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
            var savedRecord: CKRecord? = nil
            op.perRecordSaveBlock = { _, result in
                if case .success(let r) = result { savedRecord = r }
            }
            op.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: TripAnnouncement(record: savedRecord ?? record))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            db.add(op)
        }
    }

    private func fetchRecord(id: CKRecord.ID) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            let op = CKFetchRecordsOperation(recordIDs: [id])
            var fetchedRecord: CKRecord? = nil
            op.perRecordResultBlock = { _, result in
                if case .success(let record) = result { fetchedRecord = record }
            }
            op.fetchRecordsResultBlock = { result in
                switch result {
                case .success:
                    if let record = fetchedRecord {
                        continuation.resume(returning: record)
                    } else {
                        continuation.resume(throwing: CKError(.unknownItem))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            db.add(op)
        }
    }
}
