import SwiftUI
import Charts

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

    var sortedStats: [(name: String, initials: String, count: Int)] {
        stats.sorted { a, b in
            let aIsNext = nextOrganizers.contains(a.initials)
            let bIsNext = nextOrganizers.contains(b.initials)
            let aIsSecond = secondOrganizers.contains(a.initials)
            let bIsSecond = secondOrganizers.contains(b.initials)

            if aIsNext != bIsNext { return aIsNext }
            if aIsSecond != bIsSecond { return aIsSecond }
            return a.count > b.count
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(sortedStats, id: \.initials) { item in
                    NavigationLink(destination: PersonTripsView(
                        initials: item.initials,
                        name: item.name,
                        trips: pastTrips.filter { $0.organizers.contains(item.initials) }
                    )) {
                        HStack(spacing: 12) {
                            OrganizerAvatar(initials: item.initials, size: 40)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                if nextOrganizers.contains(item.initials) {
                                    badge("Formand", color: .blue)
                                } else if secondOrganizers.contains(item.initials) {
                                    badge("Kommende formand", color: .teal)
                                }
                            }

                            Spacer()

                            Text("\(item.count) \(item.count == 1 ? "tur" : "ture")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } footer: {
                Text("Tallet viser hvor mange ture broderen har arrangeret.")
            }

            Section("Ture arrangeret") {
                Chart(sortedStats, id: \.initials) { item in
                    BarMark(
                        x: .value("Antal", item.count),
                        y: .value("Bror", item.initials)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .cornerRadius(4)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("\(item.count)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let initials = value.as(String.self) {
                                Text(initials).font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: CGFloat(sortedStats.count) * 28 + 16)
                .padding(.vertical, 8)
            }

            Section {
                PairMatrixView(
                    people: sortedStats.map { $0.initials },
                    pairs: StatsService.pairCounts(from: pastTrips)
                )
                .padding(.vertical, 8)
            } header: {
                Text("Hvor mange gange har de arrangeret sammen?")
            } footer: {
                Text("Tallet er antal fælles ture. Mørk celle = mange ture sammen.")
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
