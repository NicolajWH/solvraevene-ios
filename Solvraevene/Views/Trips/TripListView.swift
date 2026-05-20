import SwiftUI

struct TripListView: View {
    @Environment(TripStore.self) private var store
    @State private var showFuture = true

    var futureTrips: [Trip] {
        store.trips.filter { $0.isFuture }.sorted { $0.date < $1.date }
    }

    var pastTrips: [Trip] {
        store.trips.filter { !$0.isFuture }.sorted { $0.date > $1.date }
    }

    var body: some View {
        List(showFuture ? futureTrips : pastTrips) { trip in
            NavigationLink(destination: TripDetailView(trip: trip)) {
                tripRow(trip)
            }
        }
        .navigationTitle("Ture")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("", selection: $showFuture) {
                    Text("Kommende").tag(true)
                    Text("Tidligere").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
        }
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
