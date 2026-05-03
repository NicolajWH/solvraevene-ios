import SwiftUI
import MapKit

struct TripMapView: View {
    let trips = DataService.loadTrips()

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.5, longitude: 10.0),
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    )

    var tripsWithCoordinates: [Trip] {
        trips.filter { $0.coordinate != nil }
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: tripsWithCoordinates) { trip in
            MapAnnotation(coordinate: trip.coordinate!) {
                VStack {
                    Text(trip.location)
                        .font(.caption)
                        .padding(5)
                        .background(.ultraThinMaterial)
                        .cornerRadius(6)

                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.red)
                        .font(.title)
                }
            }
        }
        .navigationTitle("Kort")
    }
}
