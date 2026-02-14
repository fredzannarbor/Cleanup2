import SwiftUI

struct CategoryBadgeView: View {
    let category: ItemCategory

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption2)
            Text(category.label)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(category.color.opacity(0.15))
        .foregroundStyle(category.color)
        .clipShape(Capsule())
    }
}
