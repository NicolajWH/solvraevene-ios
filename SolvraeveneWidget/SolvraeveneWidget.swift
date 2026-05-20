import WidgetKit
import SwiftUI

struct TripSnapshot {
    let dateRange: String
    let location: String?
    let organizers: [String]
    let countdown: String?
}

private func countdownLabel(forStart date: String) -> String? {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    guard let start = f.date(from: date) else { return nil }
    let cal = Calendar.current
    let days = cal.dateComponents(
        [.day],
        from: cal.startOfDay(for: Date()),
        to: cal.startOfDay(for: start)
    ).day ?? 0
    guard days >= 0 else { return nil }
    switch days {
    case 0: return "I dag"
    case 1: return "I morgen"
    default: return "Om \(days) dage"
    }
}

struct NextTripEntry: TimelineEntry {
    let date: Date
    let nextTrip: TripSnapshot?
}

struct TripProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextTripEntry {
        NextTripEntry(date: Date(), nextTrip: TripSnapshot(
            dateRange: "23.-25. oktober 2026",
            location: "Madrid",
            organizers: ["MR", "NWH"],
            countdown: "Om 156 dage"
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (NextTripEntry) -> Void) {
        Task { completion(await fetchEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextTripEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            let next = Calendar.current.date(byAdding: .hour, value: 6, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func fetchEntry() async -> NextTripEntry {
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
        let today = f.string(from: Date())

        guard let t = rawTrips
            .filter({ ($0.endDate ?? $0.date) >= today })
            .sorted(by: { $0.date < $1.date })
            .first
        else {
            return NextTripEntry(date: Date(), nextTrip: nil)
        }

        return NextTripEntry(date: Date(), nextTrip: TripSnapshot(
            dateRange: formatRange(date: t.date, endDate: t.endDate),
            location: t.location,
            organizers: t.organizers,
            countdown: countdownLabel(forStart: t.date)
        ))
    }

    private func formatRange(date: String, endDate: String?) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "da_DK")
        guard let start = f.date(from: date) else { return date }

        let long = DateFormatter()
        long.dateFormat = "d. MMMM yyyy"
        long.locale = Locale(identifier: "da_DK")

        guard let endStr = endDate, let end = f.date(from: endStr) else {
            return long.string(from: start)
        }

        if Calendar.current.isDate(start, equalTo: end, toGranularity: .month) {
            let day = DateFormatter()
            day.dateFormat = "d"
            let monthYear = DateFormatter()
            monthYear.dateFormat = "MMMM yyyy"
            monthYear.locale = Locale(identifier: "da_DK")
            return "\(day.string(from: start)).-\(day.string(from: end)). \(monthYear.string(from: end))"
        }
        return "\(long.string(from: start)) – \(long.string(from: end))"
    }
}

struct WidgetEntryView: View {
    var entry: NextTripEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if let trip = entry.nextTrip {
            VStack(alignment: .leading, spacing: 4) {
                Text("NÆSTE TUR")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                if let location = trip.location {
                    Text(location)
                        .font(family == .systemSmall ? .headline : .title3.bold())
                        .lineLimit(1)
                }

                Text(trip.dateRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if let countdown = trip.countdown {
                    Text(countdown)
                        .font(.system(
                            size: family == .systemSmall ? 17 : 22,
                            weight: .bold,
                            design: .rounded
                        ))
                        .foregroundStyle(.primary)
                        .padding(.top, 4)
                }

                Spacer(minLength: 0)

                HStack(spacing: -6) {
                    ForEach(trip.organizers, id: \.self) { initials in
                        avatarView(initials: initials, size: family == .systemSmall ? 22 : 28)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "figure.walk.departure")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Ingen kommende ture")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }

    private func avatarView(initials: String, size: CGFloat) -> some View {
        ZStack {
            Circle().fill(avatarColor(for: initials))
            Text(initials)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(.background, lineWidth: 1.5))
    }

    private func avatarColor(for initials: String) -> Color {
        switch initials {
        case "DM":  return Color(red: 0.12, green: 0.53, blue: 0.72)
        case "NWH": return Color(red: 0.33, green: 0.31, blue: 0.76)
        case "MC":  return Color(red: 0.15, green: 0.58, blue: 0.28)
        case "MSA": return Color(red: 0.86, green: 0.45, blue: 0.14)
        case "PHA": return Color(red: 0.80, green: 0.20, blue: 0.24)
        case "MR":  return Color(red: 0.55, green: 0.18, blue: 0.76)
        default:
            let hue = Double(initials.unicodeScalars.reduce(0) { ($0 + Int($1.value)) % 360 }) / 360.0
            return Color(hue: hue, saturation: 0.65, brightness: 0.75)
        }
    }
}

@main
struct SolvraeveneWidget: Widget {
    let kind = "SolvraeveneWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TripProvider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Sølvrævene")
        .description("Se næste planlagte tur.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
