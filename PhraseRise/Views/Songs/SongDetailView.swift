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

    private var accentColor: Color {
        viewModel.song.sourceType == .micRecorded ? AppColors.recording : AppColors.accent
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection

                addPhraseButton
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.large)

                phraseSection
                    .padding(.top, AppSpacing.xLarge)
            }
            .padding(.bottom, 120)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .studioScreen()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showingSongDeleteAlert = true
                    } label: {
                        Label("Song を削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(AppColors.textSecondary)
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
            Text("関連する練習区間、練習記録、演奏録音も一緒に削除されます。")
        }
        .confirmationDialog(
            "この練習区間を削除しますか？",
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
        .onDisappear {
            viewModel.stopPlayback()
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.song.sourceType.label.uppercased())
                    .font(AppTypography.eyebrow)
                    .tracking(2)
                    .foregroundStyle(accentColor)

                Text(viewModel.song.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)

                if let artist = viewModel.song.artistName, !artist.isEmpty {
                    Text(artist)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            WaveformPlaceholderView(
                values: viewModel.waveformValues,
                headPosition: viewModel.isSongPlaying ? viewModel.songPlaybackRatio : nil,
                showHead: viewModel.isSongPlaying
            )
            .frame(height: 120)
            .padding(.top, AppSpacing.small)

            HStack(spacing: 16) {
                Button {
                    viewModel.toggleSongPlayback()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isSongPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(viewModel.isSongPlaying ? "停止" : "再生")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                    }
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(
                            viewModel.isSongPlaying ? AppColors.recording : AppColors.surface
                        )
                    )
                    .overlay(Capsule().stroke(AppColors.border, lineWidth: 1))
                }
                .buttonStyle(.plain)

                metaLabel(
                    icon: "rectangle.split.3x1",
                    text: "\(viewModel.phrases.count) 練習区間"
                )
                metaLabel(
                    icon: "clock",
                    text: Formatting.duration(viewModel.song.durationSec)
                )
                Spacer()
            }
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.medium)
        .padding(.bottom, AppSpacing.large)
        .background(
            RadialGradient(
                colors: [
                    accentColor.opacity(0.22),
                    Color.clear
                ],
                center: UnitPoint(x: 0.1, y: 0.0),
                startRadius: 10,
                endRadius: 380
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    private func metaLabel(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
            Text(text)
        }
    }

    private var addPhraseButton: some View {
        NavigationLink {
            PhraseEditorView(song: viewModel.song, dependencies: dependencies)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                Text("新しい練習区間を追加")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .foregroundStyle(AppColors.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.accent.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColors.accent.opacity(0.32), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            )
        }
        .buttonStyle(.plain)
    }

    private var phraseSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("練習区間")
                .font(AppTypography.eyebrow)
                .tracking(2)
                .foregroundStyle(AppColors.textMuted)
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, AppSpacing.small)

            if viewModel.phrases.isEmpty {
                Text("まだ練習区間がありません。難所を切り出して練習を始めましょう。")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.vertical, AppSpacing.large)
            } else {
                ForEach(Array(viewModel.phrases.enumerated()), id: \.element.id) { index, phrase in
                    NavigationLink {
                        PhraseDetailView(phrase: phrase, song: viewModel.song, dependencies: dependencies)
                    } label: {
                        phraseRow(phrase)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        NavigationLink {
                            PracticePlayerView(phrase: phrase, song: viewModel.song, dependencies: dependencies)
                        } label: {
                            Label("練習", systemImage: "play.circle")
                        }
                        NavigationLink {
                            PhraseEditorView(song: viewModel.song, phrase: phrase, dependencies: dependencies)
                        } label: {
                            Label("編集", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            phraseToDelete = phrase
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }

                    if index < viewModel.phrases.count - 1 {
                        Rectangle()
                            .fill(AppColors.border)
                            .frame(height: 0.5)
                            .padding(.leading, AppSpacing.screenHorizontal + 22)
                    }
                }
            }
        }
    }

    private func phraseRow(_ phrase: Phrase) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(phrase.status.tint)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(phrase.name)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("\(Formatting.duration(phrase.startTimeSec)) – \(Formatting.duration(phrase.endTimeSec))")
                    Text("·")
                    Text(phrase.status.label)
                        .foregroundStyle(phrase.status.tint)
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            ProgressPlayButton(
                isPlaying: viewModel.playingPhraseID == phrase.id,
                progress: viewModel.playingPhraseID == phrase.id ? viewModel.playingPhraseProgress : 0,
                size: 34
            ) {
                viewModel.togglePhrasePlayback(phrase)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
