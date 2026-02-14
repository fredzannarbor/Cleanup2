import StoreKit
import SwiftUI

// MARK: - Product Identifiers

enum Cleanup2Product: String, CaseIterable {
    case monthly = "com.nimblebooks.Cleanup2.monthly"
    case annual = "com.nimblebooks.Cleanup2.annual"
    case lifetime = "com.nimblebooks.Cleanup2.lifetime"

    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        case .lifetime: return "Lifetime"
        }
    }

    var isSubscription: Bool {
        self != .lifetime
    }
}

// MARK: - Subscription Service

@MainActor
class SubscriptionService: ObservableObject {

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPremium: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Debug override: dev mode from NimbleKit pattern + debug force
    @AppStorage("fz_dev_mode") private var devMode = false
    static var debugForcePremium = false

    var effectivelyPremium: Bool {
        isPremium || (devMode && Self.debugForcePremium)
    }

    private let productIDs: Set<String> = Set(Cleanup2Product.allCases.map(\.rawValue))
    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await checkEntitlements()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        do {
            let loaded = try await Product.products(for: productIDs)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("[SubscriptionService] Failed to load products: \(error)")
        }
        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await checkEntitlements()
                await transaction.finish()
                isLoading = false
                return transaction
            case .userCancelled:
                isLoading = false
                return nil
            case .pending:
                isLoading = false
                errorMessage = "Purchase is pending approval"
                return nil
            @unknown default:
                isLoading = false
                return nil
            }
        } catch {
            isLoading = false
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Entitlements

    func checkEntitlements() async {
        var hasPremium = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if productIDs.contains(transaction.productID) {
                    hasPremium = true
                }
            }
        }
        isPremium = hasPremium
    }

    // MARK: - Helpers

    func product(for type: Cleanup2Product) -> Product? {
        products.first { $0.id == type.rawValue }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in StoreKit.Transaction.updates {
                if case .verified(let transaction) = result {
                    await self?.checkEntitlements()
                    await transaction.finish()
                }
            }
        }
    }

    #if DEBUG
    func toggleDebugPremium() {
        Self.debugForcePremium.toggle()
        objectWillChange.send()
        print("[SubscriptionService] Debug Premium: \(Self.debugForcePremium ? "ENABLED" : "disabled")")
    }
    #endif
}

// MARK: - Errors

enum SubscriptionError: Error, LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        }
    }
}
