import SwiftUI

struct CountriesView: View {
    @Environment(TripStore.self) private var store

    private static let nordicCountries = ["DK", "NO", "SE", "FI", "IS"]

    private static let europeanCountries = [
        "AL", "AT", "BA", "BE", "BG", "BY", "CH", "CY", "CZ", "DE",
        "EE", "ES", "FR", "GB", "GR", "HR", "HU", "IE", "IT", "LT",
        "LU", "LV", "ME", "MK", "MT", "NL", "PL", "PT", "RO", "RS",
        "SI", "SK", "TR", "UA",
    ]

    var pastTrips: [Trip] {
        store.trips.filter { !$0.isFuture }
    }

    var countryCounts: [(country: String, count: Int)] {
        StatsService.countryCounts(from: pastTrips)
    }

    var visitedCodes: Set<String> {
        Set(countryCounts.map { $0.country })
    }

    var body: some View {
        List {
            if countryCounts.isEmpty {
                Text("Ingen kendte destinationer endnu")
                    .foregroundStyle(.secondary)
            } else {
                Section("Besøgte lande") {
                    ForEach(countryCounts, id: \.country) { item in
                        NavigationLink(destination: CountryTripsView(
                            isoCode: item.country,
                            trips: pastTrips.filter { $0.country == item.country }
                        )) {
                            HStack(spacing: 12) {
                                Text(flag(for: item.country))
                                    .font(.title2)
                                Text(countryName(for: item.country))
                                    .font(.headline)
                                Spacer()
                                Text("\(item.count) \(item.count == 1 ? "tur" : "ture")")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }

            Section("Norden") {
                countryGrid(Self.nordicCountries)
            }

            Section("Europa") {
                countryGrid(Self.europeanCountries)
            }
        }
        .navigationTitle("Lande")
    }

    private func countryGrid(_ codes: [String]) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5),
            spacing: 12
        ) {
            ForEach(codes, id: \.self) { code in
                let visited = visitedCodes.contains(code)
                VStack(spacing: 4) {
                    Text(flag(for: code))
                        .font(.title2)
                        .grayscale(visited ? 0 : 1)
                        .opacity(visited ? 1.0 : 0.35)
                    Text(countryName(for: code))
                        .font(.system(size: 9))
                        .foregroundStyle(visited ? .primary : .tertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        }
        .padding(.vertical, 8)
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
