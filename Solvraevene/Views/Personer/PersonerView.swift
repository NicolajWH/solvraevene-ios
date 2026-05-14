import SwiftUI

struct PersonerView: View {
    let trips = DataService.loadTrips()

    var stats: [(name: String, initials: String, count: Int)] {
        StatsService.organizerCounts(from: trips)
    }

    var minCount: Int {
        stats.map { $0.count }.min() ?? 0
    }

    var body: some View {
        List {
            Section {
                ForEach(Array(stats.enumerated()), id: \.element.initials) { index, item in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(item.name)
                                    .font(.headline)
                                if item.count == minCount {
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
