import SwiftUI

struct PracticePlayerView: View {
    @Environment(\.dismiss) private var dismiss

    let phrase: Phrase
    let song: Song
    let dependencies: AppDependencies

    @State private var viewModel: PracticePlayerViewModel
    @State private var isPresentingRecordSheet = false
    @State private var isPresentingTakesSheet = false

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

            VStack(spacing: layout.outerSpacing) {
                topBar(layout: layout)
                practiceConsole(layout: layout)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, layout.horizontalPadding)
            .padding(.top, geometry.safeAreaInsets.top + layout.topPadding)
            .padding(.bottom, max(layout.bottomPadding, geometry.safeAreaInsets.bottom + 8))
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .studioScreen()
        .sheet(isPresented: $isPresentingRecordSheet) {
            PracticeRecordSheet(phrase: phrase, dependencies: dependencies)
        }
        .sheet(isPresented: $isPresentingTakesSheet) {
            NavigationStack {
                RecordingListView(phrase: phrase, song: song, dependencies: dependencies)
                    .navigationTitle("Saved Takes")
                    .navigationBarTitleDisplayMode(.inline)
            }
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

    private func topBar(layout: PracticeScreenLayout) -> some View {
        ZStack {
            HStack {
                headerButton(icon: "chevron.down", size: layout.headerButtonSize) {
                    dismiss()
                }

                Spacer()

                Menu {
                    Button("Log Practice") {
                        isPresentingRecordSheet = true
                    }

                    Button("Open Saved Takes") {
                        isPresentingTakesSheet = true
                    }
                } label: {
                    headerIcon(symbol: "ellipsis", size: layout.headerButtonSize)
                }
            }

            VStack(spacing: 3) {
                Text(displaySongTitle)
                    .font(layout.compact ? AppTypography.cardTitle : AppTypography.sectionTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(viewModel.phraseProgressLabel)
                    .font(AppTypography.captionStrong)
                    .foregroundStyle(AppColors.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, layout.headerButtonSize + 26)
        }
    }

    private func practiceConsole(layout: PracticeScreenLayout) -> some View {
        VStack(alignment: .leading, spacing: layout.sectionSpacing) {
            consoleTitleRow(layout: layout)
            mediaPreview(layout: layout)
            waveformStage(layout: layout)
            transportRow(layout: layout)
            loopStatusRow
            tuningPanel(layout: layout)
            inputMeterRow(layout: layout)
            recorderRail(layout: layout)
        }
        .padding(layout.consolePadding)
        .background(consoleBackground)
        .overlay(consoleOverlay)
        .shadow(color: AppColors.shadow.opacity(0.18), radius: 18, x: 0, y: 10)
    }

    private func consoleTitleRow(layout: PracticeScreenLayout) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(phrase.name)
                    .font(layout.compact ? Font.system(size: 21, weight: .bold, design: .rounded) : Font.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(displayArtistName)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            capsuleBadge(
                label: viewModel.isRecording ? "Recording" : (viewModel.isLoopEnabled ? "Loop On" : "Loop Off"),
                tint: viewModel.isRecording ? AppColors.recording : AppColors.accent
            )
        }
    }

    @ViewBuilder
    private func mediaPreview(layout: PracticeScreenLayout) -> some View {
        if let videoURL = song.videoFileURL {
            VideoPlaybackDisplayView(
                videoURL: videoURL,
                durationSec: song.durationSec,
                headPosition: viewModel.headRatio
            )
            .frame(height: layout.previewHeight)
            .clipShape(RoundedRectangle(cornerRadius: layout.previewCornerRadius, style: .continuous))
        } else if let thumbnailURL = song.thumbnailFileURL,
                  let image = UIImage(contentsOfFile: thumbnailURL.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: layout.previewHeight)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: layout.previewCornerRadius, style: .continuous))
                .overlay(previewGradientOverlay)
                .overlay(alignment: .bottomLeading) {
                    previewMeta
                        .padding(14)
                }
        } else {
            RoundedRectangle(cornerRadius: layout.previewCornerRadius, style: .continuous)
                .fill(AppColors.heroGradient)
                .frame(height: layout.previewHeight)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.28)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(alignment: .bottomLeading) {
                    previewMeta
                        .padding(14)
                }
                .overlay(alignment: .topTrailing) {
                    Image(systemName: song.sourceType == .micRecorded ? "mic.fill" : "waveform")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary.opacity(0.88))
                        .padding(14)
                }
        }
    }

    private func waveformStage(layout: PracticeScreenLayout) -> some View {
        VStack(spacing: layout.waveformSpacing) {
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
        }
    }

    private func transportRow(layout: PracticeScreenLayout) -> some View {
        HStack(spacing: layout.transportSpacing) {
            transportButton(icon: "gobackward.5", size: layout.sideTransportButtonSize) {
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
                                .stroke(AppColors.accent.opacity(0.96), lineWidth: 3)
                        )

                    Circle()
                        .fill(AppColors.accent.opacity(0.15))
                        .padding(layout.compact ? 8 : 10)

                    Image(systemName: transportIconName)
                        .font(.system(size: layout.playIconSize, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .offset(x: viewModel.isPlaying ? 0 : 2)
                }
                .frame(width: layout.playButtonSize, height: layout.playButtonSize)
                .shadow(color: AppColors.accent.opacity(0.20), radius: 12, x: 0, y: 8)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            transportButton(icon: "goforward.5", size: layout.sideTransportButtonSize) {
                viewModel.seek(by: 5)
            }
        }
    }

    private var loopStatusRow: some View {
        ZStack {
            HStack {
                Spacer()

                if viewModel.isRecording {
                    Text("REC \(Formatting.duration(viewModel.recordingElapsedSec))")
                        .font(AppTypography.captionStrong)
                        .foregroundStyle(AppColors.recording)
                        .monospacedDigit()
                }
            }

            HStack(spacing: 10) {
                Button {
                    viewModel.toggleLoop()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "repeat")
                            .font(.system(size: 12, weight: .semibold))
                        Text(viewModel.isLoopEnabled ? "Loop A-B" : "Loop Off")
                            .font(AppTypography.captionStrong)
                    }
                    .foregroundStyle(viewModel.isLoopEnabled ? AppColors.accent : AppColors.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(viewModel.isLoopEnabled ? AppColors.accent.opacity(0.14) : AppColors.surfaceMuted)
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                viewModel.isLoopEnabled ? AppColors.accent.opacity(0.28) : AppColors.border,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)

                Text(viewModel.loopDurationLabel)
                    .font(AppTypography.captionStrong)
                    .foregroundStyle(AppColors.textSecondary)
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
                layout: layout,
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
                .padding(.vertical, 10)

            tuningColumn(
                title: "Pitch",
                value: pitchLabel,
                tint: AppColors.progress,
                layout: layout,
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

            Text("INPUT")
                .font(AppTypography.eyebrow)
                .tracking(1.4)
                .foregroundStyle(AppColors.textMuted)

            InputLevelMeterView(level: viewModel.recordingInputLevel, isActive: viewModel.isRecording)
                .frame(height: layout.meterHeight)

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
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill((viewModel.isRecording ? AppColors.recording : AppColors.recording.opacity(0.86)).opacity(0.18))
                            .frame(width: layout.recordHaloSize, height: layout.recordHaloSize)

                        Circle()
                            .fill(viewModel.isRecording ? AppColors.recording : AppColors.recording.opacity(0.90))
                            .frame(width: layout.recordButtonSize, height: layout.recordButtonSize)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )

                        Circle()
                            .stroke(Color.white.opacity(0.94), lineWidth: 4)
                            .frame(width: layout.recordCoreSize, height: layout.recordCoreSize)

                        if viewModel.isRecording {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.white)
                                .frame(width: layout.recordStopGlyphSize, height: layout.recordStopGlyphSize)
                        } else {
                            Circle()
                                .fill(Color.white)
                                .frame(width: layout.recordDotSize, height: layout.recordDotSize)
                        }
                    }

                    Text(viewModel.isRecording ? "Tap to stop" : "Tap to record")
                        .font(AppTypography.micro)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: layout.sectionSpacing)

            Button {
                isPresentingTakesSheet = true
            } label: {
                recorderSideAction(
                    icon: "waveform.path",
                    title: "Takes",
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

    private func tuningColumn(
        title: String,
        value: String,
        tint: Color,
        layout: PracticeScreenLayout,
        decreaseAction: @escaping () -> Void,
        increaseAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: layout.compact ? 10 : 12) {
            Text(title.uppercased())
                .font(AppTypography.eyebrow)
                .tracking(1.4)
                .foregroundStyle(AppColors.textMuted)

            Text(value)
                .font(layout.compact ? Font.system(size: 26, weight: .bold, design: .rounded) : AppTypography.metric)
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            HStack(spacing: 14) {
                tuningButton(symbol: "minus", tint: tint, size: layout.tuningButtonSize, action: decreaseAction)

                Capsule()
                    .fill(AppColors.borderStrong)
                    .frame(width: layout.tuningTrackWidth, height: 4)

                tuningButton(symbol: "plus", tint: tint, size: layout.tuningButtonSize, action: increaseAction)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, layout.compact ? 12 : 14)
    }

    private func tuningButton(symbol: String, tint: Color, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.40, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
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
        tint: Color,
        size: CGFloat
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: size * 0.34, weight: .semibold))
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

            Text(title)
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
        }
        .frame(width: size + 10)
    }

    private func capsuleBadge(label: String, tint: Color) -> some View {
        Text(label)
            .font(AppTypography.captionStrong)
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
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
            headerIcon(symbol: icon, size: size)
        }
        .buttonStyle(.plain)
    }

    private func headerIcon(symbol: String, size: CGFloat) -> some View {
        Image(systemName: symbol)
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

    private var consoleBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        AppColors.surfaceRaised.opacity(0.96),
                        AppColors.surface.opacity(0.97),
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
    }

    private var previewGradientOverlay: some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color.black.opacity(0.12),
                Color.black.opacity(0.34)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var previewMeta: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(phrase.name)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)

            Text(rangeLabel)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .monospacedDigit()
        }
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

        if trimmed.count > 28 {
            return String(trimmed.prefix(28)) + "..."
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
        availableHeight < 900
    }

    var horizontalPadding: CGFloat {
        compact ? 16 : 18
    }

    var topPadding: CGFloat {
        compact ? 2 : 6
    }

    var bottomPadding: CGFloat {
        compact ? 12 : 16
    }

    var outerSpacing: CGFloat {
        compact ? 12 : 14
    }

    var sectionSpacing: CGFloat {
        compact ? 12 : 14
    }

    var waveformSpacing: CGFloat {
        compact ? 7 : 8
    }

    var consolePadding: CGFloat {
        compact ? 14 : 16
    }

    var headerButtonSize: CGFloat {
        compact ? 40 : 44
    }

    var previewHeight: CGFloat {
        compact ? 92 : 108
    }

    var previewCornerRadius: CGFloat {
        20
    }

    var waveformHeight: CGFloat {
        compact ? 68 : 76
    }

    var sideTransportButtonSize: CGFloat {
        compact ? 46 : 50
    }

    var playButtonSize: CGFloat {
        compact ? 82 : 90
    }

    var playIconSize: CGFloat {
        compact ? 28 : 30
    }

    var transportSpacing: CGFloat {
        compact ? 14 : 18
    }

    var tuningButtonSize: CGFloat {
        compact ? 28 : 30
    }

    var tuningTrackWidth: CGFloat {
        compact ? 48 : 54
    }

    var meterHeight: CGFloat {
        compact ? 16 : 18
    }

    var footerButtonSize: CGFloat {
        compact ? 44 : 48
    }

    var recordHaloSize: CGFloat {
        compact ? 86 : 94
    }

    var recordButtonSize: CGFloat {
        compact ? 66 : 72
    }

    var recordCoreSize: CGFloat {
        compact ? 28 : 32
    }

    var recordStopGlyphSize: CGFloat {
        compact ? 16 : 18
    }

    var recordDotSize: CGFloat {
        compact ? 14 : 16
    }
}
