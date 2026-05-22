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
    @FocusState private var inputFocused: Bool

    private var checkedKey: String { "packing_checked_\(tripDate)" }
    private var checkedCount: Int { items.filter { checked.contains($0.id.uuidString) }.count }

    var body: some View {
        List {
            Section {
                if items.isEmpty {
                    Text("Ingen punkter endnu. Tilføj det første herunder.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }

                ForEach(items) { item in
                    HStack(spacing: 12) {
                        Button { toggle(item) } label: {
                            Image(systemName: checked.contains(item.id.uuidString) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(checked.contains(item.id.uuidString) ? Color.accentColor : Color(uiColor: .tertiaryLabel))
                                .font(.title3)
                        }
                        .buttonStyle(.plain)

                        Text(item.text)
                            .strikethrough(checked.contains(item.id.uuidString))
                            .foregroundStyle(checked.contains(item.id.uuidString) ? .secondary : .primary)
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
                Text("Huskelisten gemmes lokalt på din enhed.")
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
        .onAppear { load() }
    }

    private func load() {
        items = PackingListService.loadItems(for: tripDate)
        let stored = UserDefaults.standard.stringArray(forKey: checkedKey) ?? []
        checked = Set(stored)
    }

    private func addItem() {
        let text = newItemText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        newItemText = ""
        let item = PackingItem(text: text, sortOrder: items.count)
        items.append(item)
        PackingListService.saveItems(items, for: tripDate)
    }

    private func delete(_ item: PackingItem) {
        items.removeAll { $0.id == item.id }
        checked.remove(item.id.uuidString)
        saveChecked()
        PackingListService.saveItems(items, for: tripDate)
    }

    private func toggle(_ item: PackingItem) {
        if checked.contains(item.id.uuidString) {
            checked.remove(item.id.uuidString)
        } else {
            checked.insert(item.id.uuidString)
        }
        saveChecked()
    }

    private func saveChecked() {
        UserDefaults.standard.set(Array(checked), forKey: checkedKey)
    }
}
