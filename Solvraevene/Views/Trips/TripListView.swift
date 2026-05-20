import SwiftUI

struct TripListView: View {
    @Environment(TripStore.self) private var store
    @State private var showFuture = false

    var futureTrips: [Trip] {
        store.trips.filter { $0.isFuture }.sorted { $0.date < $1.date }
    }

    var pastTrips: [Trip] {
        store.trips.filter { !$0.isFuture }.sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section {
                Toggle("Vis kommende ture", isOn: $showFuture)
            }

            Section(showFuture ? "Kommende ture" : "Tidligere ture") {
                ForEach(showFuture ? futureTrips : pastTrips) { trip in
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        tripRow(trip)
                    }
                }
            }
        }
        .navigationTitle("Ture")
    }

    private func tripRow(_ trip: Trip) -> some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: -10) {
                ForEach(trip.organizers, id: \.self) { initials in
                    OrganizerAvatar(initials: initials)
                        .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(trip.formattedDateRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let location = trip.location {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
