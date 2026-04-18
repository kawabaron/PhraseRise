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
        return .blocked(reason: "無料版では練習区間の保存数に上限があります。Premium で無制限に管理できます。")
    }

    func gateRecordingSave(currentCount: Int) -> SubscriptionGate {
        guard !state.isPremium, currentCount >= freeRecordingLimit else {
            return .allowed
        }
        return .blocked(reason: "無料版では演奏録音の保存数に上限があります。録音を貯めて比較するには Premium が必要です。")
    }

    func gateRecordingComparison() -> SubscriptionGate {
        state.isPremium ? .allowed : .blocked(reason: "比較再生は Premium で利用できます。")
    }

    func gateAllTimeStats() -> SubscriptionGate {
        state.isPremium ? .allowed : .blocked(reason: "全期間グラフは Premium で利用できます。")
    }

    func suggestion(
        for bpm: Int,
        resultType: PracticeResultType,
        engine: PracticeSuggestionEngine
    ) -> PracticeSuggestion {
        guard state.isPremium else {
            switch resultType {
            case .stable:
                return PracticeSuggestion(
                    nextStartBpm: max(40, bpm - 1),
                    nextTargetBpm: bpm + 1,
                    note: "無料版の簡易提案です。次回は少しだけ上げて試しましょう。"
                )
            case .barely:
                return PracticeSuggestion(
                    nextStartBpm: bpm,
                    nextTargetBpm: bpm,
                    note: "無料版の簡易提案です。テンポを維持して安定感を固めましょう。"
                )
            case .failed:
                return PracticeSuggestion(
                    nextStartBpm: max(40, bpm - 3),
                    nextTargetBpm: max(40, bpm - 1),
                    note: "無料版の簡易提案です。少し落として弾き直しましょう。"
                )
            }
        }

        return engine.makeSuggestion(from: bpm, resultType: resultType)
    }

    func enablePremiumDemo(productType: SubscriptionProductType = .lifetime) {
        let state = self.state
        state.isPremium = true
        state.productType = productType
        state.purchasedAt = .now
        state.expiresAt = productType == .monthly ? Calendar.current.date(byAdding: .month, value: 1, to: .now) : nil
        subscriptionRepository.save(state)
    }

    func restoreFreeDemo() {
        let state = self.state
        state.isPremium = false
        state.productType = .none
        state.purchasedAt = nil
        state.expiresAt = nil
        subscriptionRepository.save(state)
    }
}
