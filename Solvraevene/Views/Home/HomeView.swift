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
            VStack(spacing: 0) {
                if let error = store.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                if store.isLoading {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Henter ture…").foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                // MARK: Upcoming trips
                VStack(alignment: .leading, spacing: 0) {
                    sectionLabel("Kommende ture")

                    if nextTrips.isEmpty {
                        Text("Ingen kommende ture")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                    } else {
                        if let first = nextTrips.first {
                            NavigationLink(destination: TripDetailView(trip: first)) {
                                heroCard(first)
                            }
                            .buttonStyle(.plain)
                        }

                        if nextTrips.count > 1 {
                            NavigationLink(destination: TripDetailView(trip: nextTrips[1])) {
                                secondaryCard(nextTrips[1])
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 10)
                        }
                    }
                }
                .padding(.top, 4)

                // MARK: Stats
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
        .background(Color(uiColor: .systemGroupedBackground))
        .refreshable { await store.load() }
        .navigationTitle("Sølvrævene")
    }

    // MARK: - Hero card (next trip)

    private func heroCard(_ trip: Trip) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(tripGradient(trip))
                .frame(minHeight: 220)

            // subtle dark overlay at bottom for text legibility
            LinearGradient(
                colors: [.clear, .black.opacity(0.45)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(alignment: .leading, spacing: 10) {
                Spacer()

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let location = trip.location {
                            Text(location)
                                .font(.title.bold())
                                .foregroundStyle(.white)
                        }
                        Text(trip.formattedDateRange)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    Spacer()

                    HStack(spacing: -8) {
                        ForEach(trip.organizers, id: \.self) { initials in
                            OrganizerAvatar(initials: initials, size: 36)
                                .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 2))
                        }
                    }
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, minHeight: 220, alignment: .bottomLeading)
        }
        .padding(.horizontal, 16)
        .shadow(color: tripShadowColor(trip), radius: 18, x: 0, y: 8)
    }

    // MARK: - Secondary upcoming trip card

    private func secondaryCard(_ trip: Trip) -> some View {
        HStack(spacing: 0) {
            // Color stripe
            RoundedRectangle(cornerRadius: 3)
                .fill(tripGradient(trip))
                .frame(width: 5)
                .padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 4) {
                if let location = trip.location {
                    Text(location)
                        .font(.headline)
                }
                Text(trip.formattedDateRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)

            Spacer()

            HStack(spacing: -6) {
                ForEach(trip.organizers, id: \.self) { initials in
                    OrganizerAvatar(initials: initials, size: 30)
                        .overlay(Circle().stroke(Color(uiColor: .secondarySystemGroupedBackground), lineWidth: 2))
                }
            }

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
                .padding(.leading, 10)
                .padding(.trailing, 16)
        }
        .padding(.leading, 14)
        .padding(.vertical, 14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }

    // MARK: - Stat tile

    private func statTile(value: Int, label: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .font(.system(size: 16, weight: .semibold))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption2)
            }

            CountingText(target: value)
                .font(.system(size: 36, weight: .bold, design: .rounded))

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Last trip card

    private func lastTripCard(_ trip: Trip) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tripFirstColor(trip).opacity(0.12))
                    .frame(width: 44, height: 44)
                if let country = trip.country {
                    Text(flag(for: country))
                        .font(.title3)
                } else {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(tripFirstColor(trip))
                        .font(.title3)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                if let location = trip.location {
                    Text(location).font(.headline)
                }
                Text(trip.formattedDateRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: -6) {
                ForEach(trip.organizers, id: \.self) { initials in
                    OrganizerAvatar(initials: initials, size: 30)
                        .overlay(Circle().stroke(Color(uiColor: .secondarySystemGroupedBackground), lineWidth: 2))
                }
            }

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
                .padding(.leading, 6)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
    }

    // MARK: - Section label

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 12)
    }

    // MARK: - Helpers

    private func tripGradient(_ trip: Trip) -> LinearGradient {
        let colors = trip.organizers.map { OrganizerAvatar.color(for: $0) }
        let c1 = colors.first ?? .blue
        let c2 = colors.dropFirst().first ?? c1.opacity(0.7)
        return LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func tripFirstColor(_ trip: Trip) -> Color {
        trip.organizers.first.map { OrganizerAvatar.color(for: $0) } ?? .blue
    }

    private func tripShadowColor(_ trip: Trip) -> Color {
        (trip.organizers.first.map { OrganizerAvatar.color(for: $0) } ?? .blue).opacity(0.35)
    }

    private func flag(for isoCode: String) -> String {
        isoCode.unicodeScalars
            .compactMap { Unicode.Scalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
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
