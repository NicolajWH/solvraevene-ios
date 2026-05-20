import SwiftUI

struct PairMatrixView: View {
    let people: [String]
    let pairs: [String: [String: Int]]

    private var maxCount: Int {
        pairs.values.flatMap { $0.values }.max() ?? 1
    }

    private let cellSpacing: CGFloat = 4
    private let cellSize: CGFloat = 38

    var body: some View {
        VStack(spacing: cellSpacing) {
            // Header row
            HStack(spacing: cellSpacing) {
                cornerCell()
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

    private func cornerCell() -> some View {
        Color.clear.frame(width: cellSize, height: 22)
    }

    private func cell(row: String, col: String) -> some View {
        Group {
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
                RoundedRectangle(cornerRadius: 6)
                    .fill(intensity(for: count))
                    .frame(width: cellSize, height: cellSize)
                    .overlay(
                        Text(count == 0 ? "–" : "\(count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(count == 0 ? .secondary : .white)
                    )
            }
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
