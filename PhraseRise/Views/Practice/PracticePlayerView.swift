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
                waveformCard
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
        .studioScreen()
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
        StudioCard(emphasisColor: AppColors.accent) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(song.title)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)

                        Text(phrase.name)
                            .font(AppTypography.screenTitle)
                    }

                    Spacer()

                    Text(phrase.status.label)
                        .font(AppTypography.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(phrase.status.tint.opacity(0.88), in: Capsule())
                }

                HStack {
                    infoPill("目標", value: viewModel.targetBpmLabel)
                    infoPill("ループ長", value: viewModel.loopDurationLabel)
                    infoPill("位置", value: Formatting.duration(viewModel.currentTimeSec))
                }

                if viewModel.isRecording {
                    Label("演奏録音中 \(Formatting.duration(viewModel.recordingElapsedSec))", systemImage: "record.circle.fill")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.recording)
                } else {
                    Label(viewModel.latestRecordingSummary, systemImage: viewModel.hasLatestRecording ? "waveform.badge.mic" : "waveform")
                        .font(AppTypography.caption)
                        .foregroundStyle(viewModel.hasLatestRecording ? AppColors.textSecondary : AppColors.textMuted)
                }
            }
        }
    }

    private var waveformCard: some View {
        StudioCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("ループ範囲")
                        .font(AppTypography.cardTitle)
                    Spacer()
                    Text("\(Formatting.duration(viewModel.loopRange.lowerBound)) - \(Formatting.duration(viewModel.loopRange.upperBound))")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                WaveformPlaceholderView(
                    values: song.waveformOverview.isEmpty ? Array(repeating: 0.42, count: 52) : song.waveformOverview,
                    selection: viewModel.selectionRatio,
                    headPosition: viewModel.headRatio
                )
                .frame(height: 250)
            }
        }
    }

    private var transportCard: some View {
        StudioCard(emphasisColor: AppColors.accent) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.bpm) BPM")
                            .font(AppTypography.bpmHero)
                        Text("再生速度 \(viewModel.playbackRateLabel)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Text("前回 stable \(phrase.lastStableBpm.map { "\($0)" } ?? "--")")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        Text("今日の開始 \(phrase.recommendedStartBpm.map { "\($0)" } ?? "--")")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
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
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceGlass))

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
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceGlass))
                }
            }
        }
    }

    private var loopCard: some View {
        StudioCard(emphasisColor: viewModel.isLoopEnabled ? AppColors.accent : AppColors.textMuted) {
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
                    .buttonStyle(FilledStudioButtonStyle(tint: viewModel.isLoopEnabled ? AppColors.accentSoft : AppColors.surfaceGlass))
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
                .frame(maxWidth: .infinity)
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
                .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
                .padding(AppSpacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                        .fill(AppColors.heroGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                )
                .shadow(color: AppColors.accent.opacity(0.20), radius: 18, x: 0, y: 10)
            }
            .buttonStyle(.plain)
        }
    }

    private func infoPill(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surfaceGlass.opacity(0.82))
        )
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
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceGlass))
                Button("+0.1s", action: onPlus)
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceGlass))
            }
        }
    }
}
