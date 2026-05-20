import SwiftUI

struct PairMatrixView: View {
    let people: [String]
    let pairs: [String: [String: Int]]
    let onTap: (_ a: String, _ b: String) -> Void

    private var maxCount: Int {
        pairs.values.flatMap { $0.values }.max() ?? 1
    }

    private var minNonZeroCount: Int {
        let all = pairs.values.flatMap { $0.values }.filter { $0 > 0 }
        return all.min() ?? 0
    }

    private let cellSpacing: CGFloat = 4
    private let cellSize: CGFloat = 38

    var body: some View {
        VStack(spacing: cellSpacing) {
            // Header row
            HStack(spacing: cellSpacing) {
                Color.clear.frame(width: cellSize, height: 22)
                ForEach(people, id: \.self) { p in
                    Text(p)
                        .font(.caption2.weight(.semibold))
                        .frame(width: cellSize, height: 22)
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(people, id: \.self) { row in
                HStack(spacing: cellSpacing) {
                    Text(row)
                        .font(.caption2.weight(.semibold))
                        .frame(width: cellSize, height: cellSize, alignment: .trailing)
                        .foregroundStyle(.secondary)

                    ForEach(people, id: \.self) { col in
                        cell(row: row, col: col)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func cell(row: String, col: String) -> some View {
        if row == col {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(uiColor: .tertiarySystemFill))
                .frame(width: cellSize, height: cellSize)
                .overlay(
                    Image(systemName: "minus")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                )
        } else {
            let count = pairs[row]?[col] ?? 0
            let needsCatchup = count > 0 && count == minNonZeroCount

            Button {
                onTap(row, col)
            } label: {
                RoundedRectangle(cornerRadius: 6)
                    .fill(intensity(for: count))
                    .frame(width: cellSize, height: cellSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.orange, lineWidth: needsCatchup ? 2 : 0)
                    )
                    .overlay(
                        Text(count == 0 ? "–" : "\(count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(count == 0 ? Color.white.opacity(0.35) : Color.white)
                    )
            }
            .buttonStyle(.plain)
            .disabled(count == 0)
        }
    }

    private func intensity(for count: Int) -> Color {
        guard count > 0, maxCount > 0 else {
            return Color(uiColor: .tertiarySystemFill)
        }
        let ratio = Double(count) / Double(maxCount)
        let opacity = 0.30 + ratio * 0.55
        return Color.accentColor.opacity(opacity)
    }
}
