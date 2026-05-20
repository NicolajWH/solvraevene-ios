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

    var countryCount: Int {
        StatsService.countryCounts(from: pastTrips).count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let error = store.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }

                if store.isLoading {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Henter ture…").foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }

                sectionHeader("Kommende ture")
                if nextTrips.isEmpty {
                    Text("Ingen kommende ture")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                } else {
                    ForEach(nextTrips) { trip in
                        NavigationLink(destination: TripDetailView(trip: trip)) {
                            tripCard(trip)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 12) {
                    statTile(value: "\(pastTrips.count)", label: "Ture", icon: "figure.walk.departure", color: .blue)
                    statTile(value: "\(countryCount)", label: "Lande", icon: "globe.europe.africa.fill", color: .green)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)

                NavigationLink(destination: StatsView()) {
                    HStack {
                        Label("Se statistik", systemImage: "chart.bar.fill")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 12)

                if let trip = lastTrip {
                    sectionHeader("Seneste tur")
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        tripCard(trip)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 32)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .refreshable { await store.load() }
        .navigationTitle("Sølvrævene")
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 8)
    }

    private func tripCard(_ trip: Trip) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(trip.formattedDateRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let location = trip.location {
                    Text(location)
                        .font(.headline)
                }
                HStack(spacing: -8) {
                    ForEach(trip.organizers, id: \.self) { initials in
                        OrganizerAvatar(initials: initials, size: 28)
                            .overlay(Circle().stroke(Color(uiColor: .secondarySystemGroupedBackground), lineWidth: 2))
                    }
                }
                .padding(.top, 2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private func statTile(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.title2.bold())
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
