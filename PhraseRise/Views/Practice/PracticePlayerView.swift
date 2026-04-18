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
            VStack(spacing: 0) {
                heroSection

                waveformBlock
                    .padding(.top, AppSpacing.xLarge)

                transportBlock
                    .padding(.top, AppSpacing.xLarge)

                loopBlock
                    .padding(.top, AppSpacing.xLarge)

                actionRow
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.xLarge)
            }
            .padding(.bottom, 120)
        }
        .navigationTitle("")
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

    // MARK: - Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: 8) {
                Text(song.title.uppercased())
                    .font(AppTypography.eyebrow)
                    .tracking(2)
                    .foregroundStyle(AppColors.textMuted)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Circle()
                        .fill(phrase.status.tint)
                        .frame(width: 10, height: 10)

                    Text(phrase.name)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(2)
                }
            }

            HStack(spacing: 10) {
                heroPill(label: "目標", value: viewModel.targetBpmLabel)
                heroPill(label: "ループ", value: viewModel.loopDurationLabel)
                heroPill(label: "位置", value: Formatting.duration(viewModel.currentTimeSec))
                Spacer(minLength: 0)
            }

            recordingStatusLine
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.medium)
        .padding(.bottom, AppSpacing.large)
        .background(
            RadialGradient(
                colors: [
                    AppColors.accent.opacity(0.22),
                    Color.clear
                ],
                center: UnitPoint(x: 0.1, y: 0.0),
                startRadius: 10,
                endRadius: 380
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    private var recordingStatusLine: some View {
        HStack(spacing: 6) {
            if viewModel.isRecording {
                Image(systemName: "record.circle.fill")
                    .foregroundStyle(AppColors.recording)
                Text("演奏録音中 \(Formatting.duration(viewModel.recordingElapsedSec))")
                    .foregroundStyle(AppColors.recording)
            } else {
                Image(systemName: viewModel.hasLatestRecording ? "waveform.badge.mic" : "waveform")
                    .foregroundStyle(viewModel.hasLatestRecording ? AppColors.textSecondary : AppColors.textMuted)
                Text(viewModel.latestRecordingSummary)
                    .foregroundStyle(viewModel.hasLatestRecording ? AppColors.textSecondary : AppColors.textMuted)
            }
        }
        .font(AppTypography.caption)
    }

    private func heroPill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppTypography.eyebrow)
                .tracking(1)
                .foregroundStyle(AppColors.textMuted)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.surface.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    // MARK: - Waveform

    private var waveformBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Text("LOOP RANGE")
                    .font(AppTypography.eyebrow)
                    .tracking(2)
                    .foregroundStyle(AppColors.textMuted)
                Spacer()
                Text("\(Formatting.duration(viewModel.loopRange.lowerBound)) – \(Formatting.duration(viewModel.loopRange.upperBound))")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)

            WaveformPlaceholderView(
                values: song.waveformOverview.isEmpty ? Array(repeating: 0.42, count: 52) : song.waveformOverview,
                selection: viewModel.selectionRatio,
                headPosition: viewModel.headRatio
            )
            .frame(height: 220)
            .padding(.horizontal, AppSpacing.screenHorizontal)
        }
    }

    // MARK: - Transport

    private var transportBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TEMPO")
                        .font(AppTypography.eyebrow)
                        .tracking(2)
                        .foregroundStyle(AppColors.textMuted)

                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text("\(viewModel.bpm)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.textPrimary)
                        Text("BPM")
                            .font(.system(.title3, design: .rounded).weight(.regular))
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Text("再生速度 \(viewModel.playbackRateLabel)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("前回 stable \(phrase.lastStableBpm.map { "\($0)" } ?? "--")")
                    Text("今日の開始 \(phrase.recommendedStartBpm.map { "\($0)" } ?? "--")")
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
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
            .labelsHidden()
            .padding(.vertical, 4)

            transportControls
                .padding(.top, AppSpacing.small)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }

    private var transportControls: some View {
        HStack(spacing: AppSpacing.xLarge) {
            Spacer()

            transportSideButton(icon: "gobackward.5") {
                viewModel.seek(by: -5)
            }

            Button {
                viewModel.togglePlayback()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.black)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(AppColors.accent))
                    .shadow(color: AppColors.accent.opacity(0.35), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)

            transportSideButton(icon: "goforward.5") {
                viewModel.seek(by: 5)
            }

            Spacer()
        }
    }

    private func transportSideButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: 48, height: 48)
                .background(Circle().fill(AppColors.surface))
                .overlay(Circle().stroke(AppColors.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Loop

    private var loopBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack {
                Text("LOOP")
                    .font(AppTypography.eyebrow)
                    .tracking(2)
                    .foregroundStyle(AppColors.textMuted)

                Spacer()

                Button {
                    viewModel.toggleLoop()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "repeat")
                            .font(.system(size: 12, weight: .semibold))
                        Text(viewModel.isLoopEnabled ? "有効" : "無効")
                            .font(AppTypography.caption)
                    }
                    .foregroundStyle(viewModel.isLoopEnabled ? AppColors.accent : AppColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(
                            viewModel.isLoopEnabled
                                ? AppColors.accent.opacity(0.15)
                                : AppColors.surface.opacity(0.7)
                        )
                    )
                    .overlay(
                        Capsule().stroke(
                            viewModel.isLoopEnabled ? AppColors.accent.opacity(0.4) : AppColors.border,
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: AppSpacing.large) {
                loopAdjuster(
                    title: "A",
                    value: Formatting.duration(viewModel.loopRange.lowerBound),
                    onMinus: { viewModel.nudgeLoopStart(by: -0.1) },
                    onPlus: { viewModel.nudgeLoopStart(by: 0.1) }
                )

                loopAdjuster(
                    title: "B",
                    value: Formatting.duration(viewModel.loopRange.upperBound),
                    onMinus: { viewModel.nudgeLoopEnd(by: -0.1) },
                    onPlus: { viewModel.nudgeLoopEnd(by: 0.1) }
                )
            }
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }

    private func loopAdjuster(
        title: String,
        value: String,
        onMinus: @escaping () -> Void,
        onPlus: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(AppColors.accent)
                Text(value)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }

            HStack(spacing: 6) {
                nudgeButton(label: "-0.1s", action: onMinus)
                nudgeButton(label: "+0.1s", action: onPlus)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func nudgeButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(AppColors.surface)
                )
                .overlay(Capsule().stroke(AppColors.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack(spacing: AppSpacing.large) {
            Button {
                Task {
                    await viewModel.togglePerformanceRecording()
                }
            } label: {
                VStack(spacing: 8) {
                    CircularRecordButton(isRecording: viewModel.isRecording)
                    Text(viewModel.isRecording ? "録音を停止" : "演奏を録音")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            Button {
                isPresentingRecordSheet = true
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColors.accent)
                    Text("記録を保存")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("達成 BPM・結果・メモ")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                }
                .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
                .padding(AppSpacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                        .fill(AppColors.accent.opacity(0.10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                        .stroke(AppColors.accent.opacity(0.35), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
}
