import SwiftUI

struct SongDetailView: View {
    let dependencies: AppDependencies
    @State private var viewModel: SongDetailViewModel

    init(song: Song, dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: SongDetailViewModel(song: song, dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                StudioCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(viewModel.song.title)
                            .font(AppTypography.screenTitle)
                        Text(viewModel.song.artistName ?? viewModel.song.sourceType.label)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textSecondary)

                        WaveformPlaceholderView(
                            values: viewModel.waveformValues,
                            selection: 0.22 ... 0.40
                        )
                        .frame(height: 180)

                        HStack {
                            Label("\(viewModel.phrases.count) Phrase", systemImage: "rectangle.split.3x1")
                            Spacer()
                            Label(Formatting.duration(viewModel.song.durationSec), systemImage: "clock")
                        }
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    }
                }

                StudioSectionHeader("フレーズ")
                ForEach(viewModel.phrases, id: \.id) { phrase in
                    StudioCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(phrase.name)
                                    .font(AppTypography.cardTitle)
                                Spacer()
                                Text(phrase.status.label)
                                    .font(AppTypography.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(phrase.status.tint.opacity(0.18), in: Capsule())
                            }

                            Text("\(Formatting.duration(phrase.startTimeSec)) - \(Formatting.duration(phrase.endTimeSec))")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)

                            HStack {
                                NavigationLink("詳細") {
                                    PhraseDetailView(phrase: phrase, song: viewModel.song, dependencies: dependencies)
                                }
                                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceRaised))

                                NavigationLink("編集") {
                                    PhraseEditorView(song: viewModel.song, phrase: phrase)
                                }
                                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accentMuted))

                                NavigationLink("練習") {
                                    PracticePlayerView(phrase: phrase, song: viewModel.song, dependencies: dependencies)
                                }
                                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, 120)
        }
        .navigationTitle("Song Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
