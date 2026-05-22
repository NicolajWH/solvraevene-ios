import SwiftUI

struct PairSelection: Identifiable, Hashable {
    let a: String
    let b: String
    var id: String { "\(a)-\(b)" }
}

struct PairTripsView: View {
    let a: String
    let b: String
    let trips: [Trip]

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    HStack(spacing: -10) {
                        OrganizerAvatar(initials: a, size: 44)
                            .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                        OrganizerAvatar(initials: b, size: 44)
                            .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Organizer.fullName(for: a))")
                            .font(.subheadline.weight(.semibold))
                        Text("\(Organizer.fullName(for: b))")
                            .font(.subheadline.weight(.semibold))
                    }
                    Spacer()
                    Text("\(trips.count) \(trips.count == 1 ? "tur" : "ture")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Fælles ture") {
                ForEach(trips.sorted { $0.date > $1.date }) { trip in
                    NavigationLink(value: trip) {
                        VStack(alignment: .leading, spacing: 3) {
                            if let location = trip.location {
                                Text(location).font(.headline)
                            }
                            Text(trip.formattedDateRange)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("\(a) & \(b)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
