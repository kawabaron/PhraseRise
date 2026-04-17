import Foundation

struct PracticeSuggestion {
    let nextStartBpm: Int
    let nextTargetBpm: Int
    let note: String
}

@MainActor
struct PracticeSuggestionEngine {
    func makeSuggestion(from bpm: Int, resultType: PracticeResultType) -> PracticeSuggestion {
        switch resultType {
        case .stable:
            return PracticeSuggestion(nextStartBpm: max(40, bpm - 2), nextTargetBpm: bpm + 2, note: "安定して弾けています。次回は少しだけテンポを上げましょう。")
        case .barely:
            return PracticeSuggestion(nextStartBpm: bpm, nextTargetBpm: bpm + 1, note: "今のテンポを維持しつつ、最後の精度を固めましょう。")
        case .failed:
            return PracticeSuggestion(nextStartBpm: max(40, bpm - 4), nextTargetBpm: max(40, bpm - 1), note: "少し落として、手順と脱力を優先して再構築しましょう。")
        }
    }
}
