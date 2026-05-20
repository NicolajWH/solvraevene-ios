import SwiftUI

struct TripListView: View {
    @Environment(TripStore.self) private var store

    var futureTrips: [Trip] {
        store.trips.filter { $0.isFuture }.sorted { $0.date < $1.date }
    }

    var pastTrips: [Trip] {
        store.trips.filter { !$0.isFuture }.sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            if !futureTrips.isEmpty {
                Section("Kommende ture") {
                    ForEach(futureTrips) { trip in
                        NavigationLink(destination: TripDetailView(trip: trip)) {
                            tripRow(trip)
                        }
                    }
                }
            }

            Section("Tidligere ture") {
                ForEach(pastTrips) { trip in
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        tripRow(trip)
                    }
                }
            }
        }
        .navigationTitle("Ture")
    }

    private func tripRow(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(trip.formattedDateRange)
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
