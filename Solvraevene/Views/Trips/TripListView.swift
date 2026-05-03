import SwiftUI

struct TripListView: View {
    let trips = DataService.loadTrips()

    var body: some View {
        List {
            ForEach(trips) { trip in
                VStack(alignment: .leading, spacing: 6) {
                    Text(trip.date)
                        .font(.headline)

                    Text(trip.organizers.joined(separator: " & "))
                        .font(.subheadline)

                    Text(trip.location.isEmpty ? "Lokation mangler" : trip.location)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Ture")
    }
}
