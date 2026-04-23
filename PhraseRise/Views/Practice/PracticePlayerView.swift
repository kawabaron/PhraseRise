import SwiftUI

struct PracticePlayerView: View {
    @Environment(\.dismiss) private var dismiss

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
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppSpacing.large) {
                topBar
                heroSection
                loopCanvasCard
                playbackCard
                takesCard
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.medium)
            .padding(.bottom, AppSpacing.xxLarge)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
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

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 54, height: 54)
                    .background(
                        Circle()
                            .fill(AppColors.surfaceMuted.opacity(0.92))
                    )
                    .overlay(
                        Circle()
                            .stroke(AppColors.borderStrong, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            if viewModel.isRecording {
                statusPill(
                    label: "REC \(Formatting.duration(viewModel.recordingElapsedSec))",
                    tint: AppColors.recording
                )
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(displaySongTitle)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)

            Text(phrase.name)
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                statusPill(
                    label: phrase.status == .mastered ? "Mastered" : "Ready",
                    tint: phrase.status == .mastered ? AppColors.success : AppColors.accent
                )
                statusPill(
                    label: rangeLabel,
                    tint: AppColors.surfaceInteractive,
                    usesMutedStyle: true
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var loopCanvasCard: some View {
        StudioCard(emphasisColor: AppColors.accent) {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                cardHeader(
                    title: "Loop Canvas",
                    subtitle: "Adjust the phrase range directly on the waveform."
                )

                if let videoURL = song.videoFileURL {
                    VideoPlaybackDisplayView(
                        videoURL: videoURL,
                        durationSec: song.durationSec,
                        headPosition: viewModel.headRatio
                    )
                    .frame(height: 124)
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
                .frame(height: song.videoFileURL != nil ? 84 : 108)

                HStack(spacing: 10) {
                    loopInfoPill(title: "A", value: Formatting.duration(viewModel.loopRange.lowerBound), tint: AppColors.accent)
                    loopInfoPill(title: "B", value: Formatting.duration(viewModel.loopRange.upperBound), tint: AppColors.progress)
                    loopInfoPill(title: "Span", value: viewModel.loopDurationLabel, tint: AppColors.success)
                }
            }
        }
    }

    private var playbackCard: some View {
        StudioCard(emphasisColor: AppColors.progress) {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                cardHeader(
                    title: "Playback",
                    subtitle: "Speed and pitch stay close to the transport."
                )

                HStack(spacing: AppSpacing.large) {
                    transportSideButton(icon: "gobackward.5") {
                        viewModel.seek(by: -5)
                    }

                    Button {
                        viewModel.togglePlayback()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: transportIconName)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(Color.black)
                                .frame(width: 84, height: 84)
                                .background(Circle().fill(AppColors.accent))
                                .shadow(color: AppColors.accent.opacity(0.35), radius: 16, x: 0, y: 10)

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
    }

    private var takesCard: some View {
        StudioCard(emphasisColor: AppColors.recording) {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                cardHeader(
                    title: "Takes",
                    subtitle: "Capture reps and jump into notes or comparison."
                )

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
                            .frame(height: 26)
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
    }

    private var displaySongTitle: String {
        let trimmed = song.title.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("picked-") {
            return "Imported source"
        }

        if trimmed.count > 40 {
            return String(trimmed.prefix(40)) + "..."
        }

        return trimmed
    }

    private var rangeLabel: String {
        "\(Formatting.duration(phrase.startTimeSec)) - \(Formatting.duration(phrase.endTimeSec))"
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

    private func cardHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text(subtitle)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func transportSideButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: 52, height: 52)
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
        .padding(16)
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
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .padding(16)
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
