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

                sourceCanvasSection
                    .padding(.top, AppSpacing.large)

                playbackSection
                    .padding(.top, AppSpacing.xLarge)

                recordingSection
                    .padding(.top, AppSpacing.xLarge)
            }
            .padding(.bottom, 120)
        }
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
            "Playback Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil && !viewModel.shouldShowPaywall },
                set: { isPresented in
                    if !isPresented {
                        viewModel.errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("PRACTICE")
                .font(AppTypography.eyebrow)
                .tracking(2)
                .foregroundStyle(AppColors.textMuted)

            VStack(alignment: .leading, spacing: 8) {
                Text(song.title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)

                Text(phrase.name)
                    .font(AppTypography.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)
            }

            HStack(spacing: 10) {
                statusPill(
                    label: phrase.status == .mastered ? "Mastered" : "Ready",
                    tint: phrase.status.tint
                )
                statusPill(
                    label: viewModel.isLoopEnabled ? "Loop on" : "Loop off",
                    tint: viewModel.isLoopEnabled ? AppColors.accent : AppColors.textMuted,
                    usesMutedStyle: !viewModel.isLoopEnabled
                )

                if viewModel.isRecording {
                    statusPill(
                        label: "REC \(Formatting.duration(viewModel.recordingElapsedSec))",
                        tint: AppColors.recording
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.medium)
    }

    private var sourceCanvasSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            StudioSectionHeader("Loop Canvas", subtitle: "Trim the phrase visually and keep the loop under your fingers.")
                .padding(.horizontal, AppSpacing.screenHorizontal)

            StudioCard(emphasisColor: AppColors.accent) {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    if let videoURL = song.videoFileURL {
                        VideoPlaybackDisplayView(
                            videoURL: videoURL,
                            durationSec: song.durationSec,
                            headPosition: viewModel.headRatio
                        )
                        .frame(height: 176)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    WaveformPlaceholderView(
                        values: song.waveformOverview.isEmpty ? Array(repeating: 0.42, count: 52) : song.waveformOverview,
                        selection: viewModel.selectionRatio,
                        headPosition: viewModel.headRatio,
                        onSelectionChange: { ratio in
                            viewModel.setLoopRange(fromRatio: ratio)
                        }
                    )
                    .frame(height: song.videoFileURL != nil ? 86 : 128)

                    HStack(spacing: 10) {
                        loopInfoPill(
                            title: "A",
                            value: Formatting.duration(viewModel.loopRange.lowerBound),
                            tint: AppColors.accent
                        )
                        loopInfoPill(
                            title: "B",
                            value: Formatting.duration(viewModel.loopRange.upperBound),
                            tint: AppColors.progress
                        )
                        loopInfoPill(
                            title: "Span",
                            value: viewModel.loopDurationLabel,
                            tint: AppColors.success
                        )
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
        }
    }

    private var playbackSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            StudioSectionHeader("Playback", subtitle: "Control timing and pitch without leaving the phrase.")
                .padding(.horizontal, AppSpacing.screenHorizontal)

            StudioCard(emphasisColor: AppColors.progress) {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    HStack(spacing: AppSpacing.large) {
                        transportSideButton(icon: "gobackward.5") {
                            viewModel.seek(by: -5)
                        }

                        Button {
                            viewModel.togglePlayback()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: transportIconName)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(Color.black)
                                    .frame(width: 88, height: 88)
                                    .background(Circle().fill(AppColors.accent))
                                    .shadow(color: AppColors.accent.opacity(0.35), radius: 18, x: 0, y: 10)
                                Text(viewModel.isPlaying ? "Pause" : "Play")
                                    .font(AppTypography.captionStrong)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)

                        transportSideButton(icon: "goforward.5") {
                            viewModel.seek(by: 5)
                        }
                    }

                    HStack(spacing: AppSpacing.medium) {
                        adjustmentCard(
                            title: "Speed",
                            value: "\(viewModel.speedPercent)%",
                            tint: AppColors.accent
                        ) {
                            Stepper(
                                "",
                                value: Binding(
                                    get: { viewModel.speedPercent },
                                    set: { viewModel.setSpeedPercent($0) }
                                ),
                                in: PracticePlayerViewModel.speedPercentRange,
                                step: PracticePlayerViewModel.speedPercentStep
                            )
                            .labelsHidden()
                            .tint(AppColors.accent)
                        }

                        adjustmentCard(
                            title: "Pitch",
                            value: pitchLabel,
                            tint: AppColors.progress
                        ) {
                            Stepper(
                                "",
                                value: Binding(
                                    get: { viewModel.pitchSemitones },
                                    set: { viewModel.setPitch($0) }
                                ),
                                in: -12 ... 12,
                                step: 1
                            )
                            .labelsHidden()
                            .tint(AppColors.progress)
                        }
                    }

                    Button {
                        viewModel.toggleLoop()
                    } label: {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "repeat")
                                    .font(.system(size: 13, weight: .semibold))
                                Text(viewModel.isLoopEnabled ? "Loop is active" : "Loop is paused")
                                    .font(AppTypography.bodyStrong)
                            }
                            .foregroundStyle(viewModel.isLoopEnabled ? AppColors.accent : AppColors.textSecondary)

                            Spacer()

                            Text("Tap to toggle")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textMuted)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(viewModel.isLoopEnabled ? AppColors.accent.opacity(0.12) : AppColors.surfaceMuted)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    viewModel.isLoopEnabled ? AppColors.accent.opacity(0.35) : AppColors.border,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
        }
    }

    private var recordingSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            StudioSectionHeader("Takes", subtitle: "Capture new reps, leave notes, and jump straight into comparison.")
                .padding(.horizontal, AppSpacing.screenHorizontal)

            StudioCard(emphasisColor: AppColors.recording) {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    HStack(spacing: AppSpacing.medium) {
                        Button {
                            Task {
                                await viewModel.togglePerformanceRecording()
                            }
                        } label: {
                            CircularRecordButton(isRecording: viewModel.isRecording)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(viewModel.isRecording ? "Recording in progress" : "Capture a new take")
                                .font(AppTypography.cardTitle)
                                .foregroundStyle(AppColors.textPrimary)

                            Text(recordingSummaryText)
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if viewModel.isRecording {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Input level")
                                .font(AppTypography.captionStrong)
                                .foregroundStyle(AppColors.textMuted)

                            InputLevelMeterView(level: viewModel.recordingInputLevel, isActive: true)
                                .frame(height: 28)
                        }
                        .transition(.opacity)
                    }

                    HStack(spacing: AppSpacing.medium) {
                        Button {
                            isPresentingRecordSheet = true
                        } label: {
                            actionTile(
                                icon: "square.and.pencil",
                                title: "Log Practice",
                                subtitle: "Save result and notes",
                                tint: AppColors.accent
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            RecordingListView(phrase: phrase, song: song, dependencies: dependencies)
                        } label: {
                            actionTile(
                                icon: "waveform.circle",
                                title: "Open Takes",
                                subtitle: "\(viewModel.recordingCount) saved",
                                tint: AppColors.recording
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
        }
    }

    private var pitchLabel: String {
        let value = viewModel.pitchSemitones
        if value > 0 {
            return "+\(value) st"
        }
        return "\(value) st"
    }

    private var transportIconName: String {
        viewModel.isPlaying ? "pause.fill" : "play.fill"
    }

    private var recordingSummaryText: String {
        if viewModel.isRecording {
            return "The meter below shows your live input while PhraseRise captures this take."
        }

        if viewModel.hasLatestRecording {
            return "Latest take saved on \(viewModel.latestRecordingSummary)."
        }

        return "No take has been saved yet. Start recording when you are ready."
    }

    private func transportSideButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: 54, height: 54)
                .background(
                    Circle()
                        .fill(AppColors.surfaceMuted)
                )
                .overlay(
                    Circle()
                        .stroke(AppColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func adjustmentCard<Content: View>(
        title: String,
        value: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(AppTypography.eyebrow)
                .tracking(1.4)
                .foregroundStyle(AppColors.textMuted)

            Text(value)
                .font(AppTypography.heroMetric)
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surfaceMuted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tint.opacity(0.22), lineWidth: 1)
        )
    }

    private func statusPill(label: String, tint: Color, usesMutedStyle: Bool = false) -> some View {
        Text(label)
            .font(AppTypography.captionStrong)
            .foregroundStyle(usesMutedStyle ? AppColors.textSecondary : tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(tint.opacity(usesMutedStyle ? 0.10 : 0.14))
            )
            .overlay(
                Capsule()
                    .stroke(tint.opacity(usesMutedStyle ? 0.18 : 0.30), lineWidth: 1)
            )
    }

    private func loopInfoPill(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(AppTypography.eyebrow)
                .tracking(1.2)
                .foregroundStyle(AppColors.textMuted)
            Text(value)
                .font(AppTypography.captionStrong)
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.28), lineWidth: 1)
        )
    }

    private func actionTile(icon: String, title: String, subtitle: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.12))
                )

            Text(title)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)

            Text(subtitle)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(AppSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                .fill(AppColors.surfaceMuted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                .stroke(tint.opacity(0.24), lineWidth: 1)
        )
    }
}
