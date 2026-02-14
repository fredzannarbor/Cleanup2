import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionService: SubscriptionService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundStyle(.indigo)
                        Text("Cleanup\u{00B2} Premium")
                            .font(.title.bold())
                        Text("Unlock powerful tools to stay organized")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    // Feature list
                    VStack(alignment: .leading, spacing: 12) {
                        featureRow(icon: "arrow.up.arrow.down", title: "Drag to Reorder", description: "Arrange items in any order you want")
                        featureRow(icon: "rectangle.3.group", title: "Autogroup", description: "Automatically group similar items together")
                        featureRow(icon: "camera.metering.spot", title: "State Snapshots", description: "Track progress over time with before/after comparisons")
                        featureRow(icon: "chart.bar.xaxis", title: "Recommendations", description: "Smart suggestions for which rooms to tackle next")
                        featureRow(icon: "brain.head.profile", title: "Here Comes the Science", description: "Research-backed insights on clutter and health")
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Pricing
                    if subscriptionService.isLoading {
                        ProgressView()
                    } else {
                        VStack(spacing: 12) {
                            if let monthly = subscriptionService.product(for: .monthly) {
                                purchaseButton(product: monthly, label: "Monthly", sublabel: monthly.displayPrice + "/month")
                            }
                            if let annual = subscriptionService.product(for: .annual) {
                                purchaseButton(product: annual, label: "Annual", sublabel: annual.displayPrice + "/year")
                                    .overlay(
                                        Text("Best Value")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(.green)
                                            .foregroundStyle(.white)
                                            .clipShape(Capsule())
                                            .offset(x: 0, y: -8),
                                        alignment: .top
                                    )
                            }
                            if let lifetime = subscriptionService.product(for: .lifetime) {
                                purchaseButton(product: lifetime, label: "Lifetime", sublabel: lifetime.displayPrice + " once")
                            }
                        }
                    }

                    if let error = subscriptionService.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button("Restore Purchases") {
                        Task {
                            await subscriptionService.restorePurchases()
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.indigo)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func purchaseButton(product: Product, label: String, sublabel: String) -> some View {
        Button {
            Task {
                _ = try? await subscriptionService.purchase(product)
                if subscriptionService.effectivelyPremium {
                    dismiss()
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(label)
                        .font(.headline)
                    Text(sublabel)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.indigo)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
