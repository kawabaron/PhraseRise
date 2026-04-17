import SwiftUI

struct PhraseSummaryCard: View {
    let snapshot: PhraseSnapshot

    var body: some View {
        StudioCard(emphasisColor: snapshot.phrase.status.tint) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(snapshot.phrase.name)
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(AppColors.textPrimary)
                        Text(snapshot.song.title)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        statusPill(snapshot.phrase.status.label, tint: snapshot.phrase.status.tint)
                        if snapshot.hasRecording {
                            Label("演奏録音あり", systemImage: "waveform.badge.mic")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.accent)
                        }
                    }
                }

                HStack(alignment: .top, spacing: AppSpacing.small) {
                    metric(title: "前回 stable", value: bpmText(snapshot.phrase.lastStableBpm))
                    Spacer(minLength: 0)
                    metric(title: "次回開始", value: bpmText(snapshot.phrase.recommendedStartBpm))
                    Spacer(minLength: 0)
                    metric(title: "最終練習", value: Formatting.relativeDate(snapshot.latestRecord?.practicedAt))
                }
            }
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
        }
    }

    private func statusPill(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(AppTypography.eyebrow)
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tint.opacity(0.16), in: Capsule())
            .overlay(
                Capsule().stroke(tint.opacity(0.35), lineWidth: 1)
            )
    }

    private func bpmText(_ bpm: Int?) -> String {
        guard let bpm else { return "--" }
        return "\(bpm) BPM"
    }
}
