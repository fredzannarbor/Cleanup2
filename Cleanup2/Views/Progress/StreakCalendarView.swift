import SwiftUI
import Charts

struct StreakCalendarView: View {
    let dailyCounts: [(date: Date, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cleaning Activity")
                .font(.headline)

            if dailyCounts.isEmpty {
                Text("No activity yet. Complete some cleaning tasks!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(dailyCounts, id: \.date) { entry in
                    BarMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("Tasks", entry.count)
                    )
                    .foregroundStyle(Color.indigo.gradient)
                    .cornerRadius(2)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 120)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
