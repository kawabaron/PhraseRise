import Foundation
import Observation

@Observable
@MainActor
final class PaywallViewModel {
    private let subscriptionService: SubscriptionService

    var subscription: SubscriptionState

    init(dependencies: AppDependencies) {
        subscriptionService = dependencies.subscriptionService
        subscription = dependencies.subscriptionService.state
    }

    func upgradeToPremium() {
        subscriptionService.enablePremiumDemo(productType: .lifetime)
        subscription = subscriptionService.state
    }

    func restoreFree() {
        subscriptionService.restoreFreeDemo()
        subscription = subscriptionService.state
    }
}
