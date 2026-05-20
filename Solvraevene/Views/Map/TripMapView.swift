import SwiftUI
import MapKit

struct TripMapView: View {
    @Environment(TripStore.self) private var store

    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 55.5, longitude: 10.0),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        )
    )

    @State private var selectedTrip: Trip?

    var tripsWithCoordinates: [Trip] {
        store.trips.filter { $0.coordinate != nil }
    }

    var body: some View {
        Map(position: $position) {
            ForEach(tripsWithCoordinates) { trip in
                Annotation(trip.location ?? trip.formattedDate, coordinate: trip.coordinate!) {
                    Button {
                        selectedTrip = trip
                    } label: {
                        VStack(spacing: 4) {
                            Text(trip.location ?? trip.formattedDate)
                                .font(.caption)
                                .padding(6)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)
                                .font(.title)
                        }
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
