import Foundation

class StatsService {
    static func organizerCounts(from trips: [Trip]) -> [(name: String, count: Int)] {
        var counts: [String: Int] = [:]

        for trip in trips {
            for organizer in trip.organizers {
                counts[organizer, default: 0] += 1
            }
        }

        return counts
            .map { (name: $0.key, count: $0.value) }
            .sorted {
                if $0.count == $1.count {
                    return $0.name < $1.name
                }
                return $0.count > $1.count
            }
    }
}
