import SwiftUI

struct HomeView: View {
    @Environment(TripStore.self) private var store

    var nextTrips: [Trip] {
        Array(store.trips.filter { $0.isFuture }.sorted { $0.date < $1.date }.prefix(2))
    }

    var body: some View {
        List {
            if let error = store.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }

            if store.isLoading {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Henter ture…")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Kommende ture") {
                if nextTrips.isEmpty {
                    Text("Ingen kommende ture")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(nextTrips) { trip in
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
            }

            Section("Arrangør-statistik") {
                ForEach(StatsService.organizerCounts(from: store.trips), id: \.initials) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        Text("\(item.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Sølvrævene")
    }
}
