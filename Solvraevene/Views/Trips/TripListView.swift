import SwiftUI

struct TripListView: View {
    @Environment(TripStore.self) private var store

    var body: some View {
        List {
            ForEach(store.trips) { trip in
                NavigationLink(destination: TripDetailView(trip: trip)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(trip.formattedDate)
                            .font(.headline)
                        Text(trip.organizers.map { Organizer.fullName(for: $0) }.joined(separator: " & "))
                            .font(.subheadline)
                        if let location = trip.location {
                            Text(location)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Ture")
    }
}
