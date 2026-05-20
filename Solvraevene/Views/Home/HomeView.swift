import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
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
                            upcomingCard(trip)
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 8)
                    }
                }

                // Stats tiles
                HStack(spacing: 12) {
                    Button { selectedTab = 1 } label: {
                        statTile(
                            value: pastTrips.count,
                            label: "Ture gennemført",
                            icon: "figure.walk.departure",
                            color: .blue
                        )
                    }
                    .buttonStyle(.plain)

                    Button { selectedTab = 3 } label: {
                        statTile(
                            value: countryCount,
                            label: "Lande besøgt",
                            icon: "globe.europe.africa.fill",
                            color: .green
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 28)
                .padding(.bottom, 4)

                if let trip = lastTrip {
                    sectionHeader("Seneste tur")
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        upcomingCard(trip)
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

    // MARK: - Upcoming card (consistent style for all trip cards on home)

    private func upcomingCard(_ trip: Trip) -> some View {
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

    // MARK: - Stat tile with counting animation

    private func statTile(value: Int, label: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            CountingText(target: value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .padding(.bottom, 10)
    }
}

// MARK: - Counting animation

private struct CountingText: View {
    let target: Int
    var font: Font = .body
    @State private var displayed = 0
    @State private var hasAppeared = false

    var body: some View {
        Text("\(displayed)")
            .font(font)
            .contentTransition(.numericText())
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                animate(from: 0, to: target)
            }
            .onChange(of: target) { old, new in
                animate(from: old, to: new)
            }
    }

    private func animate(from old: Int, to value: Int) {
        guard value != old else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.9)) {
                displayed = value
            }
        }
    }
}
