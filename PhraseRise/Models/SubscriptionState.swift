import Foundation
import SwiftData

@Model
final class SubscriptionState {
    @Attribute(.unique) var id: UUID
    var isPremium: Bool
    var productTypeRaw: String
    var purchasedAt: Date?
    var expiresAt: Date?

    init(
        id: UUID = UUID(),
        isPremium: Bool = false,
        productType: SubscriptionProductType = .none,
        purchasedAt: Date? = nil,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.isPremium = isPremium
        self.productTypeRaw = productType.rawValue
        self.purchasedAt = purchasedAt
        self.expiresAt = expiresAt
    }

    var productType: SubscriptionProductType {
        get { SubscriptionProductType(rawValue: productTypeRaw) ?? .none }
        set { productTypeRaw = newValue.rawValue }
    }
}
