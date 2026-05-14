import Foundation

class StatsService {

    static func organizerCounts(from trips: [Trip]) -> [(name: String, initials: String, count: Int)] {
        var counts: [String: Int] = [:]
        for trip in trips {
            for initials in trip.organizers {
                counts[initials, default: 0] += 1
            }
        }
        return counts
            .map { (name: Organizer.fullName(for: $0.key), initials: $0.key, count: $0.value) }
            .sorted {
                if $0.count == $1.count { return $0.name < $1.name }
                return $0.count > $1.count
            }
    }

    static func countryCounts(from trips: [Trip]) -> [(country: String, count: Int)] {
        var counts: [String: Int] = [:]
        for trip in trips {
            guard let country = trip.country else { continue }
            counts[country, default: 0] += 1
        }
        return counts
            .map { (country: $0.key, count: $0.value) }
            .sorted {
                if $0.count == $1.count { return $0.country < $1.country }
                return $0.count > $1.count
            }
    }
}
