import SwiftUI

struct HomeView: View {
    let trips = DataService.loadTrips()

    var nextTrips: [Trip] {
        Array(trips.prefix(2))
    }

    var body: some View {
        List {
            Section("Næste ture") {
                ForEach(nextTrips) { trip in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(trip.date)
                            .font(.headline)

                        Text(trip.organizers.joined(separator: " & "))
                            .font(.title3)

                        Text("Status: Planlagt")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Statistik") {
                ForEach(StatsService.organizerCounts(from: trips), id: \.name) { item in
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
}
