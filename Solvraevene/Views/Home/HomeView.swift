import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    @Environment(TripStore.self) private var store

    // Palette
    private let bg = Color(red: 0.06, green: 0.07, blue: 0.09)
    private let cardBg = Color(red: 0.11, green: 0.12, blue: 0.15)
    private let cardStroke = Color.white.opacity(0.06)
    private let textPrimary = Color.white
    private let textSecondary = Color.white.opacity(0.6)
    private let textTertiary = Color.white.opacity(0.35)
    private let accent = Color(red: 0.78, green: 0.78, blue: 0.84) // silver

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
            VStack(spacing: 0) {
                if let error = store.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                if store.isLoading {
                    HStack(spacing: 10) {
                        ProgressView().tint(accent)
                        Text("Henter ture…").foregroundStyle(textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                // MARK: Upcoming
                VStack(alignment: .leading, spacing: 0) {
                    sectionLabel("Kommende ture")

                    if nextTrips.isEmpty {
                        Text("Ingen kommende ture")
                            .foregroundStyle(textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(nextTrips) { trip in
                                NavigationLink(destination: TripDetailView(trip: trip)) {
                                    upcomingCard(trip)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // MARK: Stats
                HStack(spacing: 12) {
                    Button { selectedTab = 1 } label: {
                        statTile(
                            value: pastTrips.count,
                            label: "Ture gennemført",
                            icon: "figure.walk.departure"
                        )
                    }
                    .buttonStyle(.plain)

                    Button { selectedTab = 3 } label: {
                        statTile(
                            value: countryCount,
                            label: "Lande besøgt",
                            icon: "globe.europe.africa.fill"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)

                // MARK: Last trip
                if let trip = lastTrip {
                    VStack(alignment: .leading, spacing: 0) {
                        sectionLabel("Seneste tur")
                        NavigationLink(destination: TripDetailView(trip: trip)) {
                            lastTripCard(trip)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 24)
                }
            }
            .padding(.bottom, 48)
        }
        .background(bg.ignoresSafeArea())
        .refreshable { await store.load() }
        .navigationTitle("Sølvrævene")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    // MARK: - Upcoming card

    private func upcomingCard(_ trip: Trip) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                if let location = trip.location {
                    Text(location)
                        .font(.headline)
                        .foregroundStyle(textPrimary)
                }
                Text(trip.formattedDateRange)
                    .font(.subheadline)
                    .foregroundStyle(textSecondary)
            }

            Spacer()

            HStack(spacing: -8) {
                ForEach(trip.organizers, id: \.self) { initials in
                    OrganizerAvatar(initials: initials, size: 30)
                        .overlay(Circle().stroke(cardBg, lineWidth: 2))
                }
            }

            Image(systemName: "chevron.right")
                .foregroundStyle(textTertiary)
                .font(.caption)
        }
        .padding(16)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(cardStroke, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Stat tile

    private func statTile(value: Int, label: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(accent)
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(textTertiary)
                    .font(.caption2)
            }

            Text("\(value)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(textPrimary)

            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(cardStroke, lineWidth: 1)
        )
    }

    // MARK: - Last trip card

    private func lastTripCard(_ trip: Trip) -> some View {
        upcomingCard(trip)
    }

    // MARK: - Section label

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(1.5)
            .foregroundStyle(textSecondary)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
    }

    // MARK: - Helpers

    private func flag(for isoCode: String) -> String {
        isoCode.unicodeScalars
            .compactMap { Unicode.Scalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }
}
