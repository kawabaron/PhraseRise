import SwiftUI

struct SongDetailView: View {
    let dependencies: AppDependencies

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SongDetailViewModel
    @State private var phraseToDelete: Phrase?
    @State private var showingSongDeleteAlert = false

    init(song: Song, dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: SongDetailViewModel(song: song, dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                headerCard

                NavigationLink {
                    PhraseEditorView(song: viewModel.song, dependencies: dependencies)
                } label: {
                    Label("新しい Phrase を追加", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))

                phraseSection
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, 120)
        }
        .navigationTitle("Song Detail")
        .navigationBarTitleDisplayMode(.inline)
        .studioScreen()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showingSongDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("この Song を削除しますか？", isPresented: $showingSongDeleteAlert) {
            Button("削除", role: .destructive) {
                viewModel.deleteSong()
                dismiss()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("関連する Phrase、練習記録、演奏録音も一緒に削除されます。")
        }
        .confirmationDialog(
            "この Phrase を削除しますか？",
            isPresented: Binding(
                get: { phraseToDelete != nil },
                set: { isPresented in
                    if !isPresented {
                        phraseToDelete = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                if let phraseToDelete {
                    viewModel.deletePhrase(phraseToDelete)
                    self.phraseToDelete = nil
                }
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("関連する練習記録と演奏録音も削除されます。")
        }
        .onAppear {
            viewModel.refresh()
        }
    }

    private var headerCard: some View {
        StudioCard(emphasisColor: viewModel.song.sourceType == .micRecorded ? AppColors.recording : AppColors.accent) {
            VStack(alignment: .leading, spacing: 14) {
                Text(viewModel.song.title)
                    .font(AppTypography.screenTitle)
                Text(viewModel.song.artistName ?? viewModel.song.sourceType.label)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)

                WaveformPlaceholderView(
                    values: viewModel.waveformValues,
                    selection: 0.22 ... 0.40,
                    showHead: false
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
    }

    private var phraseSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            StudioSectionHeader("フレーズ")

            if viewModel.phrases.isEmpty {
                StudioCard {
                    Text("まだ Phrase がありません。難所フレーズを切り出して練習を始めましょう。")
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(viewModel.phrases, id: \.id) { phrase in
                    StudioCard(emphasisColor: phrase.status.tint) {
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
                                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceGlass))

                                NavigationLink("編集") {
                                    PhraseEditorView(song: viewModel.song, phrase: phrase, dependencies: dependencies)
                                }
                                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accentSoft))

                                NavigationLink("練習") {
                                    PracticePlayerView(phrase: phrase, song: viewModel.song, dependencies: dependencies)
                                }
                                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))

                                Button("削除", role: .destructive) {
                                    phraseToDelete = phrase
                                }
                                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.recording))
                            }
                        }
                    }
                }
            }
        }
    }
}
