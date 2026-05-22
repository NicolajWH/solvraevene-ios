import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
                    .tripDestinations()
            }
            .tabItem { Label("Forside", systemImage: "house.fill") }
            .tag(0)

            NavigationStack {
                TripListView()
                    .tripDestinations()
            }
            .tabItem { Label("Ture", systemImage: "calendar") }
            .tag(1)

            NavigationStack { TripMapView() }
            .tabItem { Label("Kort", systemImage: "map.fill") }
            .tag(2)

            NavigationStack {
                CountriesView()
                    .tripDestinations()
            }
            .tabItem { Label("Lande", systemImage: "flag.fill") }
            .tag(3)

            NavigationStack {
                PersonerView()
                    .tripDestinations()
            }
            .tabItem { Label("Brødre", systemImage: "person.3.fill") }
            .tag(4)
        }
    }
}

private extension View {
    func tripDestinations() -> some View {
        self
            .navigationDestination(for: Trip.self) { TripDetailView(trip: $0) }
            .navigationDestination(for: PackingListRoute.self) {
                PackingListView(tripDate: $0.tripDate, tripTitle: $0.tripTitle)
            }
            .navigationDestination(for: AnnouncementEditorRoute.self) {
                AnnouncementEditorView(route: $0)
            }
    }
}
