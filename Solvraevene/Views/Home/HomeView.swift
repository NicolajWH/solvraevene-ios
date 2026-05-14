import SwiftUI

struct HomeView: View {
    let trips = DataService.loadTrips()

    var futureTrips: [Trip] {
        trips.filter { $0.isFuture }.sorted { $0.date < $1.date }
    }

    var body: some View {
        List {
            Section("Kommende ture") {
                if futureTrips.isEmpty {
                    Text("Ingen kommende ture")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(futureTrips) { trip in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(formattedDate(trip.date))
                                .font(.headline)
                            Text(trip.organizers.map { Organizer.fullName(for: $0) }.joined(separator: " & "))
                                .font(.subheadline)
                            Text(trip.location)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Arrangør-statistik") {
                ForEach(StatsService.organizerCounts(from: trips), id: \.initials) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        Text("\(item.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Sølvrævene")
    }

    private func formattedDate(_ dateString: String) -> String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        let output = DateFormatter()
        output.dateStyle = .long
        output.locale = Locale(identifier: "da_DK")
        guard let date = input.date(from: dateString) else { return dateString }
        return output.string(from: date)
    }
}
