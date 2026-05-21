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
        let pred = NSPredicate(format: "tripDate == %@", tripDate)
        let query = CKQuery(recordType: "TripAnnouncement", predicate: pred)
        let result = try await db.records(matching: query, resultsLimit: 1)
        guard let record = try? result.matchResults.first?.1.get() else { return nil }
        return TripAnnouncement(record: record)
    }

    func save(_ announcement: TripAnnouncement, for tripDate: String) async throws -> TripAnnouncement {
        let record: CKRecord
        if let id = announcement.recordID {
            record = try await db.record(for: id)
        } else {
            record = CKRecord(recordType: "TripAnnouncement")
            record["tripDate"] = tripDate
        }
        record["message"] = announcement.message
        record["meetingPlace"] = announcement.meetingPlace
        record["departureAt"] = announcement.departureDateTime as CKRecordValue?
        record["returnDateTime"] = announcement.returnDateTime as CKRecordValue?
        let saved = try await db.save(record)
        return TripAnnouncement(record: saved)
    }

    func subscribeIfNeeded(for tripDate: String, tripTitle: String) async {
        let subKey = "ck_announcement_sub_\(tripDate)"
        guard !UserDefaults.standard.bool(forKey: subKey) else { return }

        let pred = NSPredicate(format: "tripDate == %@", tripDate)
        let sub = CKQuerySubscription(
            recordType: "TripAnnouncement",
            predicate: pred,
            subscriptionID: "announcement-\(tripDate)",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        let info = CKSubscription.NotificationInfo()
        info.title = "Besked fra formanden"
        info.alertBody = "Formanden har opdateret info om turen til \(tripTitle)"
        info.soundName = "default"
        info.shouldBadge = false
        sub.notificationInfo = info

        do {
            _ = try await db.save(sub)
            UserDefaults.standard.set(true, forKey: subKey)
        } catch let error as CKError where error.code == .serverRejectedRequest {
            UserDefaults.standard.set(true, forKey: subKey)
        } catch {}
    }
}
