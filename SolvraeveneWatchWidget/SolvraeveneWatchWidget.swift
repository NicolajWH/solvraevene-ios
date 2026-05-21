import WidgetKit
import SwiftUI

struct WatchTripSnapshot {
    let dateRange: String
    let location: String?
    let countdown: String?
    let daysUntil: Int?
}

struct WatchNextTripEntry: TimelineEntry {
    let date: Date
    let nextTrip: WatchTripSnapshot?
}

struct WatchTripProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchNextTripEntry {
        WatchNextTripEntry(date: Date(), nextTrip: WatchTripSnapshot(
            dateRange: "23.-25. okt 2026",
            location: "Madrid",
            countdown: "Om 156 dage",
            daysUntil: 156
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchNextTripEntry) -> Void) {
        Task { completion(await fetchEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchNextTripEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            let next = Calendar.current.date(byAdding: .hour, value: 6, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func fetchEntry() async -> WatchNextTripEntry {
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
            return WatchNextTripEntry(date: now, nextTrip: nil)
        }

        let days: Int? = {
            guard let start = f.date(from: t.date) else { return nil }
            let d = cal.dateComponents([.day], from: cal.startOfDay(for: now), to: cal.startOfDay(for: start)).day ?? 0
            return d >= 0 ? d : nil
        }()

        let countdown: String? = {
            guard let d = days else { return nil }
            switch d {
            case 0: return "I dag"
            case 1: return "I morgen"
            default: return "Om \(d) dage"
            }
        }()

        return WatchNextTripEntry(date: now, nextTrip: WatchTripSnapshot(
            dateRange: formatRange(date: t.date, endDate: t.endDate),
            location: t.location,
            countdown: countdown,
            daysUntil: days
        ))
    }

    private func formatRange(date: String, endDate: String?) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let start = f.date(from: date) else { return date }
        let short = DateFormatter()
        short.locale = Locale(identifier: "da_DK")
        short.dateFormat = "d. MMM"
        guard let endStr = endDate, let end = f.date(from: endStr) else {
            return short.string(from: start)
        }
        if Calendar.current.isDate(start, equalTo: end, toGranularity: .month) {
            let day = DateFormatter(); day.dateFormat = "d"
            let mon = DateFormatter(); mon.locale = Locale(identifier: "da_DK"); mon.dateFormat = "MMM"
            return "\(day.string(from: start)).-\(day.string(from: end)). \(mon.string(from: end))"
        }
        return "\(short.string(from: start)) – \(short.string(from: end))"
    }
}

struct WatchWidgetEntryView: View {
    var entry: WatchNextTripEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:  circularView
        case .accessoryRectangular: rectangularView
        case .accessoryCorner: cornerView
        case .accessoryInline: inlineView
        default: rectangularView
        }
    }

    // MARK: - Circular — viser antal dage som stort tal

    @ViewBuilder
    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let trip = entry.nextTrip, let days = trip.daysUntil {
                switch days {
                case 0:
                    VStack(spacing: -1) {
                        Text("I").font(.system(size: 12, weight: .bold))
                        Text("dag").font(.system(size: 13, weight: .bold))
                    }
                case 1:
                    VStack(spacing: -1) {
                        Text("I").font(.system(size: 12, weight: .bold))
                        Text("mrg").font(.system(size: 13, weight: .bold))
                    }
                default:
                    VStack(spacing: -3) {
                        Text("\(days)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                        Text("dage")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Image(systemName: "figure.walk.departure")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(Color.clear, for: .widget)
    }

    // MARK: - Rectangular — sted + nedtælling

    @ViewBuilder
    private var rectangularView: some View {
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

    // MARK: - Corner — ikon med buet tekst

    @ViewBuilder
    private var cornerView: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "figure.walk.departure")
                .font(.system(size: 16, weight: .semibold))
                .widgetAccentable()
        }
        .widgetLabel {
            if let countdown = entry.nextTrip?.countdown {
                Text(countdown)
            } else {
                Text("Ingen tur")
            }
        }
        .containerBackground(Color.clear, for: .widget)
    }

    // MARK: - Inline — enkelt linje øverst på urskiven

    @ViewBuilder
    private var inlineView: some View {
        if let trip = entry.nextTrip {
            Label {
                Group {
                    if let location = trip.location, let countdown = trip.countdown {
                        Text("\(location) · \(countdown)")
                    } else if let location = trip.location {
                        Text(location)
                    } else {
                        Text(trip.countdown ?? "Næste tur")
                    }
                }
            } icon: {
                Image(systemName: "figure.walk.departure")
            }
        } else {
            Label("Ingen kommende tur", systemImage: "figure.walk.departure")
        }
    }
}

@main
struct SolvraeveneWatchWidget: Widget {
    let kind = "SolvraeveneWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchTripProvider()) { entry in
            WatchWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Sølvrævene")
        .description("Nedtælling til næste tur.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryCorner, .accessoryInline])
    }
}
