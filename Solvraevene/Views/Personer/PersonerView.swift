import SwiftUI
import Charts

struct PersonerView: View {
    @Environment(TripStore.self) private var store
    @State private var selectedPair: PairSelection?

    var pastTrips: [Trip] {
        store.trips.filter { !$0.isFuture }
    }

    private var pairMatrix: [String: [String: Int]] {
        StatsService.pairCounts(from: pastTrips)
    }

    private var monthCounts: [(month: Int, label: String, count: Int)] {
        StatsService.monthCounts(from: pastTrips)
    }

    private var seasonCounts: (spring: Int, autumn: Int) {
        StatsService.seasonCounts(from: pastTrips)
    }

    /// Pair with the highest joint count.
    private var topPair: (a: String, b: String, count: Int)? {
        let people = sortedStats.map { $0.initials }
        var best: (String, String, Int)?
        for i in 0..<people.count {
            for j in (i+1)..<people.count {
                let a = people[i], b = people[j]
                let c = pairMatrix[a]?[b] ?? 0
                if best == nil || c > best!.2 {
                    best = (a, b, c)
                }
            }
        }
        guard let b = best else { return nil }
        return (a: b.0, b: b.1, count: b.2)
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
                        }
                        .padding(.vertical, 4)
                    }
                }
            } footer: {
                Text("")
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
                if let top = topPair {
                    HStack(spacing: 10) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mest aktive par")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(Organizer.fullName(for: top.a)) & \(Organizer.fullName(for: top.b))")
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        Spacer()
                        Text("\(top.count) ture")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                PairMatrixView(
                    people: sortedStats.map { $0.initials },
                    pairs: pairMatrix
                ) { a, b in
                    selectedPair = PairSelection(a: a, b: b)
                }
                .padding(.vertical, 8)
            } header: {
                Text("Hvor mange gange har de arrangeret sammen?")
            } footer: {
                Text("Orange ramme = par der mangler en runde. Tryk på en celle for at se de fælles ture.")
            }

            Section("Sæson") {
                HStack(spacing: 0) {
                    seasonPill(label: "Forår", count: seasonCounts.spring, color: .green)
                    Spacer()
                    seasonPill(label: "Efterår", count: seasonCounts.autumn, color: .orange)
                }
                .padding(.vertical, 4)

                Chart(monthCounts, id: \.month) { item in
                    BarMark(
                        x: .value("Måned", item.label),
                        y: .value("Antal", item.count)
                    )
                    .foregroundStyle(item.month <= 6 ? Color.green.gradient : Color.orange.gradient)
                    .cornerRadius(4)
                    .annotation(position: .top, alignment: .center) {
                        Text("\(item.count)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 120)
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Brødre")
        .navigationDestination(item: $selectedPair) { pair in
            PairTripsView(
                a: pair.a,
                b: pair.b,
                trips: pastTrips.filter {
                    $0.organizers.contains(pair.a) && $0.organizers.contains(pair.b)
                }
            )
        }
    }

    private func seasonPill(label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
