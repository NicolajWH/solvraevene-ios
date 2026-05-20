import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
            }
            .tabItem { Label("Forside", systemImage: "house.fill") }
            .tag(0)

            NavigationStack { TripListView() }
            .tabItem { Label("Ture", systemImage: "calendar") }
            .tag(1)

            NavigationStack { TripMapView() }
            .tabItem { Label("Kort", systemImage: "map.fill") }
            .tag(2)

            NavigationStack { CountriesView() }
            .tabItem { Label("Lande", systemImage: "flag.fill") }
            .tag(3)

            NavigationStack { PersonerView() }
            .tabItem { Label("Brødre", systemImage: "person.3.fill") }
            .tag(4)
        }
    }
}
