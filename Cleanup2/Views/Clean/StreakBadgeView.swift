import SwiftUI

struct StreakBadgeView: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: streak > 0 ? "flame.fill" : "flame")
                .foregroundStyle(streak > 0 ? .orange : .gray)
            Text("\(streak)")
                .font(.title2)
                .fontWeight(.bold)
            Text(streak == 1 ? "day" : "days")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(streak > 0 ? Color.orange.opacity(0.1) : Color.gray.opacity(0.1))
        .clipShape(Capsule())
    }
}
