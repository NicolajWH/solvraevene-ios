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
                    if let first = nextTrips.first {
                        NavigationLink(destination: TripDetailView(trip: first)) {
                            heroCard(first)
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 8)
                    }
                    if nextTrips.count > 1 {
                        NavigationLink(destination: TripDetailView(trip: nextTrips[1])) {
                            compactCard(nextTrips[1])
                        }
                        .buttonStyle(.plain)
                    }
                }

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
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 20)

                if let trip = lastTrip {
                    sectionHeader("Seneste tur")
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        compactCard(trip)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color(uiColor: .systemBackground))
        .refreshable { await store.load() }
        .navigationTitle("Sølvrævene")
    }

    // MARK: - Hero card

    private func heroCard(_ trip: Trip) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(tripGradient(trip))
                .frame(minHeight: 200)
                .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                if let location = trip.location {
                    Text(location)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                }
                Text(trip.formattedDateRange)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))

                HStack(spacing: 6) {
                    ForEach(trip.organizers, id: \.self) { initials in
                        OrganizerAvatar(initials: initials, size: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 32 * 0.28)
                                    .stroke(.white.opacity(0.5), lineWidth: 1.5)
                            )
                    }
                }
                .padding(.top, 2)
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 200, alignment: .bottomLeading)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Compact card

    private func compactCard(_ trip: Trip) -> some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                if let location = trip.location {
                    Text(location).font(.headline)
                }
                Text(trip.formattedDateRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(trip.organizers, id: \.self) { initials in
                    OrganizerAvatar(initials: initials, size: 30)
                }
            }
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
                .padding(.leading, 4)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
    }

    // MARK: - Helpers

    private func tripGradient(_ trip: Trip) -> LinearGradient {
        let colors = trip.organizers.map { OrganizerAvatar.color(for: $0) }
        let c1 = colors.first ?? .blue
        let c2 = colors.dropFirst().first ?? c1.opacity(0.6)
        return LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .padding(.bottom, 10)
    }
}
