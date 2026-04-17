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
                StudioCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(viewModel.song.title)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        Text(viewModel.phrase.name)
                            .font(AppTypography.screenTitle)
                        HStack {
                            metric("前回 stable", viewModel.phrase.lastStableBpm.map { "\($0)" } ?? "--")
                            Spacer()
                            metric("最高 stable", viewModel.phrase.bestStableBpm.map { "\($0)" } ?? "--")
                            Spacer()
                            metric("次回提案", viewModel.phrase.recommendedNextBpm.map { "\($0)" } ?? "--")
                        }
                    }
                }

                StudioSectionHeader("BPM 推移")
                StudioCard {
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

                NavigationLink {
                    RecordingListView(phrase: viewModel.phrase, song: viewModel.song, dependencies: dependencies)
                } label: {
                    StudioCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("演奏録音履歴")
                                    .font(AppTypography.cardTitle)
                                Text("\(viewModel.recordings.count) 件の録音")
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

                NavigationLink {
                    PracticePlayerView(phrase: viewModel.phrase, song: viewModel.song, dependencies: dependencies)
                } label: {
                    Label("PracticePlayer を開く", systemImage: "play.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, 120)
        }
        .navigationTitle("Phrase Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.semibold))
        }
    }
}
