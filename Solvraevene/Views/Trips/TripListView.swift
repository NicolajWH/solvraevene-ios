import SwiftUI

struct TripListView: View {
    @Environment(TripStore.self) private var store
    @State private var showFuture = false
    @State private var searchText = ""

    var futureTrips: [Trip] {
        store.trips.filter { $0.isFuture }.sorted { $0.date < $1.date }
    }

    var pastTrips: [Trip] {
        store.trips.filter { !$0.isFuture }.sorted { $0.date > $1.date }
    }

    var filteredFuture: [Trip] {
        guard !searchText.isEmpty else { return futureTrips }
        return futureTrips.filter { matches($0) }
    }

    var futureByYear: [(year: String, trips: [Trip])] {
        let base = searchText.isEmpty ? futureTrips : futureTrips.filter { matches($0) }
        let grouped = Dictionary(grouping: base) { String($0.date.prefix(4)) }
        return grouped.map { (year: $0.key, trips: $0.value) }.sorted { $0.year < $1.year }
    }

    var pastByYear: [(year: String, trips: [Trip])] {
        let base = searchText.isEmpty ? pastTrips : pastTrips.filter { matches($0) }
        let grouped = Dictionary(grouping: base) { String($0.date.prefix(4)) }
        return grouped.map { (year: $0.key, trips: $0.value) }.sorted { $0.year > $1.year }
    }

    var body: some View {
        List {
            Section {
                Toggle("Vis kommende ture", isOn: $showFuture)
            }

            if showFuture {
                ForEach(futureByYear, id: \.year) { group in
                    Section(group.year) {
                        ForEach(group.trips) { trip in
                            NavigationLink(destination: TripDetailView(trip: trip)) {
                                tripRow(trip)
                            }
                        }
                    }
                }
            } else {
                ForEach(pastByYear, id: \.year) { group in
                    Section(group.year) {
                        ForEach(group.trips) { trip in
                            NavigationLink(destination: TripDetailView(trip: trip)) {
                                tripRow(trip)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Søg på lokation eller arrangør")
        .refreshable { await store.load() }
        .navigationTitle("Ture")
    }

    private func matches(_ trip: Trip) -> Bool {
        let q = searchText.lowercased()
        if trip.location?.lowercased().contains(q) == true { return true }
        return trip.organizers.contains { Organizer.fullName(for: $0).lowercased().contains(q) }
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
