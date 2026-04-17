import SwiftUI

struct RecordingListView: View {
    let phrase: Phrase
    let song: Song
    let dependencies: AppDependencies

    @State private var viewModel: RecordingListViewModel

    init(phrase: Phrase, song: Song, dependencies: AppDependencies) {
        self.phrase = phrase
        self.song = song
        self.dependencies = dependencies
        _viewModel = State(initialValue: RecordingListViewModel(phrase: phrase, song: song, dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                StudioSectionHeader("演奏録音一覧", subtitle: "日付、BPM、結果を見ながら聞き返せます。")

                compareCard

                if viewModel.recordings.isEmpty {
                    StudioCard {
                        Text("演奏録音はまだありません。PracticePlayer から録音してみましょう。")
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    ForEach(viewModel.recordings, id: \.id) { recording in
                        recordingCard(recording)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, 120)
        }
        .navigationTitle("Recordings")
        .navigationBarTitleDisplayMode(.inline)
        .studioScreen()
        .sheet(
            isPresented: Binding(
                get: { viewModel.paywallMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.paywallMessage = nil
                    }
                }
            )
        ) {
            PaywallView(dependencies: dependencies, message: viewModel.paywallMessage)
        }
        .alert(
            "エラー",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.errorMessage = nil
                    }
                }
            )
        ) {
            Button("閉じる", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "不明なエラーです。")
        }
        .onDisappear {
            viewModel.stopPreview()
        }
    }

    private var compareCard: some View {
        StudioCard(emphasisColor: AppColors.accent) {
            VStack(alignment: .leading, spacing: 12) {
                Text("比較再生")
                    .font(AppTypography.cardTitle)

                Text(viewModel.compareTitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)

                HStack {
                    selectedBadge(index: 1, recording: viewModel.selectedRecordings.first)
                    selectedBadge(index: 2, recording: viewModel.selectedRecordings.dropFirst().first)
                }

                HStack(spacing: AppSpacing.medium) {
                    Button {
                        viewModel.playComparison()
                    } label: {
                        Label("比較再生", systemImage: "arrow.left.arrow.right.circle.fill")
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))

                    Button {
                        viewModel.stopPreview()
                    } label: {
                        Label("停止", systemImage: "stop.fill")
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceGlass))
                }
            }
        }
    }

    private func recordingCard(_ recording: PerformanceRecording) -> some View {
        StudioCard(emphasisColor: AppColors.recording) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recording.takeName)
                            .font(AppTypography.cardTitle)
                        Text(song.title)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Spacer()

                    if let resultType = recording.resultType {
                        Text(resultType.label)
                            .font(AppTypography.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(resultType.tint.opacity(0.18), in: Capsule())
                    }
                }

                HStack {
                    Label(Formatting.date(recording.recordedAt), systemImage: "calendar")
                    Spacer()
                    Label("\(recording.bpmAtRecording ?? 0) BPM", systemImage: "metronome")
                    Spacer()
                    Label(Formatting.duration(recording.durationSec), systemImage: "clock")
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)

                HStack {
                    Label(viewModel.hasLinkedMemo(for: recording) ? "メモあり" : "メモなし", systemImage: "note.text")
                    Spacer()
                    Label(
                        viewModel.selectedRecordingIDs.contains(recording.id) ? "比較対象" : "未選択",
                        systemImage: viewModel.selectedRecordingIDs.contains(recording.id) ? "checkmark.circle.fill" : "circle"
                    )
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)

                HStack(spacing: AppSpacing.medium) {
                    Button {
                        viewModel.playSingle(recording)
                    } label: {
                        Label(
                            viewModel.playingRecordingID == recording.id ? "停止" : "演奏録音を聞く",
                            systemImage: viewModel.playingRecordingID == recording.id ? "stop.fill" : "play.fill"
                        )
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceGlass))

                    Button {
                        viewModel.toggleSelection(recording)
                    } label: {
                        Label(
                            viewModel.selectedRecordingIDs.contains(recording.id) ? "選択解除" : "比較に追加",
                            systemImage: viewModel.selectedRecordingIDs.contains(recording.id) ? "checkmark.circle.fill" : "plus.circle"
                        )
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accentSoft))

                    Button {
                        viewModel.delete(recording)
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.recording))
                }
            }
        }
    }

    private func selectedBadge(index: Int, recording: PerformanceRecording?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("比較 \(index)")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            Text(recording?.takeName ?? "未選択")
                .font(.system(.headline, design: .rounded).weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surfaceGlass.opacity(0.84))
        )
    }
}
