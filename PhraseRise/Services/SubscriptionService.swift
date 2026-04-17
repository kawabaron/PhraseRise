import Foundation

enum SubscriptionGate {
    case allowed
    case blocked(reason: String)
}

@MainActor
final class SubscriptionService {
    private let subscriptionRepository: SubscriptionRepository
    let freePhraseLimit = 6
    let freeRecordingLimit = 12

    init(subscriptionRepository: SubscriptionRepository) {
        self.subscriptionRepository = subscriptionRepository
    }

    var state: SubscriptionState {
        subscriptionRepository.loadOrCreate()
    }

    func gatePhraseCreation(currentCount: Int) -> SubscriptionGate {
        guard !state.isPremium, currentCount >= freePhraseLimit else {
            return .allowed
        }
        return .blocked(reason: "無料版では Phrase 保存数に上限があります。")
    }

    func gateRecordingSave(currentCount: Int) -> SubscriptionGate {
        guard !state.isPremium, currentCount >= freeRecordingLimit else {
            return .allowed
        }
        return .blocked(reason: "無料版では演奏録音の保存数に上限があります。")
    }
}
