import SwiftUI
import EventKit

struct TripDetailView: View {
    let trip: Trip

    @State private var calendarMessage: String?
    @State private var showCalendarAlert = false

    private var displayTitle: String {
        trip.isFuture ? trip.formattedDateRange : (trip.location ?? trip.formattedDateRange)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 0) {
                    if let country = trip.country {
                        Text(flag(for: country))
                            .font(.system(size: 44))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 12)
                    }

                    Text("Dato")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(trip.formattedDateRange)
                        .font(.body.weight(.medium))
                        .padding(.top, 2)
                        .padding(.bottom, 16)

                    Divider()
                        .padding(.bottom, 16)

                    Text("Arrangører")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .padding(.bottom, 8)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(trip.organizers, id: \.self) { initials in
                            HStack(spacing: 12) {
                                OrganizerAvatar(initials: initials, size: 34)
                                Text(Organizer.fullName(for: initials))
                                    .font(.body.weight(.medium))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            }

            if let urlString = trip.photoAlbumURL, let url = URL(string: urlString) {
                Section {
                    Link(destination: url) {
                        Label("Se billeder fra turen", systemImage: "photo.stack")
                    }
                }
            }

            if trip.isFuture {
                TripAnnouncementSection(
                    tripDate: trip.date,
                    tripEndDate: trip.endDate,
                    tripTitle: displayTitle
                )
            }

            Section {
                NavigationLink(destination: PackingListView(
                    tripDate: trip.date,
                    tripTitle: displayTitle
                )) {
                    Label("Huskeliste", systemImage: "checklist")
                }
            }

            if trip.isFuture {
                Section {
                    Button {
                        addToCalendar()
                    } label: {
                        Label("Tilføj til kalender", systemImage: "calendar.badge.plus")
                    }
                }
            }
        }
        .navigationTitle(displayTitle)
        .navigationBarTitleDisplayMode(.large)
        .alert("Kalender", isPresented: $showCalendarAlert) {
            Button("OK") {}
        } message: {
            Text(calendarMessage ?? "")
        }
    }

    private func flag(for isoCode: String) -> String {
        isoCode.unicodeScalars
            .compactMap { Unicode.Scalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }

    private func addToCalendar() {
        let eventStore = EKEventStore()
        Task {
            do {
                let granted = try await eventStore.requestWriteOnlyAccessToEvents()
                guard granted else {
                    calendarMessage = "Adgang til kalender er ikke tilladt. Tillad adgang i Indstillinger."
                    showCalendarAlert = true
                    return
                }

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"

                guard let startDate = formatter.date(from: trip.date) else { return }
                let endString = trip.endDate ?? trip.date
                guard let endDate = formatter.date(from: endString) else { return }

                let event = EKEvent(eventStore: eventStore)
                event.title = trip.isFuture ? "Sølvrævene" : (trip.location.map { "Sølvrævene – \($0)" } ?? "Sølvrævene")
                event.startDate = startDate
                event.endDate = Calendar.current.date(byAdding: .day, value: 1, to: endDate) ?? endDate
                event.isAllDay = true
                event.notes = "Arrangører: \(trip.organizers.map { Organizer.fullName(for: $0) }.joined(separator: " & "))"
                event.calendar = eventStore.defaultCalendarForNewEvents

                try eventStore.save(event, span: .thisEvent)
                calendarMessage = "Turen er tilføjet til din kalender."
                showCalendarAlert = true
            } catch {
                calendarMessage = "Kunne ikke tilføje til kalender: \(error.localizedDescription)"
                showCalendarAlert = true
            }
        }
    }
}
