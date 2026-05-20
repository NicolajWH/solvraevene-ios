import SwiftUI

struct OrganizerAvatar: View {
    let initials: String
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(Self.color(for: initials))
            Text(initials)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }

    static func color(for initials: String) -> Color {
        let palette: [Color] = [
            Color(red: 0.40, green: 0.44, blue: 0.78),
            Color(red: 0.22, green: 0.60, blue: 0.42),
            Color(red: 0.82, green: 0.44, blue: 0.18),
            Color(red: 0.58, green: 0.24, blue: 0.70),
            Color(red: 0.18, green: 0.58, blue: 0.74),
            Color(red: 0.78, green: 0.24, blue: 0.34),
        ]
        let hash = initials.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[hash % palette.count]
    }
}
