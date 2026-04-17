import SwiftUI

struct PhraseSummaryCard: View {
    let snapshot: PhraseSnapshot

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(snapshot.phrase.status.tint)
                .frame(width: 10)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(snapshot.phrase.name)
                            .font(AppTypography.cardTitle)
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
                .fill(AppColors.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
        }
    }

    private func statusPill(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(AppTypography.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.85), in: Capsule())
    }

    private func bpmText(_ bpm: Int?) -> String {
        guard let bpm else { return "--" }
        return "\(bpm) BPM"
    }
}
