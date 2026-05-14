import SwiftUI

struct TripListView: View {
    let trips = DataService.loadTrips()

    var body: some View {
        List {
            ForEach(trips) { trip in
                VStack(alignment: .leading, spacing: 6) {
                    Text(formattedDate(trip.date))
                        .font(.headline)
                    Text(trip.organizers.map { Organizer.fullName(for: $0) }.joined(separator: " & "))
                        .font(.subheadline)
                    Text(trip.location)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Ture")
    }

    private func formattedDate(_ dateString: String) -> String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        let output = DateFormatter()
        output.dateStyle = .long
        output.locale = Locale(identifier: "da_DK")
        guard let date = input.date(from: dateString) else { return dateString }
        return output.string(from: date)
    }
}
