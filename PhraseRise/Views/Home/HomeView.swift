import SwiftUI

struct HomeView: View {
    let dependencies: AppDependencies
    @State private var viewModel: HomeViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: HomeViewModel(dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                focusHeader
                todaySection
                recentPhraseSection
                recentRecordingSection
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, 120)
        }
        .navigationTitle("PhraseRise")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .studioScreen()
        .task {
            viewModel.refresh()
        }
    }

    private var focusHeader: some View {
        StudioCard(emphasisColor: AppColors.accent) {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("TODAY FOCUS")
                    .font(AppTypography.eyebrow)
                    .foregroundStyle(AppColors.textSecondary)

                if let snapshot = viewModel.todayPhrases.first {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(snapshot.phrase.name)
                            .font(AppTypography.screenTitle)
                        Text(snapshot.song.title)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    HStack {
                        overviewMetric(title: "今日やる", value: "\(viewModel.todayPhrases.count)")
                        overviewMetric(title: "最近練習", value: "\(viewModel.recentPhrases.count)")
                        overviewMetric(title: "録音", value: "\(viewModel.recentRecordings.count)")
                    }

                    NavigationLink {
                        PracticePlayerView(phrase: snapshot.phrase, song: snapshot.song, dependencies: dependencies)
                    } label: {
                        Label("このフレーズから始める", systemImage: "play.circle.fill")
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))
                } else {
                    Text("練習音源を追加して Phrase を作ると、ここからすぐ練習を始められます。")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)

                    HStack {
                        overviewMetric(title: "今日やる", value: "0")
                        overviewMetric(title: "最近練習", value: "0")
                        overviewMetric(title: "録音", value: "0")
                    }
                }
            }
        }
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            StudioSectionHeader("今日やるフレーズ", subtitle: "次回練習日と最近の進捗を見ながら入れます。")

            if viewModel.todayPhrases.isEmpty {
                emptyCard("まだ Phrase がありません。Songs から練習音源を追加して、難所フレーズを切り出しましょう。")
            } else {
                ForEach(viewModel.todayPhrases.prefix(4)) { snapshot in
                    NavigationLink {
                        PhraseDetailView(phrase: snapshot.phrase, song: snapshot.song, dependencies: dependencies)
                    } label: {
                        PhraseSummaryCard(snapshot: snapshot)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recentPhraseSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            StudioSectionHeader("最近練習したフレーズ")

            if viewModel.recentPhrases.isEmpty {
                emptyCard("練習履歴が入ると、最近触ったフレーズがここに並びます。")
            } else {
                ForEach(viewModel.recentPhrases) { snapshot in
                    NavigationLink {
                        PracticePlayerView(phrase: snapshot.phrase, song: snapshot.song, dependencies: dependencies)
                    } label: {
                        PhraseSummaryCard(snapshot: snapshot)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recentRecordingSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            StudioSectionHeader("最近録音した演奏")

            if viewModel.recentRecordings.isEmpty {
                emptyCard("PracticePlayer で演奏を録音すると、ここからすぐ聞き返せます。")
            } else {
                ForEach(viewModel.recentRecordings) { snapshot in
                    StudioCard(emphasisColor: AppColors.recording) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(snapshot.phraseName)
                                        .font(AppTypography.cardTitle)
                                    Text(snapshot.songTitle)
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColors.textSecondary)
                                }

                                Spacer()

                                Text("\(snapshot.recording.bpmAtRecording ?? 0) BPM")
                                    .font(.system(.headline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(AppColors.accent)
                            }

                            HStack {
                                Label(Formatting.date(snapshot.recording.recordedAt), systemImage: "calendar")
                                Spacer()
                                Label(Formatting.duration(snapshot.recording.durationSec), systemImage: "clock")
                            }
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private func overviewMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            Text(value)
                .font(AppTypography.heroMetric)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func emptyCard(_ message: String) -> some View {
        StudioCard {
            Text(message)
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
