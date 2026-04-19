import SwiftUI

struct RecordingListView: View {
    let phrase: Phrase
    let song: Song
    let dependencies: AppDependencies

    @State private var viewModel: RecordingListViewModel
    @State private var recordingToDelete: PerformanceRecording?

    init(phrase: Phrase, song: Song, dependencies: AppDependencies) {
        self.phrase = phrase
        self.song = song
        self.dependencies = dependencies
        _viewModel = State(initialValue: RecordingListViewModel(phrase: phrase, song: song, dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection

                compareBlock
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.large)

                recordingsSection
                    .padding(.top, AppSpacing.xLarge)
            }
            .padding(.bottom, 120)
        }
        .navigationTitle("")
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
        .confirmationDialog(
            "この録音を削除しますか？",
            isPresented: Binding(
                get: { recordingToDelete != nil },
                set: { isPresented in
                    if !isPresented {
                        recordingToDelete = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                if let recordingToDelete {
                    viewModel.delete(recordingToDelete)
                    self.recordingToDelete = nil
                }
            }
            Button("キャンセル", role: .cancel) { }
        }
        .onDisappear {
            viewModel.stopPreview()
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECORDINGS")
                .font(AppTypography.eyebrow)
                .tracking(2)
                .foregroundStyle(AppColors.textMuted)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(viewModel.recordings.count)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                Text("テイク")
                    .font(.system(.title3, design: .rounded).weight(.regular))
                    .foregroundStyle(AppColors.textMuted)
            }

            Text("\(phrase.name) · \(song.title)")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.medium)
        .padding(.bottom, AppSpacing.xLarge)
        .background(
            RadialGradient(
                colors: [
                    AppColors.recording.opacity(0.22),
                    Color.clear
                ],
                center: UnitPoint(x: 0.1, y: 0.0),
                startRadius: 10,
                endRadius: 380
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - Compare

    private var compareBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack {
                Text("COMPARE")
                    .font(AppTypography.eyebrow)
                    .tracking(2)
                    .foregroundStyle(AppColors.textMuted)
                Spacer()
                Text(viewModel.compareTitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
            }

            HStack(spacing: 10) {
                selectedSlot(index: 1, recording: viewModel.selectedRecordings.first)
                selectedSlot(index: 2, recording: viewModel.selectedRecordings.dropFirst().first)
            }

            HStack(spacing: AppSpacing.small) {
                Button {
                    viewModel.playComparison()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 13, weight: .bold))
                        Text("比較再生")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppColors.accent)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.stopPreview()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AppColors.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func selectedSlot(index: Int, recording: PerformanceRecording?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SLOT \(index)")
                .font(AppTypography.eyebrow)
                .tracking(1)
                .foregroundStyle(AppColors.textMuted)
            Text(recording?.takeName ?? "未選択")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(recording == nil ? AppColors.textMuted : AppColors.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.surface.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    recording != nil ? AppColors.accent.opacity(0.4) : AppColors.border,
                    lineWidth: 1
                )
        )
    }

    // MARK: - Recordings

    private var recordingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TAKES")
                .font(AppTypography.eyebrow)
                .tracking(2)
                .foregroundStyle(AppColors.textMuted)
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, AppSpacing.small)

            if viewModel.recordings.isEmpty {
                Text("演奏録音はまだありません。PracticePlayer から録音してみましょう。")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.vertical, AppSpacing.large)
            } else {
                ForEach(Array(viewModel.recordings.enumerated()), id: \.element.id) { index, recording in
                    recordingRow(recording)
                        .contextMenu {
                            Button {
                                viewModel.toggleSelection(recording)
                            } label: {
                                Label(
                                    viewModel.selectedRecordingIDs.contains(recording.id) ? "選択解除" : "比較に追加",
                                    systemImage: viewModel.selectedRecordingIDs.contains(recording.id) ? "checkmark.circle.fill" : "plus.circle"
                                )
                            }
                            Button(role: .destructive) {
                                recordingToDelete = recording
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }

                    if index < viewModel.recordings.count - 1 {
                        Rectangle()
                            .fill(AppColors.border)
                            .frame(height: 0.5)
                            .padding(.leading, AppSpacing.screenHorizontal + 22)
                    }
                }
            }
        }
    }

    private func recordingRow(_ recording: PerformanceRecording) -> some View {
        let isSelected = viewModel.selectedRecordingIDs.contains(recording.id)
        let isPlaying = viewModel.playingRecordingID == recording.id

        return HStack(spacing: 14) {
            Circle()
                .fill(recording.resultType?.tint ?? AppColors.recording)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(recording.takeName)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(Formatting.date(recording.recordedAt))
                    Text("·")
                    Text(Formatting.duration(recording.durationSec))
                    if let resultType = recording.resultType {
                        Text("·")
                        Text(resultType.label).foregroundStyle(resultType.tint)
                    }
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button {
                viewModel.toggleSelection(recording)
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? AppColors.accent : AppColors.textMuted)
            }
            .buttonStyle(.plain)

            ProgressPlayButton(
                isPlaying: isPlaying,
                progress: isPlaying ? viewModel.playingProgress : 0,
                size: 34
            ) {
                viewModel.playSingle(recording)
            }
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
