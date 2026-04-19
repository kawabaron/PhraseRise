import SwiftUI

struct PhraseDetailView: View {
    let dependencies: AppDependencies
    @State private var viewModel: PhraseDetailViewModel

    init(phrase: Phrase, song: Song, dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: PhraseDetailViewModel(phrase: phrase, song: song, dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection

                practiceButton
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.large)

                metricsList
                    .padding(.top, AppSpacing.xLarge)

                historySection
                    .padding(.top, AppSpacing.xLarge)

                recordingsRow
                    .padding(.top, AppSpacing.xLarge)
            }
            .padding(.bottom, 120)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .studioScreen()
        .task {
            viewModel.refresh()
        }
        .onDisappear {
            viewModel.stopPlayback()
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.song.title.uppercased())
                    .font(AppTypography.eyebrow)
                    .tracking(2)
                    .foregroundStyle(AppColors.textMuted)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Circle()
                        .fill(viewModel.phrase.status.tint)
                        .frame(width: 10, height: 10)

                    Text(viewModel.phrase.name)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(2)
                }

                Text(viewModel.phrase.status.label)
                    .font(AppTypography.caption)
                    .foregroundStyle(viewModel.phrase.status.tint)
            }

            HStack(spacing: 12) {
                heroPill(
                    label: "範囲",
                    value: "\(Formatting.duration(viewModel.phrase.startTimeSec)) – \(Formatting.duration(viewModel.phrase.endTimeSec))"
                )
                Spacer(minLength: 0)

                ProgressPlayButton(
                    isPlaying: viewModel.isPlaying,
                    progress: viewModel.progress,
                    size: 44
                ) {
                    viewModel.togglePlayback()
                }
            }

            if let memo = viewModel.phrase.memo, !memo.isEmpty {
                Text(memo)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.medium)
        .padding(.bottom, AppSpacing.large)
        .background(
            RadialGradient(
                colors: [
                    viewModel.phrase.status.tint.opacity(0.22),
                    Color.clear
                ],
                center: UnitPoint(x: 0.1, y: 0.0),
                startRadius: 10,
                endRadius: 380
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    private func heroPill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppTypography.eyebrow)
                .tracking(1)
                .foregroundStyle(AppColors.textMuted)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.surface.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    // MARK: - Practice CTA & suggestion

    private var practiceButton: some View {
        NavigationLink {
            PracticePlayerView(phrase: viewModel.phrase, song: viewModel.song, dependencies: dependencies)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("練習をはじめる")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
            }
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.accent)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Metrics

    private var metricsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionEyebrow("成績")

            metricRow("練習時間", value: "\(viewModel.totalPracticeMinutes)分", valueTint: AppColors.textPrimary)
        }
    }

    private func metricRow(_ label: String, value: String, valueTint: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(valueTint)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, 14)
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionEyebrow("練習履歴")

            if viewModel.practiceRecords.isEmpty {
                Text("まだ練習記録がありません。")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.vertical, AppSpacing.large)
            } else {
                let records = Array(viewModel.practiceRecords.prefix(6))
                ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                    practiceRow(record)
                    if index < records.count - 1 {
                        hairline
                    }
                }
            }
        }
    }

    private func practiceRow(_ record: PracticeRecord) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(record.resultType.tint)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(Formatting.date(record.practicedAt))
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)

                HStack(spacing: 6) {
                    Text(record.resultType.label)
                        .foregroundStyle(record.resultType.tint)
                    Text("·")
                    Text("\(record.practiceDurationSec / 60)分")
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
                .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Recordings link

    private var recordingsRow: some View {
        NavigationLink {
            RecordingListView(phrase: viewModel.phrase, song: viewModel.song, dependencies: dependencies)
        } label: {
            HStack(spacing: 14) {
                Circle()
                    .fill(AppColors.recording)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 3) {
                    Text("演奏録音")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("\(viewModel.recordings.count) 件")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textMuted)
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sectionEyebrow(_ text: String) -> some View {
        Text(text.uppercased())
            .font(AppTypography.eyebrow)
            .tracking(2)
            .foregroundStyle(AppColors.textMuted)
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.bottom, AppSpacing.small)
    }

    private var hairline: some View {
        Rectangle()
            .fill(AppColors.border)
            .frame(height: 0.5)
            .padding(.leading, AppSpacing.screenHorizontal + 22)
    }
}
