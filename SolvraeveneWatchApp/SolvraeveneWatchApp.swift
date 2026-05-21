import SwiftUI

@main
struct SolvraeveneWatchApp: App {
    var body: some Scene {
        WindowGroup { WatchHomeView() }
    }
}

// MARK: - Data

struct WatchTrip {
    let dateRange: String
    let organizers: [String]
    let daysUntil: Int
}

@MainActor
class WatchViewModel: ObservableObject {
    @Published var trip: WatchTrip?
    @Published var isLoading = true

    func load() async {
        struct RawTrip: Decodable {
            let date: String
            let endDate: String?
            let location: String?
            let organizers: [String]
        }

        let url = URL(string: "https://raw.githubusercontent.com/nicolajwh/solvraevene-ios/main/Solvraevene/Resources/trips.json")!
        var rawTrips: [RawTrip] = []
        if let data = try? await URLSession.shared.data(from: url).0 {
            rawTrips = (try? JSONDecoder().decode([RawTrip].self, from: data)) ?? []
        }

        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let now = Date()
        let today = f.string(from: now)
        let cal = Calendar.current

        guard let t = rawTrips
            .filter({ ($0.endDate ?? $0.date) >= today })
            .sorted(by: { $0.date < $1.date })
            .first
        else {
            isLoading = false
            return
        }

        let days: Int = {
            guard let start = f.date(from: t.date) else { return 0 }
            let d = cal.dateComponents([.day], from: cal.startOfDay(for: now), to: cal.startOfDay(for: start)).day ?? 0
            return max(0, d)
        }()

        trip = WatchTrip(
            dateRange: formatRange(date: t.date, endDate: t.endDate, f: f),
            organizers: t.organizers,
            daysUntil: days
        )
        isLoading = false
    }

    private func formatRange(date: String, endDate: String?, f: DateFormatter) -> String {
        guard let start = f.date(from: date) else { return date }
        let short = DateFormatter()
        short.locale = Locale(identifier: "da_DK")
        short.dateFormat = "d. MMM"
        guard let endStr = endDate, let end = f.date(from: endStr) else {
            return short.string(from: start)
        }
        let cal = Calendar.current
        if cal.isDate(start, equalTo: end, toGranularity: .month) {
            let day = DateFormatter(); day.dateFormat = "d"
            let mon = DateFormatter(); mon.locale = Locale(identifier: "da_DK"); mon.dateFormat = "MMM"
            return "\(day.string(from: start)).-\(day.string(from: end)). \(mon.string(from: end))"
        }
        return "\(short.string(from: start)) – \(short.string(from: end))"
    }
}

// MARK: - Views

struct WatchHomeView: View {
    @StateObject private var vm = WatchViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
            } else if let trip = vm.trip {
                WatchCountdownView(trip: trip)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Ingen ture planlagt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .task { await vm.load() }
    }
}

struct WatchCountdownView: View {
    let trip: WatchTrip

    var body: some View {
        VStack(spacing: 6) {
            Text("🦊")
                .font(.system(size: 20))
                .grayscale(1)
            switch trip.daysUntil {
            case 0:
                Text("I dag!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.yellow)
            case 1:
                Text("I morgen")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.yellow)
            default:
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(trip.daysUntil)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("dage")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 2)
                }
            }

            Text(trip.dateRange)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(trip.organizers, id: \.self) { initials in
                    ZStack {
                        Circle()
                            .fill(avatarColor(for: initials))
                            .frame(width: 26, height: 26)
                        Text(initials)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.top, 2)
        }
    }

    private func avatarColor(for initials: String) -> Color {
        switch initials {
        case "NWH": return Color(red: 0.20, green: 0.47, blue: 0.96)
        case "MR":  return Color(red: 0.85, green: 0.26, blue: 0.21)
        case "MB":  return Color(red: 0.20, green: 0.70, blue: 0.45)
        case "TA":  return Color(red: 0.60, green: 0.35, blue: 0.90)
        case "JH":  return Color(red: 0.95, green: 0.55, blue: 0.15)
        case "SS":  return Color(red: 0.15, green: 0.65, blue: 0.75)
        default:    return Color.gray
        }
    }
}
