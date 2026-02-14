import SwiftUI
import Charts

struct DeclutterProgressChart: View {
    let rooms: [Room]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Room Progress")
                .font(.headline)

            Chart(rooms) { room in
                BarMark(
                    x: .value("Progress", room.declutterProgress),
                    y: .value("Room", room.name)
                )
                .foregroundStyle(room.isDecluttered ? Color.green : Color.indigo)
                .cornerRadius(4)
            }
            .chartXScale(domain: 0...1)
            .chartXAxis {
                AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v * 100))%")
                        }
                    }
                }
            }
            .frame(height: CGFloat(rooms.count) * 40 + 20)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
