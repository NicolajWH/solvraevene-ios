import SwiftUI

struct PersonerView: View {
    @Environment(TripStore.self) private var store

    var pastTrips: [Trip] {
        store.trips.filter { !$0.isFuture }
    }

    var stats: [(name: String, initials: String, count: Int)] {
        StatsService.organizerCounts(from: pastTrips)
    }

    var nextUpInitials: String? {
        guard !stats.isEmpty else { return nil }
        let minCount = stats.map { $0.count }.min()!
        let candidates = stats.filter { $0.count == minCount }
        if candidates.count == 1 { return candidates[0].initials }

        func lastTripDate(for initials: String) -> String {
            pastTrips
                .filter { $0.organizers.contains(initials) }
                .map { $0.date }
                .max() ?? "0000-00-00"
        }

        return candidates
            .min { lastTripDate(for: $0.initials) < lastTripDate(for: $1.initials) }?
            .initials
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
                                    if item.initials == nextUpInitials {
                                        Text("På tur snart!")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.2))
                                            .foregroundStyle(.orange)
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
            } footer: {
                Text("Den med færrest ture arrangerer næste tur.")
                    .font(.caption)
            }
        }
        .navigationTitle("Personer")
    }
}
