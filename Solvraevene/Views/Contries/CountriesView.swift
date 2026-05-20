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

    var unvisitedEuropean: [String] {
        Self.europeanCountries.filter { !visitedCodes.contains($0) }
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
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5),
                    spacing: 10
                ) {
                    ForEach(Self.nordicCountries, id: \.self) { code in
                        VStack(spacing: 4) {
                            Text(flag(for: code))
                                .font(.title2)
                                .grayscale(visitedCodes.contains(code) ? 0 : 1)
                                .opacity(visitedCodes.contains(code) ? 1.0 : 0.35)
                            Text(countryName(for: code))
                                .font(.system(size: 9))
                                .foregroundStyle(visitedCodes.contains(code) ? .primary : .tertiary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            if !unvisitedEuropean.isEmpty {
                Section("Lande vi mangler at besøge i Europa") {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5),
                        spacing: 12
                    ) {
                        ForEach(unvisitedEuropean, id: \.self) { code in
                            VStack(spacing: 3) {
                                Text(flag(for: code))
                                    .font(.title2)
                                    .grayscale(1)
                                    .opacity(0.4)
                                Text(countryName(for: code))
                                    .font(.system(size: 8))
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }
                        }
                    }
                    .padding(.vertical, 8)
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
