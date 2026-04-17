import SwiftUI

struct PhraseSummaryCard: View {
    let snapshot: PhraseSnapshot

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(snapshot.phrase.status.tint)
                .frame(width: 8)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(snapshot.phrase.name)
                            .font(AppTypography.cardTitle)
                        Text(snapshot.song.title)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Spacer()

                    if snapshot.hasRecording {
                        Label("演奏録音あり", systemImage: "waveform.badge.mic")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.accent)
                    }
                }

                HStack {
                    metric(title: "前回 stable", value: bpmText(snapshot.phrase.lastStableBpm))
                    Spacer()
                    metric(title: "次回開始", value: bpmText(snapshot.phrase.recommendedStartBpm))
                    Spacer()
                    metric(title: "最終練習", value: Formatting.relativeDate(snapshot.latestRecord?.practicedAt))
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                .fill(AppColors.surfaceRaised)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
        }
    }

    private func bpmText(_ bpm: Int?) -> String {
        guard let bpm else { return "--" }
        return "\(bpm)"
    }
}
