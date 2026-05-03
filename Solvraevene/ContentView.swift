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
                    .navigationTitle("Ture")
            }
            .tabItem {
                Label("Ture", systemImage: "calendar")
            }

            NavigationStack {
                Text("Kort")
                    .navigationTitle("Kort")
            }
            .tabItem {
                Label("Kort", systemImage: "map.fill")
            }

            NavigationStack {
                Text("Lande")
                    .navigationTitle("Lande")
            }
            .tabItem {
                Label("Lande", systemImage: "flag.fill")
            }

            NavigationStack {
                Text("Personer")
                    .navigationTitle("Personer")
            }
            .tabItem {
                Label("Personer", systemImage: "person.3.fill")
            }
        }
    }
}

struct HomeView: View {
    var body: some View {
        List {
            Section("Næste ture") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("23. oktober 2026")
                        .font(.headline)
                    Text("MR & NWH")
                        .font(.title3)
                    Text("Status: Planlagt")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("23. april 2027")
                        .font(.headline)
                    Text("MSA & PHA")
                        .font(.title3)
                    Text("Status: Forslag")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Statistik") {
                Text("DM 9 · MC 10 · MR 10")
                Text("MSA 9 · NWH 9 · PHA 9")
            }
        }
        .navigationTitle("Sølvrævene")
    }
}
