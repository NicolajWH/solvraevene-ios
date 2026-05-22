import SwiftUI

struct PackingListRoute: Hashable {
    let tripDate: String
    let tripTitle: String
}

struct PackingListView: View {
    let tripDate: String
    let tripTitle: String

    @State private var items: [PackingItem] = []
    @State private var checked: Set<String> = []
    @State private var newItemText = ""
    @State private var isLoading = true
    @State private var error: String?
    @FocusState private var inputFocused: Bool

    private let checkedKey: String

    init(tripDate: String, tripTitle: String) {
        self.tripDate = tripDate
        self.tripTitle = tripTitle
        self.checkedKey = "packing_checked_\(tripDate)"
    }

    private var checkedCount: Int { items.filter { checked.contains($0.id.recordName) }.count }

    var body: some View {
        List {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else if let error {
                Text(error)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                Section {
                    if items.isEmpty {
                        Text("Ingen punkter endnu. Tilføj det første herunder.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }

                    ForEach(items) { item in
                        HStack(spacing: 12) {
                            Button { toggle(item) } label: {
                                Image(systemName: checked.contains(item.id.recordName) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(checked.contains(item.id.recordName) ? Color.accentColor : Color(uiColor: .tertiaryLabel))
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)

                            Text(item.text)
                                .strikethrough(checked.contains(item.id.recordName))
                                .foregroundStyle(checked.contains(item.id.recordName) ? .secondary : .primary)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { delete(item) } label: {
                                Label("Slet", systemImage: "trash")
                            }
                        }
                    }

                    HStack {
                        TextField("Tilføj punkt…", text: $newItemText)
                            .focused($inputFocused)
                            .onSubmit { addItem() }
                        if !newItemText.isEmpty {
                            Button(action: addItem) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } footer: {
                    Text("Flueben er personlige — kun synlige på din enhed.")
                }
            }
        }
        .navigationTitle(items.isEmpty ? "Huskeliste" : "Huskeliste \(checkedCount)/\(items.count)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if checkedCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Nulstil") {
                        checked.removeAll()
                        saveChecked()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            Task { await load() }
        }
    }

    private func load() async {
        guard isLoading else { return }
        do {
            items = try await PackingListService.shared.fetchItems(for: tripDate)
            let stored = UserDefaults.standard.stringArray(forKey: checkedKey) ?? []
            checked = Set(stored)
        } catch {
            self.error = "Kunne ikke hente huskelisten. Tjek din internetforbindelse."
        }
        isLoading = false
    }

    private func addItem() {
        let text = newItemText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        newItemText = ""
        Task {
            do {
                let item = try await PackingListService.shared.addItem(
                    tripDate: tripDate,
                    text: text,
                    order: items.count
                )
                items.append(item)
            } catch {
                self.error = "Kunne ikke tilføje punkt."
            }
        }
    }

    private func delete(_ item: PackingItem) {
        items.removeAll { $0.id == item.id }
        checked.remove(item.id.recordName)
        saveChecked()
        Task { try? await PackingListService.shared.deleteItem(item) }
    }

    private func toggle(_ item: PackingItem) {
        if checked.contains(item.id.recordName) {
            checked.remove(item.id.recordName)
        } else {
            checked.insert(item.id.recordName)
        }
        saveChecked()
    }

    private func saveChecked() {
        UserDefaults.standard.set(Array(checked), forKey: checkedKey)
    }
}
