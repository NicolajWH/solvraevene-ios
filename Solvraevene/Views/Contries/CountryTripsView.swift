import SwiftUI

struct CountryTripsView: View {
    let isoCode: String
    let trips: [Trip]

    private func flag(for isoCode: String) -> String {
        isoCode.unicodeScalars
            .compactMap { Unicode.Scalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }

    private func countryName(for isoCode: String) -> String {
        Locale(identifier: "da_DK").localizedString(forRegionCode: isoCode) ?? isoCode
    }

    var body: some View {
        List {
            ForEach(trips.sorted { $0.date > $1.date }) { trip in
                NavigationLink(value: trip) {
                    HStack(alignment: .center, spacing: 12) {
                        HStack(spacing: -10) {
                            ForEach(trip.organizers, id: \.self) { initials in
                                OrganizerAvatar(initials: initials)
                                    .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                            }
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(trip.formattedDateRange)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if let location = trip.location {
                                Label(location, systemImage: "mappin.and.ellipse")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("\(flag(for: isoCode)) \(countryName(for: isoCode))")
    }
}
