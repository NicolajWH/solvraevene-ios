import SwiftUI

struct PersonTripsView: View {
    let initials: String
    let name: String
    let trips: [Trip]

    var body: some View {
        List {
            ForEach(trips.sorted { $0.date > $1.date }) { trip in
                NavigationLink(destination: TripDetailView(trip: trip)) {
                    HStack(alignment: .center, spacing: 12) {
                        HStack(spacing: -10) {
                            ForEach(trip.organizers, id: \.self) { i in
                                OrganizerAvatar(initials: i)
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
        .navigationTitle(name)
    }
}
