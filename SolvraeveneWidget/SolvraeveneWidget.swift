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
    let onThisDay: TripSnapshot?
}

struct TripProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextTripEntry {
        NextTripEntry(date: Date(), nextTrip: TripSnapshot(
            dateRange: "23.-25. oktober 2026",
            location: "Madrid",
            organizers: ["MR", "NWH"],
            countdown: "Om 156 dage"
        ), onThisDay: nil)
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
        let now = Date()
        let today = f.string(from: now)
        let cal = Calendar.current
        let todayMD = cal.dateComponents([.month, .day], from: now)

        let nextTrip: TripSnapshot? = rawTrips
            .filter({ ($0.endDate ?? $0.date) >= today })
            .sorted(by: { $0.date < $1.date })
            .first
            .map { t in
                TripSnapshot(
                    dateRange: formatRange(date: t.date, endDate: t.endDate),
                    location: t.location,
                    organizers: t.organizers,
                    countdown: countdownLabel(forStart: t.date)
                )
            }

        let onThisDay: TripSnapshot? = rawTrips
            .filter { t in
                guard (t.endDate ?? t.date) < today,
                      let d = f.date(from: t.date) else { return false }
                let c = cal.dateComponents([.month, .day], from: d)
                return c.month == todayMD.month && c.day == todayMD.day
            }
            .sorted { $0.date < $1.date }
            .first
            .map { t in
                let years = cal.dateComponents([.year], from: f.date(from: t.date)!, to: now).year ?? 0
                return TripSnapshot(
                    dateRange: "For \(years) år siden",
                    location: t.location,
                    organizers: t.organizers,
                    countdown: nil
                )
            }

        return NextTripEntry(date: now, nextTrip: nextTrip, onThisDay: onThisDay)
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
    private var isAccessory: Bool { family == .accessoryRectangular }

    var body: some View {
        if isAccessory {
            accessoryView
        } else {
            systemView
        }
    }

    // MARK: - CarPlay / Lock Screen (accessoryRectangular)

    @ViewBuilder
    private var accessoryView: some View {
        if let trip = entry.nextTrip {
            VStack(alignment: .leading, spacing: 2) {
                Label("Næste tur", systemImage: "figure.walk.departure")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let location = trip.location {
                    Text(location)
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                if let countdown = trip.countdown {
                    Text(countdown)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                } else {
                    Text(trip.dateRange)
                        .font(.system(size: 11))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(Color.clear, for: .widget)
        } else {
            Label("Ingen ture planlagt", systemImage: "figure.walk.departure")
                .font(.caption)
                .containerBackground(Color.clear, for: .widget)
        }
    }

    // MARK: - System small / medium

    @ViewBuilder
    private var systemView: some View {
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

                if !isSmall, let otd = entry.onThisDay {
                    Divider().overlay(Color.white.opacity(0.08)).padding(.vertical, 4)
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                            .font(.system(size: 10))
                            .foregroundStyle(textSecondary)
                        Text(otd.location ?? "I dag for \(otd.dateRange)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(textSecondary)
                            .lineLimit(1)
                        Spacer()
                        Text(otd.dateRange)
                            .font(.system(size: 10))
                            .foregroundStyle(textSecondary.opacity(0.7))
                    }
                } else {
                    HStack(spacing: -6) {
                        ForEach(trip.organizers, id: \.self) { initials in
                            avatarView(initials: initials, size: isSmall ? 22 : 28)
                        }
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
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
