import SwiftUI
import NimbleScience

struct ScienceView: View {
    let roomType: String
    let itemCount: Int
    let categorizedCount: Int

    private let provider = ScienceContentProvider()

    private var sections: [ScienceSection] {
        provider.sections(roomType: roomType, itemCount: itemCount)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Motivational header
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundStyle(.indigo)
                    Text("Here Comes the Science")
                        .font(.title2.bold())
                    Text(provider.motivationalSummary(itemCount: itemCount, categorizedCount: categorizedCount))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()

                // Science sections
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: section.icon)
                                .foregroundStyle(.indigo)
                            Text(section.title)
                                .font(.headline)
                        }
                        .padding(.horizontal)

                        // Health findings
                        ForEach(section.findings) { finding in
                            FindingCard(finding: finding)
                        }

                        // Biological risks
                        ForEach(section.risks) { risk in
                            RiskCard(risk: risk)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("The Science")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Finding Card

private struct FindingCard: View {
    let finding: HealthFinding
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: finding.category.icon)
                    .foregroundStyle(severityColor)
                    .font(.caption)
                Text(finding.title)
                    .font(.subheadline.bold())
                Spacer()
                SeverityBadge(level: finding.severity)
            }

            Text(finding.summary)
                .font(.caption)
                .foregroundStyle(.secondary)

            if isExpanded {
                Text(finding.detail)
                    .font(.caption)
                    .padding(.top, 4)
                Text(finding.citation)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .italic()
                    .padding(.top, 2)
            }

            Button(isExpanded ? "Show Less" : "Read More") {
                withAnimation { isExpanded.toggle() }
            }
            .font(.caption2)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var severityColor: Color {
        switch finding.severity {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .severe: return .red
        }
    }
}

// MARK: - Risk Card

private struct RiskCard: View {
    let risk: BiologicalRisk
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: risk.riskType.icon)
                    .foregroundStyle(severityColor)
                    .font(.caption)
                Text(risk.title)
                    .font(.subheadline.bold())
                Spacer()
                SeverityBadge(level: risk.severity)
            }

            Text(risk.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Label {
                        Text(risk.conditions)
                            .font(.caption)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Label {
                        Text(risk.prevention)
                            .font(.caption)
                    } icon: {
                        Image(systemName: "checkmark.shield")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                .padding(.top, 4)
            }

            Button(isExpanded ? "Show Less" : "Details & Prevention") {
                withAnimation { isExpanded.toggle() }
            }
            .font(.caption2)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var severityColor: Color {
        switch risk.severity {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .severe: return .red
        }
    }
}

// MARK: - Severity Badge

private struct SeverityBadge: View {
    let level: RiskLevel

    var body: some View {
        Text(level.rawValue.uppercased())
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch level {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .severe: return .red
        }
    }
}
