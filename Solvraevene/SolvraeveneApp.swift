import SwiftUI

@main
struct SolvraeveneApp: App {
    @State private var store = TripStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .task { await store.load() }
        }
    }
}
