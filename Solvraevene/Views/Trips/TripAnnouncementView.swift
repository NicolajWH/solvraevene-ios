import SwiftUI

struct TripAnnouncementSection: View {
    let tripDate: String
    let tripTitle: String

    @State private var announcement = TripAnnouncement.empty
    @State private var isLoading = true
    @State private var showEditor = false

    var body: some View {
        Section {
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
                        .foregroundStyle(.accentColor)
                }
            } else {
                if !announcement.message.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BESKED FRA FORMANDEN")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(announcement.message)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }
                if !announcement.meetingPlace.isEmpty {
                    infoRow(icon: "mappin.circle", label: "Mødested", value: announcement.meetingPlace)
                }
                if !announcement.departureTime.isEmpty {
                    infoRow(icon: "arrow.right.circle", label: "Afgang", value: announcement.departureTime)
                }
                if !announcement.returnTime.isEmpty {
                    infoRow(icon: "arrow.left.circle", label: "Hjemkomst", value: announcement.returnTime)
                }
                Button {
                    showEditor = true
                } label: {
                    Label("Rediger", systemImage: "pencil")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Info")
        }
        .task {
            await load()
        }
        .sheet(isPresented: $showEditor) {
            AnnouncementEditorView(tripDate: tripDate, tripTitle: tripTitle, announcement: announcement) { updated in
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

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body.weight(.medium))
            }
        }
        .padding(.vertical, 2)
    }
}

struct AnnouncementEditorView: View {
    let tripDate: String
    let tripTitle: String
    let initial: TripAnnouncement
    let onSave: (TripAnnouncement) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var message: String
    @State private var meetingPlace: String
    @State private var departureTime: String
    @State private var returnTime: String
    @State private var isSaving = false
    @State private var error: String?

    init(tripDate: String, tripTitle: String, announcement: TripAnnouncement, onSave: @escaping (TripAnnouncement) -> Void) {
        self.tripDate = tripDate
        self.tripTitle = tripTitle
        self.initial = announcement
        self.onSave = onSave
        _message = State(initialValue: announcement.message)
        _meetingPlace = State(initialValue: announcement.meetingPlace)
        _departureTime = State(initialValue: announcement.departureTime)
        _returnTime = State(initialValue: announcement.returnTime)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Besked fra formanden") {
                    TextField("F.eks. husk at pakke støvler!", text: $message, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }
                Section("Praktisk info") {
                    LabeledContent("Mødested") {
                        TextField("F.eks. Nicolajs hjem", text: $meetingPlace)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Afgang") {
                        TextField("F.eks. fredag kl. 15:00", text: $departureTime)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Hjemkomst") {
                        TextField("F.eks. søndag ca. 17:00", text: $returnTime)
                            .multilineTextAlignment(.trailing)
                    }
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
                    Button("Gem") { save() }
                        .disabled(isSaving)
                }
            }
            .overlay {
                if isSaving { ProgressView() }
            }
        }
    }

    private func save() {
        isSaving = true
        error = nil
        let updated = TripAnnouncement(
            message: message,
            meetingPlace: meetingPlace,
            departureTime: departureTime,
            returnTime: returnTime,
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
