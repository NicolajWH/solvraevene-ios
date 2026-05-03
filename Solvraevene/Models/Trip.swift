import Foundation

struct Trip: Identifiable, Codable {
    var id = UUID()
    let date: String
    let location: String
    let organizers: [String]

    enum CodingKeys: String, CodingKey {
        case date
        case location
        case organizers
    }
}
