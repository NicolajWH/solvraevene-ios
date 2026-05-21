import SwiftUI
import MapKit

struct TripAnnouncementSection: View {
    let tripDate: String
    let tripEndDate: String?
    let tripTitle: String

    @State private var announcement = TripAnnouncement.empty
    @State private var isLoading = true
    @State private var showEditor = false

    var body: some View {
        Section("Info") {
            if isLoading {
                HStack {
                    ProgressView().scaleEffect(0.8)
                    Text("Henter info…").foregroundStyle(.secondary).font(.subheadline)
                }
            } else if announcement.isEmpty {
                Button {
                    showEditor = true
                } label: {
                    Label("Tilføj info fra formanden", systemImage: "plus.circle")
                }
            } else {
                if !announcement.message.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BESKED FRA FORMANDEN")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(announcement.message)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }

                if !announcement.meetingPlace.isEmpty {
                    Button {
                        openMaps(announcement.meetingPlace)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Mødested")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(announcement.meetingPlace)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                }

                if let dt = announcement.departureDateTime {
                    infoRow(icon: "arrow.right.circle.fill", color: .green,
                            label: "Afgang", value: formatted(dt))
                }
                if let rt = announcement.returnDateTime {
                    infoRow(icon: "arrow.left.circle.fill", color: .orange,
                            label: "Hjemkomst", value: formatted(rt))
                }

                Button {
                    showEditor = true
                } label: {
                    Label("Rediger", systemImage: "pencil")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task { await load() }
        .sheet(isPresented: $showEditor) {
            AnnouncementEditorView(
                tripDate: tripDate,
                tripEndDate: tripEndDate,
                tripTitle: tripTitle,
                announcement: announcement
            ) { updated in
                announcement = updated
            }
        }
    }

    private func load() async {
        isLoading = true
        announcement = (try? await TripAnnouncementService.shared.fetch(for: tripDate)) ?? .empty
        isLoading = false
        await TripAnnouncementService.shared.subscribeIfNeeded(for: tripDate, tripTitle: tripTitle)
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
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.body.weight(.medium))
            }
        }
        .padding(.vertical, 2)
    }
}

struct AnnouncementEditorView: View {
    let tripDate: String
    let tripEndDate: String?
    let tripTitle: String
    let initial: TripAnnouncement
    let onSave: (TripAnnouncement) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var message: String
    @State private var meetingPlace: String
    @State private var departureDateTime: Date
    @State private var returnDateTime: Date
    @State private var isSaving = false
    @State private var error: String?

    private let df: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    init(tripDate: String, tripEndDate: String?, tripTitle: String, announcement: TripAnnouncement, onSave: @escaping (TripAnnouncement) -> Void) {
        self.tripDate = tripDate
        self.tripEndDate = tripEndDate
        self.tripTitle = tripTitle
        self.initial = announcement
        self.onSave = onSave
        _message = State(initialValue: announcement.message)
        _meetingPlace = State(initialValue: announcement.meetingPlace)

        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let startBase = f.date(from: tripDate) ?? Date()
        let endBase = tripEndDate.flatMap { f.date(from: $0) } ?? startBase

        _departureDateTime = State(initialValue: announcement.departureDateTime ?? startBase)
        _returnDateTime = State(initialValue: announcement.returnDateTime ?? endBase)
    }

    var tripStartDate: Date { df.date(from: tripDate) ?? Date() }

    var body: some View {
        NavigationStack {
            Form {
                Section("Besked fra formanden") {
                    TextField("F.eks. husk at pakke støvler!", text: $message, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }

                Section("Mødested") {
                    HStack {
                        Image(systemName: "mappin.circle.fill").foregroundStyle(.red)
                        TextField("F.eks. Nicolajs hjem", text: $meetingPlace)
                    }
                }

                Section("Afgang") {
                    LabeledContent("Dato") {
                        Text(tripStartDate, style: .date)
                            .foregroundStyle(.secondary)
                    }
                    DatePicker("Tidspunkt", selection: $departureDateTime, displayedComponents: .hourAndMinute)
                }

                Section {
                    DatePicker("Dato", selection: $returnDateTime, in: tripStartDate..., displayedComponents: .date)
                    DatePicker("Tidspunkt", selection: $returnDateTime, displayedComponents: .hourAndMinute)
                } header: {
                    Text("Hjemkomst")
                } footer: {
                    Text("Ændr datoen hvis turen slutter tidligere end planlagt.")
                }

                if let error {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle(tripTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuller") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gem") { save() }.disabled(isSaving)
                }
            }
            .overlay { if isSaving { ProgressView() } }
        }
    }

    private func save() {
        isSaving = true
        error = nil
        let updated = TripAnnouncement(
            message: message,
            meetingPlace: meetingPlace,
            departureDateTime: departureDateTime,
            returnDateTime: returnDateTime,
            recordID: initial.recordID
        )
        Task {
            do {
                let saved = try await TripAnnouncementService.shared.save(updated, for: tripDate)
                onSave(saved)
                dismiss()
            } catch {
                self.error = "Kunne ikke gemme. Prøv igen."
            }
            isSaving = false
        }
    }
}
