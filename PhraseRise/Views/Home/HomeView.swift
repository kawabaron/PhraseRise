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
                StudioSectionHeader("今日やるフレーズ", subtitle: "起動したらすぐ練習に入れる導線を優先")

                if viewModel.todayPhrases.isEmpty {
                    StudioCard {
                        Text("まだ Phrase がありません。Songs から練習音源を追加しましょう。")
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    ForEach(viewModel.todayPhrases) { snapshot in
                        NavigationLink {
                            PhraseDetailView(phrase: snapshot.phrase, song: snapshot.song, dependencies: dependencies)
                        } label: {
                            PhraseSummaryCard(snapshot: snapshot)
                        }
                        .buttonStyle(.plain)
                    }
                }

                StudioSectionHeader("最近練習したフレーズ")
                ForEach(viewModel.recentPhrases) { snapshot in
                    NavigationLink {
                        PracticePlayerView(phrase: snapshot.phrase, song: snapshot.song, dependencies: dependencies)
                    } label: {
                        PhraseSummaryCard(snapshot: snapshot)
                    }
                    .buttonStyle(.plain)
                }

                StudioSectionHeader("最近録音した演奏")
                ForEach(viewModel.recentRecordings) { snapshot in
                    StudioCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(snapshot.phraseName)
                                    .font(AppTypography.cardTitle)
                                Spacer()
                                Text("\(snapshot.recording.bpmAtRecording ?? 0) BPM")
                                    .font(.system(.headline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(AppColors.accent)
                            }

                            Text(snapshot.songTitle)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)

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
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, 120)
        }
        .navigationTitle("PhraseRise")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            viewModel.refresh()
        }
    }
}
