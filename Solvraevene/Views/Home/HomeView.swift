import SwiftUI

struct HomeView: View {
    @Environment(TripStore.self) private var store

    var nextTrips: [Trip] {
        Array(store.trips.filter { $0.isFuture }.sorted { $0.date < $1.date }.prefix(2))
    }

    var pastTrips: [Trip] {
        store.trips.filter { !$0.isFuture }
    }

    var nextOrganizerName: String? {
        let stats = StatsService.organizerCounts(from: pastTrips)
        guard !stats.isEmpty else { return nil }
        let minCount = stats.map { $0.count }.min()!
        let candidates = stats.filter { $0.count == minCount }
        if candidates.count == 1 { return candidates[0].name }
        func lastTripDate(for initials: String) -> String {
            pastTrips.filter { $0.organizers.contains(initials) }.map { $0.date }.max() ?? "0000-00-00"
        }
        return candidates.min { lastTripDate(for: $0.initials) < lastTripDate(for: $1.initials) }?.name
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

            Section("Fakta") {
                LabeledContent("Ture gennemført", value: "\(pastTrips.count)")
                LabeledContent("Lande besøgt", value: "\(StatsService.countryCounts(from: pastTrips).count)")
                if let name = nextOrganizerName {
                    LabeledContent("Næste arrangør", value: name)
                }
            }
        }
        .navigationTitle("Sølvrævene")
    }
}
