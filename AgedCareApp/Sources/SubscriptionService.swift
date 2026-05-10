import Foundation
import StoreKit
import Combine

enum SubscriptionTier: String, CaseIterable, Identifiable {
    case starter = "starter"
    case carePro = "care_pro"
    case careTeam = "care_team"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .starter: return "Starter"
        case .carePro: return "Care Pro"
        case .careTeam: return "Care Team"
        }
    }

    var subtitle: String {
        switch self {
        case .starter: return "For family carers"
        case .carePro: return "For individual & professional carers"
        case .careTeam: return "For organizations & care teams"
        }
    }

    var icon: String {
        switch self {
        case .starter: return "heart.circle.fill"
        case .carePro: return "stethoscope"
        case .careTeam: return "building.2.fill"
        }
    }

    var features: [String] {
        switch self {
        case .starter:
            return [
                "Daily routines & reminders",
                "Mood & wellbeing logs",
                "1 care profile",
                "Basic calming activities",
            ]
        case .carePro:
            return [
                "Everything in Starter",
                "Unlimited care profiles",
                "Weekly caregiver summaries",
                "Exportable PDF reports",
                "Shared care notes",
                "Premium activity packs",
                "Smart reminder templates",
            ]
        case .careTeam:
            return [
                "Everything in Care Pro",
                "Multi-user staff access",
                "Staff activity reporting",
                "Shared care plans",
                "Onboarding support",
                "Admin dashboard",
                "Priority support",
            ]
        }
    }

    var priceDisplay: String {
        switch self {
        case .starter: return "Free"
        case .carePro: return "$9.99/mo"
        case .careTeam: return "Custom pricing"
        }
    }

    var productId: String? {
        switch self {
        case .starter: return nil
        case .carePro: return "wcs.Agedcare_shared.care_pro_monthly"
        case .careTeam: return "wcs.Agedcare_shared.care_team_annual"
        }
    }
}

@MainActor
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published var currentTier: SubscriptionTier = .starter
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var planTapCounts: [SubscriptionTier: Int] = [
        .starter: 0, .carePro: 0, .careTeam: 0,
    ]

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        let ids = SubscriptionTier.allCases.compactMap(\.productId)
        do {
            products = try await Product.products(for: Set(ids))
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func purchase(_ tier: SubscriptionTier) async -> Bool {
        guard let productId = tier.productId,
              let product = products.first(where: { $0.id == productId }) else {
            return false
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                purchasedProductIDs.insert(transaction.productID)
                currentTier = tier
                await transaction.finish()
                return true
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchasedProductIDs.insert(transaction.productID)
                if transaction.productID.contains("care_team") {
                    currentTier = .careTeam
                } else if transaction.productID.contains("care_pro") {
                    currentTier = .carePro
                }
            }
        }
    }

    func trackPlanTap(_ tier: SubscriptionTier) {
        planTapCounts[tier, default: 0] += 1
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw SubscriptionError.verificationFailed
        case .verified(let value): return value
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await MainActor.run {
                        self.purchasedProductIDs.insert(transaction.productID)
                    }
                    await transaction.finish()
                }
            }
        }
    }
}

enum SubscriptionError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed: return "Transaction verification failed"
        }
    }
}
