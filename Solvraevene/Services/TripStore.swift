import Foundation
import Observation

@MainActor
@Observable
class TripStore {
    var trips: [Trip] = []
    var isLoading = false
    var errorMessage: String?

    private let geocodingService = GeocodingService()

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            trips = try await DataService.loadTrips()
        } catch {
            errorMessage = "Kunne ikke hente turdata: \(error.localizedDescription)"
            isLoading = false
            return
        }

        isLoading = false
        await geocodeTrips()
    }

    private func geocodeTrips() async {
        for i in trips.indices {
            guard let location = trips[i].location else { continue }
            let (coordinate, country) = await geocodingService.geocode(location: location)
            trips[i].coordinate = coordinate
            trips[i].country = country
        }
    }
}
