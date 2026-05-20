import SwiftUI

struct OrganizerAvatar: View {
    let initials: String
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28)
                .fill(Self.color(for: initials).gradient)
                .shadow(color: Self.color(for: initials).opacity(0.35), radius: size * 0.18, x: 0, y: size * 0.06)
            Text(initials)
                .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }

    static func color(for initials: String) -> Color {
        switch initials {
        case "DM":  return Color(red: 0.12, green: 0.53, blue: 0.72)
        case "NWH": return Color(red: 0.33, green: 0.31, blue: 0.76)
        case "MC":  return Color(red: 0.15, green: 0.58, blue: 0.28)
        case "MSA": return Color(red: 0.86, green: 0.45, blue: 0.14)
        case "PHA": return Color(red: 0.80, green: 0.20, blue: 0.24)
        case "MR":  return Color(red: 0.55, green: 0.18, blue: 0.76)
        default:
            let hue = Double(initials.unicodeScalars.reduce(0) { ($0 + Int($1.value)) % 360 }) / 360.0
            return Color(hue: hue, saturation: 0.65, brightness: 0.75)
        }
    }
}
