import SwiftUI

struct TripAnnouncementSection: View {
    let trip: Trip
    let announcement: TripAnnouncement?
    let onSave: (TripAnnouncement) -> Void

    var body: some View {
        Section("Info") {
            if let a = announcement, !a.isEmpty {
                if let msg = a.message, !msg.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BESKED FRA FORMANDEN")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(msg).font(.body)
                    }
                    .padding(.vertical, 4)
                }

                if let place = a.meetingPlace, !place.isEmpty {
                    Button { openMaps(place) } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red).frame(width: 20)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Mødested").font(.caption).foregroundStyle(.secondary)
                                Text(place).font(.body.weight(.medium)).foregroundStyle(.primary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                }

                if let dt = a.departureDate() {
                    infoRow(icon: "arrow.right.circle.fill", color: .green,
                            label: "Afgang", value: formatted(dt))
                }
                if let rt = a.returnDate() {
                    infoRow(icon: "arrow.left.circle.fill", color: .orange,
                            label: "Hjemkomst", value: formatted(rt))
                }

                NavigationLink(value: AnnouncementEditorRoute(trip: trip, existing: a, onSave: onSave)) {
                    Label("Rediger", systemImage: "pencil")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            } else {
                NavigationLink(value: AnnouncementEditorRoute(trip: trip, existing: nil, onSave: onSave)) {
                    Label("Tilføj info fra formanden", systemImage: "plus.circle")
                }
            }
        }
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "da_DK")
        f.dateFormat = "EEEE d. MMM 'kl.' HH:mm"
        return f.string(from: date).capitalized
    }

    private func openMaps(_ place: String) {
        let encoded = place.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    private func infoRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.body.weight(.medium))
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Navigation route

struct AnnouncementEditorRoute: Hashable {
    let trip: Trip
    let existing: TripAnnouncement?
    let onSave: (TripAnnouncement) -> Void

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.trip.id == rhs.trip.id }
    func hash(into hasher: inout Hasher) { hasher.combine(trip.id) }
}

// MARK: - Editor

struct AnnouncementEditorView: View {
    let route: AnnouncementEditorRoute

    @Environment(\.dismiss) private var dismiss
    @State private var message: String
    @State private var meetingPlace: String
    @State private var departureTime: Date
    @State private var returnDateTime: Date

    private let tripStartDate: Date
    private let tripEndDate: Date

    init(route: AnnouncementEditorRoute) {
        self.route = route

        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let start = f.date(from: route.trip.date) ?? Date()
        let end   = route.trip.endDate.flatMap { f.date(from: $0) } ?? start
        self.tripStartDate = start
        self.tripEndDate   = end

        let existing = route.existing
        _message      = State(initialValue: existing?.message ?? "")
        _meetingPlace = State(initialValue: existing?.meetingPlace ?? "")

        // Departure: trip start date at 09:00 by default
        let defaultDeparture: Date = {
            var c = Calendar.current.dateComponents([.year, .month, .day], from: start)
            c.hour = 9; c.minute = 0
            return Calendar.current.date(from: c) ?? start
        }()
        _departureTime = State(initialValue: existing?.departureDate() ?? defaultDeparture)

        // Return: trip end date at 14:00 by default
        let defaultReturn: Date = {
            var c = Calendar.current.dateComponents([.year, .month, .day], from: end)
            c.hour = 14; c.minute = 0
            return Calendar.current.date(from: c) ?? end
        }()
        _returnDateTime = State(initialValue: existing?.returnDate() ?? defaultReturn)
    }

    var body: some View {
        Form {
            Section("Besked fra formanden") {
                TextEditor(text: $message)
                    .frame(minHeight: 200)
                    .overlay(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("Skriv en besked til deltagerne…")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Section("Mødested") {
                HStack {
                    Image(systemName: "mappin.circle.fill").foregroundStyle(.red)
                    TextField("F.eks. Nicolajs hjem", text: $meetingPlace)
                }
            }

            Section {
                LabeledContent("Dato") {
                    Text(tripStartDate, style: .date).foregroundStyle(.secondary)
                }
                DatePicker("Tidspunkt", selection: $departureTime, displayedComponents: .hourAndMinute)
            } header: {
                Text("Afgang")
            }

            Section {
                // Let user pick Saturday or Sunday (or any day in range)
                DatePicker("Dato", selection: $returnDateTime,
                           in: tripStartDate...Calendar.current.date(byAdding: .day, value: 3, to: tripEndDate)!,
                           displayedComponents: .date)
                DatePicker("Tidspunkt", selection: $returnDateTime, displayedComponents: .hourAndMinute)
            } header: {
                Text("Hjemkomst")
            } footer: {
                Text("Vælg lørdag eller søndag afhængigt af hvornår I kører hjem.")
            }
        }
        .navigationTitle("Info om turen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Gem") { save() }
            }
        }
    }

    private func save() {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        let a = TripAnnouncement(
            message: message.trimmingCharacters(in: .whitespaces).isEmpty ? nil : message.trimmingCharacters(in: .whitespaces),
            meetingPlace: meetingPlace.trimmingCharacters(in: .whitespaces).isEmpty ? nil : meetingPlace.trimmingCharacters(in: .whitespaces),
            departureAt: f.string(from: departureTime),
            returnDateTime: f.string(from: returnDateTime)
        )
        route.onSave(a)
        dismiss()
    }
}
