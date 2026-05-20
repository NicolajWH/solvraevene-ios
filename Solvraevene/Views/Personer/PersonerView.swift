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
            Section("Brødre") {
                ForEach(Array(stats.enumerated()), id: \.element.initials) { index, item in
                    NavigationLink(destination: PersonTripsView(
                        initials: item.initials,
                        name: item.name,
                        trips: pastTrips.filter { $0.organizers.contains(item.initials) }
                    )) {
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(width: 20)

                            OrganizerAvatar(initials: item.initials, size: 40)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                HStack(spacing: 6) {
                                    Text(item.initials)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if nextOrganizers.contains(item.initials) {
                                        badge("Formand", color: .blue)
                                    } else if secondOrganizers.contains(item.initials) {
                                        badge("Kommende formand", color: .teal)
                                    }
                                }
                            }

                            Spacer()

                            Text("\(item.count)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Brødre")
    }

    private func badge(_ label: String, color: Color) -> some View {
        Text(label)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
