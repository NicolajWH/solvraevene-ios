import SwiftUI
import MapKit

struct TripMapView: View {
    @Environment(TripStore.self) private var store

    @State private var position: MapCameraPosition = .automatic
    @State private var selectedTrip: Trip?

    var tripsWithCoordinates: [Trip] {
        store.trips.filter { $0.coordinate != nil }
    }

    var body: some View {
        Map(position: $position) {
            ForEach(tripsWithCoordinates) { trip in
                Annotation("", coordinate: trip.coordinate!) {
                    Button {
                        selectedTrip = trip
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 18, height: 18)
                                .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
                            Circle()
                                .fill(trip.isFuture ? Color.blue : Color(red: 0.35, green: 0.34, blue: 0.84))
                                .frame(width: 12, height: 12)
                        }
                        .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Kort")
        .sheet(item: $selectedTrip) { trip in
            NavigationStack {
                TripDetailView(trip: trip)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Luk") { selectedTrip = nil }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }
}
