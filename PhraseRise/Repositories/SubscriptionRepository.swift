import Foundation
import SwiftData

@MainActor
final class SubscriptionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func loadOrCreate() -> SubscriptionState {
        if let existing = (try? context.fetch(FetchDescriptor<SubscriptionState>()))?.first {
            return existing
        }

        let subscription = SubscriptionState()
        context.insert(subscription)
        save()
        return subscription
    }

    func save(_ subscription: SubscriptionState) {
        _ = subscription
        save()
    }

    private func save() {
        try? context.save()
    }
}
