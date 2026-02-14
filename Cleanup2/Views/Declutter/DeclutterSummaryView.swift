import SwiftUI

struct DeclutterSummaryView: View {
    let roomId: Int64
    let roomName: String
    @EnvironmentObject var declutterManager: DeclutterManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)

                Text("\(roomName) Decluttered!")
                    .font(.title)
                    .fontWeight(.bold)

                VStack(spacing: 12) {
                    SummaryRow(icon: "checkmark.circle.fill", color: .blue, label: "Keep", count: declutterManager.items(for: .keep).count)
                    SummaryRow(icon: "heart.circle.fill", color: .green, label: "Donate", count: declutterManager.items(for: .donate).count)
                    SummaryRow(icon: "trash.circle.fill", color: .red, label: "Trash", count: declutterManager.items(for: .trash).count)
                    SummaryRow(icon: "dollarsign.circle.fill", color: .orange, label: "Sell", count: declutterManager.items(for: .sell).count)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Text("Cleaning tasks have been set up for this room. Check the Clean tab!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            declutterManager.loadItems(forRoom: roomId)
        }
    }
}

private struct SummaryRow: View {
    let icon: String
    let color: Color
    let label: String
    let count: Int

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
            Spacer()
            Text("\(count)")
                .fontWeight(.semibold)
        }
    }
}
