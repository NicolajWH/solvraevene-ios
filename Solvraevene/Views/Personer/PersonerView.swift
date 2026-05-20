import SwiftUI

struct PersonerView: View {
    @Environment(TripStore.self) private var store

    var pastTrips: [Trip] {
        store.trips.filter { !$0.isFuture }
    }

    var stats: [(name: String, initials: String, count: Int)] {
        StatsService.organizerCounts(from: pastTrips)
    }

    var upcomingTrips: [Trip] {
        store.trips.filter { $0.isFuture }.sorted { $0.date < $1.date }
    }

    var nextOrganizers: Set<String> {
        Set(upcomingTrips.first?.organizers ?? [])
    }

    var secondOrganizers: Set<String> {
        Set(upcomingTrips.dropFirst().first?.organizers ?? [])
    }

    var body: some View {
        List {
            Section("Arrangører") {
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
                                HStack(spacing: 6) {
                                    Text(item.name)
                                        .font(.headline)
                                    if nextOrganizers.contains(item.initials) {
                                        badge("Formand", color: .blue)
                                    } else if secondOrganizers.contains(item.initials) {
                                        badge("Kommende formand", color: .teal)
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
            }
        }
        .navigationTitle("Personer")
    }

    private func badge(_ label: String, color: Color) -> some View {
        Text(label)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
