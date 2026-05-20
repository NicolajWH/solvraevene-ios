import SwiftUI
import Charts

struct StatsView: View {
    @Environment(TripStore.self) private var store

    var pastTrips: [Trip] {
        store.trips.filter { !$0.isFuture }
    }

    var tripsByYear: [(year: String, count: Int)] {
        let grouped = Dictionary(grouping: pastTrips) { String($0.date.prefix(4)) }
        return grouped.map { (year: $0.key, count: $0.value.count) }.sorted { $0.year < $1.year }
    }

    var topCountries: [(country: String, count: Int)] {
        Array(StatsService.countryCounts(from: pastTrips).prefix(5))
    }

    var organizerStats: [(name: String, initials: String, count: Int)] {
        StatsService.organizerCounts(from: pastTrips)
    }

    var body: some View {
        List {
            Section("Ture per år") {
                ScrollView(.horizontal, showsIndicators: false) {
                    Chart(tripsByYear, id: \.year) { item in
                        BarMark(
                            x: .value("År", item.year),
                            y: .value("Ture", item.count)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .cornerRadius(4)
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel().font(.caption2)
                        }
                    }
                    .frame(width: CGFloat(tripsByYear.count) * 36, height: 180)
                }
                .padding(.vertical, 8)
            }

            if !topCountries.isEmpty {
                Section("Mest besøgte lande") {
                    ForEach(topCountries, id: \.country) { item in
                        HStack {
                            Text(flag(for: item.country)).font(.title2)
                            Text(countryName(for: item.country))
                            Spacer()
                            Text("\(item.count) \(item.count == 1 ? "tur" : "ture")")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Arrangørstatistik") {
                Chart(organizerStats, id: \.initials) { item in
                    BarMark(
                        x: .value("Antal", item.count),
                        y: .value("", item.initials)
                    )
                    .foregroundStyle(OrganizerAvatar.color(for: item.initials).gradient)
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let initials = value.as(String.self) {
                                Text(initials).font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 180)
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Statistik")
    }

    private func flag(for isoCode: String) -> String {
        isoCode.unicodeScalars
            .compactMap { Unicode.Scalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }

    private func countryName(for isoCode: String) -> String {
        Locale(identifier: "da_DK").localizedString(forRegionCode: isoCode) ?? isoCode
    }
}
