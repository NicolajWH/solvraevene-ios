import SwiftUI

struct OrganizerAvatar: View {
    let initials: String
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(Self.color(for: initials).gradient)
            Text(initials)
                .font(.system(size: size * 0.36, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }

    static func color(for initials: String) -> Color {
        switch initials {
        case "DM":  return Color(red: 0.11, green: 0.63, blue: 0.76)
        case "NWH": return Color(red: 0.35, green: 0.34, blue: 0.84)
        case "MC":  return Color(red: 0.18, green: 0.65, blue: 0.32)
        case "MSA": return Color(red: 0.90, green: 0.49, blue: 0.13)
        case "PHA": return Color(red: 0.85, green: 0.23, blue: 0.30)
        case "MR":  return Color(red: 0.62, green: 0.20, blue: 0.80)
        default:
            let hue = Double(initials.unicodeScalars.reduce(0) { ($0 + Int($1.value)) % 360 }) / 360.0
            return Color(hue: hue, saturation: 0.65, brightness: 0.75)
        }
    }
}
