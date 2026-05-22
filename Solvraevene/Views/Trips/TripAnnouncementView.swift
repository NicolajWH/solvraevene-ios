import SwiftUI

struct TripAnnouncementSection: View {
    let announcement: TripAnnouncement?

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
            } else {
                Text("Ingen info endnu — opdateres i trips.json")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
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
