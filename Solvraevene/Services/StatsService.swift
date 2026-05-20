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

    /// Number of trips each pair of organizers has done together.
    /// Key is a sorted tuple (a < b). Diagonal pairs (a == b) are excluded.
    static func pairCounts(from trips: [Trip]) -> [String: [String: Int]] {
        var matrix: [String: [String: Int]] = [:]
        for trip in trips {
            let orgs = trip.organizers
            guard orgs.count >= 2 else { continue }
            for i in 0..<orgs.count {
                for j in (i + 1)..<orgs.count {
                    let a = orgs[i], b = orgs[j]
                    matrix[a, default: [:]][b, default: 0] += 1
                    matrix[b, default: [:]][a, default: 0] += 1
                }
            }
        }
        return matrix
    }
}
