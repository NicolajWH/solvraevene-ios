import Foundation

enum DataServiceError: LocalizedError {
    case bundleNotFound
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .bundleNotFound:
            return "trips.json mangler i app-bundlen"
        case .decodingFailed(let e):
            return "Ugyldig JSON: \(e.localizedDescription)"
        }
    }
}

class DataService {
    private static let remoteURL = URL(string: "https://raw.githubusercontent.com/nicolajwh/solvraevene-ios/main/Solvraevene/Resources/trips.json")!

    static func loadTrips() async throws -> [Trip] {
        // Try remote; fall back to bundled on any failure
        if let data = try? await URLSession.shared.data(from: remoteURL).0,
           let trips = try? decode(data) {
            return trips
        }
        return try loadBundled()
    }

    private static func loadBundled() throws -> [Trip] {
        guard let url = Bundle.main.url(forResource: "trips", withExtension: "json") else {
            throw DataServiceError.bundleNotFound
        }
        do {
            return try decode(Data(contentsOf: url))
        } catch let e as DataServiceError {
            throw e
        } catch {
            throw DataServiceError.decodingFailed(error)
        }
    }

    private static func decode(_ data: Data) throws -> [Trip] {
        do {
            let trips = try JSONDecoder().decode([Trip].self, from: data)
            return trips.sorted { $0.date > $1.date }
        } catch {
            throw DataServiceError.decodingFailed(error)
        }
    }
}
