import SwiftUI

struct TripDetailView: View {
    let trip: Trip

    var body: some View {
        List {
            Section {
                LabeledContent("Dato", value: trip.formattedDate)
                if let location = trip.location {
                    LabeledContent("Lokation", value: location)
                }
            }

            Section("Arrangører") {
                ForEach(trip.organizers, id: \.self) { initials in
                    Text(Organizer.fullName(for: initials))
                }
            }

            if let urlString = trip.photoAlbumURL, let url = URL(string: urlString) {
                Section {
                    Link(destination: url) {
                        Label("Se billeder fra turen", systemImage: "photo.stack")
                    }
                }
            }
        }
        .navigationTitle(trip.location ?? trip.formattedDate)
        .navigationBarTitleDisplayMode(.inline)
    }
}
