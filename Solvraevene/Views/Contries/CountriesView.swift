import SwiftUI

struct CountriesView: View {
    @Environment(TripStore.self) private var store

    var pastTrips: [Trip] {
        store.trips.filter { !$0.isFuture }
    }

    var countryCounts: [(country: String, count: Int)] {
        StatsService.countryCounts(from: pastTrips)
    }

    var body: some View {
        List {
            if countryCounts.isEmpty {
                Text("Ingen kendte destinationer endnu")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(countryCounts, id: \.country) { item in
                    NavigationLink(destination: CountryTripsView(
                        isoCode: item.country,
                        trips: pastTrips.filter { $0.country == item.country }
                    )) {
                        HStack(spacing: 12) {
                            Text(flag(for: item.country))
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(countryName(for: item.country))
                                    .font(.headline)
                                Text(item.country)
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
        .navigationTitle("Lande")
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
