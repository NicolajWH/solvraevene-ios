import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Forside", systemImage: "house.fill")
            }

            NavigationStack {
                TripListView()
            }
            .tabItem {
                Label("Ture", systemImage: "calendar")
            }

            NavigationStack {
                TripMapView()
            }
            .tabItem {
                Label("Kort", systemImage: "map.fill")
            }

            NavigationStack {
                CountriesView()
            }
            .tabItem {
                Label("Lande", systemImage: "flag.fill")
            }

            NavigationStack {
                PersonerView()
            }
            .tabItem {
                Label("Personer", systemImage: "person.3.fill")
            }
        }
    }
}
