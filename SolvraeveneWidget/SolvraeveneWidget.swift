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

    private let bg = Color(red: 0.06, green: 0.07, blue: 0.09)
    private let cardStroke = Color.white.opacity(0.06)
    private let accent = Color(red: 0.78, green: 0.78, blue: 0.84)
    private let textPrimary = Color.white
    private let textSecondary = Color.white.opacity(0.6)

    private var isSmall: Bool { family == .systemSmall }

    var body: some View {
        if let trip = entry.nextTrip {
            VStack(alignment: .leading, spacing: 4) {
                Text("NÆSTE TUR")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(textSecondary)

                if let location = trip.location {
                    Text(location)
                        .font(.system(size: isSmall ? 16 : 22, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Text(trip.dateRange)
                    .font(.system(size: isSmall ? 10 : 12))
                    .foregroundStyle(textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let countdown = trip.countdown {
                    Text(countdown)
                        .font(.system(
                            size: isSmall ? 20 : 26,
                            weight: .bold,
                            design: .rounded
                        ))
                        .foregroundStyle(accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.top, 2)
                }

                Spacer(minLength: 0)

                HStack(spacing: -6) {
                    ForEach(trip.organizers, id: \.self) { initials in
                        avatarView(initials: initials, size: isSmall ? 22 : 28)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(isSmall ? 12 : 16)
            .containerBackground(for: .widget) { bg }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "figure.walk.departure")
                    .font(.title2)
                    .foregroundStyle(textSecondary)
                Text("Ingen kommende ture")
                    .font(.caption)
                    .foregroundStyle(textSecondary)
                    .multilineTextAlignment(.center)
            }
            .containerBackground(for: .widget) { bg }
        }
    }

    private func avatarView(initials: String, size: CGFloat) -> some View {
        ZStack {
            if let ui = UIImage(named: "profile_\(initials)") {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle().fill(Color.white)
                Text(initials)
                    .font(.system(size: size * 0.34, weight: .semibold, design: .rounded))
                    .foregroundStyle(bg)
            }
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(bg, lineWidth: 2))
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
