import Foundation

struct Trip: Identifiable, Codable {
    let id = UUID()
    let date: String
    let location: String?
    let organizers: [String]
}
