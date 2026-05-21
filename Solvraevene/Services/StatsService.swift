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

    static func monthCounts(from trips: [Trip]) -> [(month: Int, label: String, count: Int)] {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let monthName = DateFormatter()
        monthName.dateFormat = "MMM"
        monthName.locale = Locale(identifier: "da_DK")

        var counts: [Int: Int] = [:]
        for trip in trips {
            guard let d = f.date(from: trip.date) else { continue }
            let m = Calendar.current.component(.month, from: d)
            counts[m, default: 0] += 1
        }
        return counts
            .map { month, count -> (month: Int, label: String, count: Int) in
                let d = Calendar.current.date(from: DateComponents(month: month))!
                return (month: month, label: monthName.string(from: d).capitalized, count: count)
            }
            .sorted { $0.month < $1.month }
    }

    static func seasonCounts(from trips: [Trip]) -> (spring: Int, autumn: Int) {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        var spring = 0, autumn = 0
        for trip in trips {
            guard let d = f.date(from: trip.date) else { continue }
            let m = Calendar.current.component(.month, from: d)
            if m >= 3 && m <= 6 { spring += 1 }
            else if m >= 8 && m <= 11 { autumn += 1 }
        }
        return (spring, autumn)
    }
}
