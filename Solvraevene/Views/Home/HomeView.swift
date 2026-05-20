import SwiftUI

struct HomeView: View {
    @Environment(TripStore.self) private var store

    var nextTrips: [Trip] {
        Array(store.trips.filter { $0.isFuture }.sorted { $0.date < $1.date }.prefix(2))
    }

    var pastTrips: [Trip] {
        store.trips.filter { !$0.isFuture }
    }

    var lastTrip: Trip? {
        pastTrips.sorted { $0.date > $1.date }.first
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
                        NavigationLink(destination: TripDetailView(trip: trip)) {
                            upcomingTripRow(trip)
                        }
                    }
                }
            }

            Section("Fakta") {
                LabeledContent {
                    Text("\(pastTrips.count)").font(.headline)
                } label: {
                    Label("Ture gennemført", systemImage: "figure.walk.departure")
                }
                LabeledContent {
                    Text("\(StatsService.countryCounts(from: pastTrips).count)").font(.headline)
                } label: {
                    Label("Lande besøgt", systemImage: "globe.europe.africa.fill")
                }
            }

            if let trip = lastTrip {
                Section("Seneste tur") {
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        HStack(alignment: .center, spacing: 12) {
                            HStack(spacing: -10) {
                                ForEach(trip.organizers, id: \.self) { initials in
                                    OrganizerAvatar(initials: initials)
                                        .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                                }
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(trip.location ?? trip.formattedDate)
                                    .font(.headline)
                                Text(trip.formattedDateRange)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Sølvrævene")
    }

    private func upcomingTripRow(_ trip: Trip) -> some View {
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
