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
        GeometryReader { geometry in
            let layout = PracticeScreenLayout(
                size: geometry.size,
                safeAreaInsets: geometry.safeAreaInsets
            )

            VStack(spacing: layout.stackSpacing) {
                compactHeader(layout: layout)
                practiceConsole(layout: layout)
            }
            .padding(.horizontal, layout.horizontalPadding)
            .padding(.top, geometry.safeAreaInsets.top + layout.topPadding)
            .padding(.bottom, max(layout.bottomPadding, geometry.safeAreaInsets.bottom + 8))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

    private func compactHeader(layout: PracticeScreenLayout) -> some View {
        ZStack {
            HStack {
                headerButton(icon: "chevron.down", size: layout.headerButtonSize) {
                    dismiss()
                }

                Spacer()

                Color.clear
                    .frame(width: layout.headerButtonSize, height: layout.headerButtonSize)
            }

            VStack(spacing: 4) {
                Text(displaySongTitle)
                    .font(layout.compact ? AppTypography.cardTitle : AppTypography.sectionTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text("\(phrase.name) | \(viewModel.phraseProgressLabel)")
                    .font(AppTypography.captionStrong)
                    .foregroundStyle(AppColors.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, layout.headerButtonSize + 18)
        }
    }

    private func practiceConsole(layout: PracticeScreenLayout) -> some View {
        VStack(alignment: .leading, spacing: layout.sectionSpacing) {
            consoleHeader(layout: layout)
            mediaStage(layout: layout)
            transportRow(layout: layout)
            loopStatusRow
            tuningPanel(layout: layout)
            inputMeterRow(layout: layout)
            recorderRail(layout: layout)
        }
        .padding(layout.consolePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(consoleBackground)
        .overlay(consoleOverlay)
        .shadow(color: AppColors.shadow.opacity(0.24), radius: 18, x: 0, y: 12)
    }

    private func consoleHeader(layout: PracticeScreenLayout) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(phrase.name)
                    .font(layout.compact ? Font.system(size: 24, weight: .bold, design: .rounded) : Font.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 0)

                capsuleBadge(
                    label: viewModel.isRecording ? "Recording" : (viewModel.isLoopEnabled ? "Loop On" : "Loop Off"),
                    tint: viewModel.isRecording ? AppColors.recording : AppColors.accent
                )
            }

            Text("\(displayArtistName) | \(rangeLabel)")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private func mediaStage(layout: PracticeScreenLayout) -> some View {
        VStack(alignment: .leading, spacing: layout.elementSpacing) {
            if let videoURL = song.videoFileURL {
                VideoPlaybackDisplayView(
                    videoURL: videoURL,
                    durationSec: song.durationSec,
                    headPosition: viewModel.headRatio
                )
                .frame(height: layout.videoHeight)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }

            WaveformPlaceholderView(
                values: waveformValues,
                selection: viewModel.selectionRatio,
                headPosition: viewModel.headRatio,
                onSelectionChange: { ratio in
                    viewModel.setLoopRange(fromRatio: ratio)
                }
            )
            .frame(height: layout.waveformHeight)

            HStack {
                waveformTimeLabel(Formatting.duration(viewModel.loopRange.lowerBound))
                Spacer()
                waveformTimeLabel(Formatting.duration(viewModel.currentTimeSec))
                Spacer()
                waveformTimeLabel(Formatting.duration(viewModel.loopRange.upperBound))
            }

            HStack(spacing: 10) {
                timelineMetric(title: "A", value: Formatting.duration(viewModel.loopRange.lowerBound), tint: AppColors.accent)
                timelineMetric(title: "B", value: Formatting.duration(viewModel.loopRange.upperBound), tint: AppColors.progress)
                timelineMetric(title: "Span", value: viewModel.loopDurationLabel, tint: AppColors.success)
            }
        }
    }

    private func transportRow(layout: PracticeScreenLayout) -> some View {
        HStack(spacing: layout.transportSpacing) {
            transportButton(
                icon: "gobackward.5",
                size: layout.sideTransportButtonSize
            ) {
                viewModel.seek(by: -5)
            }

            Spacer(minLength: 0)

            Button {
                viewModel.togglePlayback()
            } label: {
                ZStack {
                    Circle()
                        .fill(AppColors.surface)
                        .overlay(
                            Circle()
                                .stroke(AppColors.accent.opacity(0.95), lineWidth: 3)
                        )

                    Circle()
                        .fill(AppColors.accent.opacity(0.16))
                        .padding(8)

                    Image(systemName: transportIconName)
                        .font(.system(size: layout.playIconSize, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .offset(x: viewModel.isPlaying ? 0 : 2)
                }
                .frame(width: layout.playButtonSize, height: layout.playButtonSize)
                .shadow(color: AppColors.accent.opacity(0.28), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            transportButton(
                icon: "goforward.5",
                size: layout.sideTransportButtonSize
            ) {
                viewModel.seek(by: 5)
            }
        }
    }

    private var loopStatusRow: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.toggleLoop()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "repeat")
                        .font(.system(size: 13, weight: .semibold))
                    Text(viewModel.isLoopEnabled ? "Loop A-B" : "Loop Off")
                        .font(AppTypography.captionStrong)
                }
                .foregroundStyle(viewModel.isLoopEnabled ? AppColors.accent : AppColors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(viewModel.isLoopEnabled ? AppColors.accent.opacity(0.14) : AppColors.surfaceMuted)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            viewModel.isLoopEnabled ? AppColors.accent.opacity(0.30) : AppColors.border,
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)

            Text(viewModel.loopDurationLabel)
                .font(AppTypography.captionStrong)
                .foregroundStyle(AppColors.textSecondary)
                .monospacedDigit()

            Spacer()

            if viewModel.isRecording {
                Text("REC \(Formatting.duration(viewModel.recordingElapsedSec))")
                    .font(AppTypography.captionStrong)
                    .foregroundStyle(AppColors.recording)
                    .monospacedDigit()
            }
        }
    }

    private func tuningPanel(layout: PracticeScreenLayout) -> some View {
        HStack(spacing: 0) {
            tuningColumn(
                title: "Speed",
                value: "\(viewModel.speedPercent)%",
                tint: AppColors.accent,
                decreaseAction: {
                    viewModel.setSpeedPercent(viewModel.speedPercent - PracticePlayerViewModel.speedPercentStep)
                },
                increaseAction: {
                    viewModel.setSpeedPercent(viewModel.speedPercent + PracticePlayerViewModel.speedPercentStep)
                }
            )

            Rectangle()
                .fill(AppColors.border)
                .frame(width: 1)
                .padding(.vertical, 12)

            tuningColumn(
                title: "Pitch",
                value: pitchLabel,
                tint: AppColors.progress,
                decreaseAction: {
                    viewModel.setPitch(viewModel.pitchSemitones - 1)
                },
                increaseAction: {
                    viewModel.setPitch(viewModel.pitchSemitones + 1)
                }
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColors.surfaceMuted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    private func inputMeterRow(layout: PracticeScreenLayout) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "mic.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(viewModel.isRecording ? AppColors.recording : AppColors.textMuted)

            VStack(alignment: .leading, spacing: 8) {
                Text("INPUT")
                    .font(AppTypography.eyebrow)
                    .tracking(1.4)
                    .foregroundStyle(AppColors.textMuted)

                InputLevelMeterView(level: viewModel.recordingInputLevel, isActive: viewModel.isRecording)
                    .frame(height: layout.meterHeight)
            }

            Spacer(minLength: 0)

            Text(inputMeterLabel)
                .font(AppTypography.captionStrong)
                .foregroundStyle(viewModel.isRecording ? AppColors.textPrimary : AppColors.textMuted)
                .monospacedDigit()
        }
    }

    private func recorderRail(layout: PracticeScreenLayout) -> some View {
        HStack(alignment: .center) {
            Button {
                isPresentingRecordSheet = true
            } label: {
                recorderSideAction(
                    icon: "square.and.pencil",
                    title: "Log",
                    detail: "Notes",
                    tint: AppColors.accent,
                    size: layout.footerButtonSize
                )
            }
            .buttonStyle(.plain)

            Spacer(minLength: layout.sectionSpacing)

            Button {
                Task {
                    await viewModel.togglePerformanceRecording()
                }
            } label: {
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill((viewModel.isRecording ? AppColors.recording : AppColors.recording.opacity(0.86)).opacity(0.20))
                            .frame(width: layout.recordHaloSize, height: layout.recordHaloSize)

                        Circle()
                            .fill(viewModel.isRecording ? AppColors.recording : AppColors.recording.opacity(0.88))
                            .frame(width: layout.recordButtonSize, height: layout.recordButtonSize)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
                            )

                        Circle()
                            .stroke(Color.white.opacity(0.92), lineWidth: 4)
                            .frame(width: layout.recordCoreSize, height: layout.recordCoreSize)

                        if viewModel.isRecording {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white)
                                .frame(width: layout.recordStopGlyphSize, height: layout.recordStopGlyphSize)
                        } else {
                            Circle()
                                .fill(Color.white)
                                .frame(width: layout.recordDotSize, height: layout.recordDotSize)
                        }
                    }

                    Text(viewModel.isRecording ? "Tap to stop" : "Tap to record")
                        .font(AppTypography.captionStrong)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: layout.sectionSpacing)

            NavigationLink {
                RecordingListView(phrase: phrase, song: song, dependencies: dependencies)
            } label: {
                recorderSideAction(
                    icon: "waveform.path",
                    title: "Takes",
                    detail: "\(viewModel.recordingCount)",
                    tint: AppColors.progress,
                    size: layout.footerButtonSize
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func waveformTimeLabel(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textMuted)
            .monospacedDigit()
    }

    private func timelineMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.eyebrow)
                .tracking(1.2)
                .foregroundStyle(AppColors.textMuted)

            Text(value)
                .font(AppTypography.captionStrong)
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.24), lineWidth: 1)
        )
    }

    private func tuningColumn(
        title: String,
        value: String,
        tint: Color,
        decreaseAction: @escaping () -> Void,
        increaseAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(AppTypography.eyebrow)
                .tracking(1.4)
                .foregroundStyle(AppColors.textMuted)

            Text(value)
                .font(AppTypography.metric)
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            HStack(spacing: 16) {
                tuningButton(symbol: "minus", tint: tint, action: decreaseAction)

                Capsule()
                    .fill(AppColors.borderStrong)
                    .frame(width: 42, height: 4)

                tuningButton(symbol: "plus", tint: tint, action: increaseAction)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func tuningButton(symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(tint.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
    }

    private func transportButton(icon: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.34, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: size, height: size)
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

    private func recorderSideAction(
        icon: String,
        title: String,
        detail: String,
        tint: Color,
        size: CGFloat
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: size * 0.32, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(AppColors.surfaceMuted)
                )
                .overlay(
                    Circle()
                        .stroke(AppColors.border, lineWidth: 1)
                )

            VStack(spacing: 2) {
                Text(title)
                    .font(AppTypography.captionStrong)
                    .foregroundStyle(AppColors.textPrimary)

                Text(detail)
                    .font(AppTypography.micro)
                    .foregroundStyle(AppColors.textMuted)
                    .lineLimit(1)
            }
        }
        .frame(width: size + 14)
    }

    private func capsuleBadge(label: String, tint: Color) -> some View {
        Text(label)
            .font(AppTypography.captionStrong)
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(tint.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(tint.opacity(0.28), lineWidth: 1)
            )
    }

    private func headerButton(icon: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.34, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(AppColors.surfaceMuted.opacity(0.96))
                )
                .overlay(
                    Circle()
                        .stroke(AppColors.borderStrong, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var consoleBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        AppColors.surfaceRaised.opacity(0.96),
                        AppColors.surface.opacity(0.96),
                        AppColors.surfaceMuted.opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var consoleOverlay: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .stroke(AppColors.borderStrong, lineWidth: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(AppColors.accent.opacity(0.10), lineWidth: 1)
                    .blur(radius: 10)
            )
    }

    private var waveformValues: [Double] {
        if song.waveformOverview.isEmpty {
            return Array(repeating: 0.42, count: 52)
        }
        return song.waveformOverview
    }

    private var displaySongTitle: String {
        let trimmed = song.title.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("picked-") {
            return "Imported source"
        }

        if trimmed.count > 32 {
            return String(trimmed.prefix(32)) + "..."
        }

        return trimmed
    }

    private var displayArtistName: String {
        let artist = song.artistName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if artist.isEmpty {
            return "Practice session"
        }
        return artist
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

    private var inputMeterLabel: String {
        guard viewModel.isRecording else {
            return viewModel.hasLatestRecording ? "Live ready" : "Ready"
        }

        let clamped = min(max(viewModel.recordingInputLevel, 0), 1)
        let dbValue = Int(round(-24 + clamped * 24))
        return "\(dbValue) dB"
    }

    private var transportIconName: String {
        viewModel.isPlaying ? "pause.fill" : "play.fill"
    }
}

private struct PracticeScreenLayout {
    let size: CGSize
    let safeAreaInsets: EdgeInsets

    var availableHeight: CGFloat {
        size.height - safeAreaInsets.top - safeAreaInsets.bottom
    }

    var compact: Bool {
        availableHeight < 740
    }

    var horizontalPadding: CGFloat {
        compact ? 16 : 20
    }

    var topPadding: CGFloat {
        compact ? 6 : 10
    }

    var bottomPadding: CGFloat {
        compact ? 14 : 18
    }

    var stackSpacing: CGFloat {
        compact ? 12 : 16
    }

    var sectionSpacing: CGFloat {
        compact ? 14 : 18
    }

    var elementSpacing: CGFloat {
        compact ? 8 : 10
    }

    var consolePadding: CGFloat {
        compact ? 14 : 18
    }

    var headerButtonSize: CGFloat {
        compact ? 42 : 46
    }

    var videoHeight: CGFloat {
        min(max(availableHeight * 0.17, 104), compact ? 120 : 140)
    }

    var waveformHeight: CGFloat {
        compact ? 76 : 88
    }

    var sideTransportButtonSize: CGFloat {
        compact ? 54 : 58
    }

    var playButtonSize: CGFloat {
        compact ? 88 : 98
    }

    var playIconSize: CGFloat {
        compact ? 28 : 32
    }

    var transportSpacing: CGFloat {
        compact ? 18 : 24
    }

    var meterHeight: CGFloat {
        compact ? 16 : 18
    }

    var footerButtonSize: CGFloat {
        compact ? 50 : 54
    }

    var recordHaloSize: CGFloat {
        compact ? 92 : 102
    }

    var recordButtonSize: CGFloat {
        compact ? 72 : 78
    }

    var recordCoreSize: CGFloat {
        compact ? 30 : 34
    }

    var recordStopGlyphSize: CGFloat {
        compact ? 18 : 20
    }

    var recordDotSize: CGFloat {
        compact ? 14 : 16
    }
}
