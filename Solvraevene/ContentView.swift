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
                Text("Ture")
            }
            .tabItem {
                Label("Ture", systemImage: "calendar")
            }

            NavigationStack {
                Text("Kort")
            }
            .tabItem {
                Label("Kort", systemImage: "map.fill")
            }

            NavigationStack {
                Text("Lande")
            }
            .tabItem {
                Label("Lande", systemImage: "flag.fill")
            }

            NavigationStack {
                Text("Personer")
            }
            .tabItem {
                Label("Personer", systemImage: "person.3.fill")
            }
        }
    }
}
