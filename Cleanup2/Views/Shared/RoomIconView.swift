import SwiftUI

struct RoomIconView: View {
    let icon: RoomIcon
    var size: CGFloat = 40
    var color: Color = .indigo

    var body: some View {
        Image(systemName: icon.systemImage)
            .font(.system(size: size * 0.5))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
    }
}
