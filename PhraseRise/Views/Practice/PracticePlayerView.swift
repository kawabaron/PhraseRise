import SwiftUI

struct PracticePlayerView: View {
    let phrase: Phrase
    let song: Song
    let dependencies: AppDependencies

    @State private var viewModel: PracticePlayerViewModel
    @State private var isPresentingRecordSheet = false

    init(phrase: Phrase, song: Song, dependencies: AppDependencies) {
        self.phrase = phrase
        self.song = song
        self.dependencies = dependencies
        _viewModel = State(initialValue: PracticePlayerViewModel(phrase: phrase, song: song, dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                headerCard

                WaveformPlaceholderView(
                    values: song.waveformOverview.isEmpty ? Array(repeating: 0.42, count: 52) : song.waveformOverview,
                    selection: viewModel.selectionRatio,
                    headPosition: viewModel.headRatio
                )
                .frame(height: 260)

                transportCard
                loopCard
                actionRow
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, 120)
        }
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingRecordSheet) {
            PracticeRecordSheet(phrase: phrase, initialBpm: viewModel.bpm, dependencies: dependencies)
        }
        .sheet(
            isPresented: Binding(
                get: { viewModel.shouldShowPaywall },
                set: { isPresented in
                    if !isPresented {
                        viewModel.shouldShowPaywall = false
                    }
                }
            )
        ) {
            PaywallView(dependencies: dependencies, message: viewModel.errorMessage)
        }
        .task {
            viewModel.handleAppear()
        }
        .onDisappear {
            viewModel.handleDisappear()
        }
        .alert(
            "エラー",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil && !viewModel.shouldShowPaywall },
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
    }

    private var headerCard: some View {
        StudioCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(song.title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)

                Text(phrase.name)
                    .font(AppTypography.screenTitle)

                HStack {
                    metric("目標 BPM", value: phrase.targetBpm.map { "\($0)" } ?? "--")
                    Spacer()
                    metric("前回 stable", value: phrase.lastStableBpm.map { "\($0)" } ?? "--")
                    Spacer()
                    metric("今日の開始", value: phrase.recommendedStartBpm.map { "\($0)" } ?? "--")
                }

                HStack {
                    Label("再生位置 \(Formatting.duration(viewModel.currentTimeSec))", systemImage: "play.fill")
                    Spacer()
                    if viewModel.isRecording {
                        Label("演奏録音 \(Formatting.duration(viewModel.recordingElapsedSec))", systemImage: "record.circle.fill")
                            .foregroundStyle(AppColors.recording)
                    } else {
                        Text(viewModel.latestRecordingSummary)
                    }
                }
                .font(AppTypography.caption)
                .foregroundStyle(viewModel.isRecording ? AppColors.recording : (viewModel.hasLatestRecording ? AppColors.textSecondary : AppColors.textMuted))
            }
        }
    }

    private var transportCard: some View {
        StudioCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(viewModel.bpm) BPM")
                        .font(AppTypography.bpmHero)
                    Spacer()
                    Text("再生速度 \(viewModel.playbackRateLabel)")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppColors.accent)
                }

                Stepper(
                    "テンポを調整",
                    value: Binding(
                        get: { viewModel.bpm },
                        set: { viewModel.setBpm($0) }
                    ),
                    in: 40 ... 240,
                    step: 1
                )
                .tint(AppColors.accent)

                HStack(spacing: AppSpacing.medium) {
                    Button {
                        viewModel.seek(by: -5)
                    } label: {
                        Label("5秒戻る", systemImage: "gobackward.5")
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceRaised))

                    Button {
                        viewModel.togglePlayback()
                    } label: {
                        Label(viewModel.isPlaying ? "一時停止" : "再生", systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))

                    Button {
                        viewModel.seek(by: 5)
                    } label: {
                        Label("5秒進む", systemImage: "goforward.5")
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceRaised))
                }
            }
        }
    }

    private var loopCard: some View {
        StudioCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(viewModel.isLoopEnabled ? "ループ中" : "ループ停止", systemImage: "repeat")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(viewModel.isLoopEnabled ? AppColors.accent : AppColors.textSecondary)
                    Spacer()
                    Button {
                        viewModel.toggleLoop()
                    } label: {
                        Text(viewModel.isLoopEnabled ? "ループを解除" : "ループを有効")
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: viewModel.isLoopEnabled ? AppColors.accentMuted : AppColors.surfaceRaised))
                }

                HStack {
                    loopAdjuster(
                        title: "A",
                        value: Formatting.duration(viewModel.loopRange.lowerBound),
                        onMinus: { viewModel.nudgeLoopStart(by: -0.1) },
                        onPlus: { viewModel.nudgeLoopStart(by: 0.1) }
                    )
                    Spacer()
                    loopAdjuster(
                        title: "B",
                        value: Formatting.duration(viewModel.loopRange.upperBound),
                        onMinus: { viewModel.nudgeLoopEnd(by: -0.1) },
                        onPlus: { viewModel.nudgeLoopEnd(by: 0.1) }
                    )
                }
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: AppSpacing.large) {
            Button {
                Task {
                    await viewModel.togglePerformanceRecording()
                }
            } label: {
                VStack(spacing: 10) {
                    CircularRecordButton(isRecording: viewModel.isRecording)
                    Text(viewModel.isRecording ? "演奏録音を停止" : "演奏を録音")
                        .font(AppTypography.caption)
                }
            }
            .buttonStyle(.plain)

            Button {
                isPresentingRecordSheet = true
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    Label("記録", systemImage: "square.and.pencil")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                    Text("達成 BPM、結果、メモを1画面で保存")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                .padding(AppSpacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                        .fill(AppColors.accent)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.semibold))
        }
    }

    private func loopAdjuster(
        title: String,
        value: String,
        onMinus: @escaping () -> Void,
        onPlus: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(title): \(value)")
                .font(.system(.headline, design: .rounded).weight(.semibold))

            HStack(spacing: AppSpacing.small) {
                Button("-0.1s", action: onMinus)
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceRaised))
                Button("+0.1s", action: onPlus)
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceRaised))
            }
        }
    }
}
