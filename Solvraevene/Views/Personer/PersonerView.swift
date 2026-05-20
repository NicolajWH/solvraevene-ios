import SwiftUI

struct PersonerView: View {
    @Environment(TripStore.self) private var store

    var pastTrips: [Trip] {
        store.trips.filter { !$0.isFuture }
    }

    var stats: [(name: String, initials: String, count: Int)] {
        StatsService.organizerCounts(from: pastTrips)
    }

    var nextTripOrganizers: Set<String> {
        guard let nextTrip = store.trips
            .filter({ $0.isFuture })
            .sorted(by: { $0.date < $1.date })
            .first
        else { return [] }
        return Set(nextTrip.organizers)
    }

    var body: some View {
        List {
            Section {
                ForEach(Array(stats.enumerated()), id: \.element.initials) { index, item in
                    NavigationLink(destination: PersonTripsView(
                        initials: item.initials,
                        name: item.name,
                        trips: pastTrips.filter { $0.organizers.contains(item.initials) }
                    )) {
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .frame(width: 24)

                            OrganizerAvatar(initials: item.initials)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(item.name)
                                        .font(.headline)
                                    if nextTripOrganizers.contains(item.initials) {
                                        Text("Næste tur")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.15))
                                            .foregroundStyle(.blue)
                                            .clipShape(Capsule())
                                    }
                                }
                                Text(item.initials)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("\(item.count) \(item.count == 1 ? "tur" : "ture")")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("Arrangører")
            }
        }
        .navigationTitle("Personer")
    }
}
