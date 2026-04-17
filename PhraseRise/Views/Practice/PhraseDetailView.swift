import Charts
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
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                headerCard
                metricsGrid
                suggestionCard
                chartSection
                historySection
                recordingsSection
                practiceButton
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, 120)
        }
        .navigationTitle("Phrase Detail")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.refresh()
        }
    }

    private var headerCard: some View {
        StudioCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.song.title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)

                Text(viewModel.phrase.name)
                    .font(AppTypography.screenTitle)

                if let memo = viewModel.phrase.memo, !memo.isEmpty {
                    Text(memo)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.medium) {
            MetricTile(title: "前回 stable", value: bpmText(viewModel.phrase.lastStableBpm), tint: AppColors.accent)
            MetricTile(title: "最高 stable", value: bpmText(viewModel.phrase.bestStableBpm), tint: AppColors.success)
            MetricTile(title: "stable率", value: "\(viewModel.stableRate)%", tint: AppColors.warning)
            MetricTile(title: "練習時間", value: "\(viewModel.totalPracticeMinutes) 分", tint: AppColors.accentMuted)
        }
    }

    private var suggestionCard: some View {
        StudioCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("次回提案", systemImage: "arrow.up.forward.circle.fill")
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.accent)

                Text(viewModel.nextSuggestionSummary)
                    .font(AppTypography.body)

                if !viewModel.isPremium && viewModel.practiceRecords.count > 8 {
                    Text("無料版では直近の履歴を中心に表示しています。全期間の変化は Premium で確認できます。")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            StudioSectionHeader("BPM 推移")
            StudioCard {
                if viewModel.chartPoints.isEmpty {
                    Text("PracticeRecord を保存するとグラフが表示されます。")
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Chart(viewModel.chartPoints) { point in
                        LineMark(
                            x: .value("Date", point.label),
                            y: .value("BPM", point.bpm)
                        )
                        .foregroundStyle(AppColors.accent)

                        PointMark(
                            x: .value("Date", point.label),
                            y: .value("BPM", point.bpm)
                        )
                        .foregroundStyle(AppColors.success)
                    }
                    .frame(height: 220)
                }
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            StudioSectionHeader("練習履歴")

            if viewModel.practiceRecords.isEmpty {
                StudioCard {
                    Text("まだ練習記録がありません。PracticePlayer から記録してみましょう。")
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(viewModel.practiceRecords.prefix(8), id: \.id) { record in
                    StudioCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("\(record.triedBpm) BPM")
                                    .font(AppTypography.cardTitle)
                                Spacer()
                                Text(record.resultType.label)
                                    .font(AppTypography.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(record.resultType.tint.opacity(0.2), in: Capsule())
                            }

                            HStack {
                                Label(Formatting.date(record.practicedAt), systemImage: "calendar")
                                Spacer()
                                Label("\(record.practiceDurationSec / 60) 分", systemImage: "clock")
                            }
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)

                            if let notes = record.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var recordingsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            StudioSectionHeader("演奏録音")

            NavigationLink {
                RecordingListView(phrase: viewModel.phrase, song: viewModel.song, dependencies: dependencies)
            } label: {
                StudioCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("録音一覧を開く")
                                .font(AppTypography.cardTitle)
                            Text("\(viewModel.recordings.count) 件の演奏録音")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var practiceButton: some View {
        NavigationLink {
            PracticePlayerView(phrase: viewModel.phrase, song: viewModel.song, dependencies: dependencies)
        } label: {
            Label("PracticePlayer を開く", systemImage: "play.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))
    }

    private func bpmText(_ bpm: Int?) -> String {
        bpm.map { "\($0) BPM" } ?? "--"
    }
}
