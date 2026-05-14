import Foundation

struct Organizer {
    static let names: [String: String] = [
        "DM":  "Danny Meyer",
        "NWH": "Nicolaj Worsaae Haugaard",
        "MC":  "Morten Christoffersen",
        "MSA": "Martin Stjernholm Andersen",
        "PHA": "Peter Hassø Andersen",
        "MR":  "Martin Røjgaard"
    ]

    static func fullName(for initials: String) -> String {
        names[initials] ?? initials
    }
}
