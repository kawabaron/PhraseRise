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
        VStack(spacing: 0) {
            heroSection

            waveformBlock
                .padding(.top, AppSpacing.medium)

            Spacer(minLength: AppSpacing.small)

            transportBlock

            Spacer(minLength: AppSpacing.small)

            loopBlock

            Spacer(minLength: AppSpacing.small)

            if viewModel.isRecording {
                InputLevelMeterView(level: viewModel.recordingInputLevel, isActive: true)
                    .frame(height: 28)
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.bottom, AppSpacing.xSmall)
                    .transition(.opacity)
            }

            actionRow
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, AppSpacing.medium)
        }
        .frame(maxHeight: .infinity)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .studioScreen()
        .sheet(isPresented: $isPresentingRecordSheet) {
            PracticeRecordSheet(phrase: phrase, dependencies: dependencies)
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
        VStack(alignment: .leading, spacing: AppSpacing.small) {
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
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                if viewModel.isRecording {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "record.circle.fill")
                        Text(Formatting.duration(viewModel.recordingElapsedSec))
                            .monospacedDigit()
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.recording)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.small)
        .padding(.bottom, AppSpacing.medium)
        .background(
            RadialGradient(
                colors: [
                    AppColors.accent.opacity(0.22),
                    Color.clear
                ],
                center: UnitPoint(x: 0.1, y: 0.0),
                startRadius: 10,
                endRadius: 320
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - Waveform

    private var waveformBlock: some View {
        WaveformPlaceholderView(
            values: song.waveformOverview.isEmpty ? Array(repeating: 0.42, count: 52) : song.waveformOverview,
            selection: viewModel.selectionRatio,
            headPosition: viewModel.headRatio,
            onSelectionChange: { ratio in
                viewModel.setLoopRange(fromRatio: ratio)
            }
        )
        .frame(height: 110)
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }

    // MARK: - Transport

    private var transportBlock: some View {
        VStack(spacing: AppSpacing.small) {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                speedStack
                    .frame(maxWidth: .infinity)
                pitchStack
                    .frame(maxWidth: .infinity)
            }

            HStack(spacing: AppSpacing.large) {
                transportSideButton(icon: "gobackward.5") {
                    viewModel.seek(by: -5)
                }

                Button {
                    viewModel.togglePlayback()
                } label: {
                    Image(systemName: transportIconName)
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
            }
            .padding(.top, AppSpacing.xSmall)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }

    private var speedStack: some View {
        VStack(spacing: AppSpacing.xSmall) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(viewModel.speedPercent)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .monospacedDigit()
                Text("%")
                    .font(.system(.subheadline, design: .rounded).weight(.regular))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Stepper(
                "速度を調整",
                value: Binding(
                    get: { viewModel.speedPercent },
                    set: { viewModel.setSpeedPercent($0) }
                ),
                in: PracticePlayerViewModel.speedPercentRange,
                step: PracticePlayerViewModel.speedPercentStep
            )
            .tint(AppColors.accent)
            .labelsHidden()
        }
    }

    private var pitchStack: some View {
        VStack(spacing: AppSpacing.xSmall) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(pitchLabel)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .monospacedDigit()
                Text("キー")
                    .font(.system(.subheadline, design: .rounded).weight(.regular))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Stepper(
                "キーを調整",
                value: Binding(
                    get: { viewModel.pitchSemitones },
                    set: { viewModel.setPitch($0) }
                ),
                in: -12 ... 12,
                step: 1
            )
            .tint(AppColors.accent)
            .labelsHidden()
        }
    }

    private var pitchLabel: String {
        let value = viewModel.pitchSemitones
        if value > 0 { return "+\(value)" }
        return "\(value)"
    }

    private var transportIconName: String {
        viewModel.isPlaying ? "pause.fill" : "play.fill"
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
        VStack(spacing: AppSpacing.small) {
            HStack(spacing: AppSpacing.xSmall) {
                Button {
                    viewModel.toggleLoop()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "repeat")
                            .font(.system(size: 12, weight: .semibold))
                        Text("ループ")
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

                Spacer()
            }

            HStack(spacing: AppSpacing.medium) {
                loopAdjuster(
                    title: "開始",
                    value: Formatting.duration(viewModel.loopRange.lowerBound),
                    onMinus: { viewModel.nudgeLoopStart(by: -0.1) },
                    onPlus: { viewModel.nudgeLoopStart(by: 0.1) }
                )

                loopAdjuster(
                    title: "終了",
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
        HStack(spacing: 6) {
            Text("\(title) \(value)")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()

            Button(action: onMinus) {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(AppColors.surface))
                    .overlay(Circle().stroke(AppColors.border, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button(action: onPlus) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(AppColors.surface))
                    .overlay(Circle().stroke(AppColors.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack(spacing: AppSpacing.medium) {
            Button {
                Task {
                    await viewModel.togglePerformanceRecording()
                }
            } label: {
                CircularRecordButton(isRecording: viewModel.isRecording)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            Button {
                isPresentingRecordSheet = true
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppColors.accent)
                    Text("練習を記録")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                }
                .frame(maxWidth: .infinity, minHeight: 88)
                .padding(AppSpacing.small)
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
