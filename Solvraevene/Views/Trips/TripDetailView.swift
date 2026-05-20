import SwiftUI
import EventKit

struct TripDetailView: View {
    let trip: Trip

    @State private var calendarMessage: String?
    @State private var showCalendarAlert = false

    var body: some View {
        List {
            Section {
                LabeledContent("Dato", value: trip.formattedDateRange)
                if let location = trip.location {
                    LabeledContent("Lokation", value: location)
                }
            }

            Section("Arrangører") {
                ForEach(trip.organizers, id: \.self) { initials in
                    Text(Organizer.fullName(for: initials))
                }
            }

            if let urlString = trip.photoAlbumURL, let url = URL(string: urlString) {
                Section {
                    Link(destination: url) {
                        Label("Se billeder fra turen", systemImage: "photo.stack")
                    }
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
        .navigationTitle(trip.location ?? trip.formattedDate)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Kalender", isPresented: $showCalendarAlert) {
            Button("OK") {}
        } message: {
            Text(calendarMessage ?? "")
        }
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
                event.title = trip.location.map { "Sølvrævene – \($0)" } ?? "Sølvrævene"
                event.startDate = startDate
                // All-day end date is exclusive, so add one day
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
