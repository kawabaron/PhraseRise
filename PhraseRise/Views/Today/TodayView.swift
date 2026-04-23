import SwiftUI

struct TodayView: View {
    let dependencies: AppDependencies

    @State private var viewModel: TodayViewModel
    @State private var selectedFilter: TodayPhraseFilter = .active

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: TodayViewModel(dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection

                if viewModel.hasContent {
                    if let resumeItem = viewModel.resumeItem {
                        resumeSection(resumeItem)
                            .padding(.top, AppSpacing.large)
                    }

                    focusSection
                        .padding(.top, AppSpacing.xLarge)

                    recentSourcesSection
                        .padding(.top, AppSpacing.xLarge)

                    weeklyProgressSection
                        .padding(.top, AppSpacing.xLarge)
                } else {
                    emptyState
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                        .padding(.top, AppSpacing.large)
                }
            }
            .padding(.bottom, 120)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .studioScreen()
        .task {
            viewModel.refresh()
        }
        .onAppear {
            viewModel.refresh()
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: 8) {
                Text("TODAY")
                    .font(AppTypography.eyebrow)
                    .tracking(2)
                    .foregroundStyle(AppColors.textMuted)

                Text("Stay inside the phrase.")
                    .font(AppTypography.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Pick up where you left off, tighten the tricky phrases, and keep the streak moving.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    StudioInlineMetricPill(
                        icon: "music.note.list",
                        title: "Sources",
                        value: "\(viewModel.totalSourceCount)"
                    )
                    StudioInlineMetricPill(
                        icon: "waveform",
                        title: "Active Phrases",
                        value: "\(viewModel.activePhraseCount)"
                    )
                    StudioInlineMetricPill(
                        icon: "flame.fill",
                        title: "Streak",
                        value: "\(viewModel.weeklySummary.streakDays) days",
                        tint: AppColors.progress
                    )
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
            }
            .padding(.horizontal, -AppSpacing.screenHorizontal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.medium)
        .padding(.bottom, AppSpacing.small)
    }

    private func resumeSection(_ summary: TodayViewModel.FocusPhrase) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            StudioSectionHeader("Resume Practice", subtitle: "Jump straight back into your latest phrase.")
                .padding(.horizontal, AppSpacing.screenHorizontal)

            NavigationLink {
                PracticePlayerView(phrase: summary.phrase, song: summary.song, dependencies: dependencies)
            } label: {
                StudioCard(emphasisColor: AppColors.accent) {
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(summary.song.title)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textMuted)
                                .lineLimit(1)

                            Text(summary.phrase.name)
                                .font(AppTypography.sectionTitle)
                                .foregroundStyle(AppColors.textPrimary)
                                .lineLimit(2)
                        }

                        HStack(spacing: AppSpacing.small) {
                            summaryRangePill(summary)
                            summarySignalPill(summary)
                        }

                        HStack {
                            Text(resumeHint(for: summary))
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textSecondary)

                            Spacer(minLength: 12)

                            HStack(spacing: 8) {
                                Text("Resume")
                                Image(systemName: "play.fill")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(AppColors.accent)
                            )
                            .foregroundStyle(Color.black)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.screenHorizontal)
        }
    }

    private var focusSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            StudioSectionHeader("Focus Phrases", subtitle: "Keep your next few reps obvious and easy to start.")
                .padding(.horizontal, AppSpacing.screenHorizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TodayPhraseFilter.allCases) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            StudioFilterPill(
                                title: filter.title,
                                value: "\(viewModel.count(for: filter))",
                                tint: tint(for: filter),
                                isSelected: selectedFilter == filter
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
            }
            .padding(.horizontal, -AppSpacing.screenHorizontal)

            if filteredFocusPhrases.isEmpty {
                StudioCard(emphasisColor: tint(for: selectedFilter)) {
                    Text(emptyMessage(for: selectedFilter))
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
            } else {
                VStack(spacing: AppSpacing.medium) {
                    ForEach(filteredFocusPhrases) { summary in
                        NavigationLink {
                            PracticePlayerView(phrase: summary.phrase, song: summary.song, dependencies: dependencies)
                        } label: {
                            FocusPhraseCard(
                                summary: summary,
                                tint: tint(for: selectedFilter)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
            }
        }
    }

    private var filteredFocusPhrases: [TodayViewModel.FocusPhrase] {
        Array(viewModel.focusPhrases(for: selectedFilter).prefix(4))
    }

    private var recentSourcesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            StudioSectionHeader("Recent Sources", subtitle: "The material you have touched most recently.")
                .padding(.horizontal, AppSpacing.screenHorizontal)

            VStack(spacing: AppSpacing.medium) {
                ForEach(viewModel.recentSources) { source in
                    NavigationLink {
                        SongDetailView(song: source.song, dependencies: dependencies)
                    } label: {
                        RecentSourceCard(source: source)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
        }
    }

    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            StudioSectionHeader("Weekly Progress", subtitle: "A fast read on your momentum this week.")
                .padding(.horizontal, AppSpacing.screenHorizontal)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: AppSpacing.medium),
                    GridItem(.flexible(), spacing: AppSpacing.medium)
                ],
                spacing: AppSpacing.medium
            ) {
                MetricTile(
                    title: "Sessions",
                    value: "\(viewModel.weeklySummary.practiceSessions)",
                    tint: AppColors.accent
                )
                MetricTile(
                    title: "Minutes",
                    value: "\(viewModel.weeklySummary.practiceMinutes)m",
                    tint: AppColors.progress
                )
                MetricTile(
                    title: "Recordings",
                    value: "\(viewModel.weeklySummary.recordings)",
                    tint: AppColors.recording
                )
                MetricTile(
                    title: "Streak",
                    value: "\(viewModel.weeklySummary.streakDays)d",
                    tint: AppColors.success
                )
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
        }
    }

    private var emptyState: some View {
        StudioCard(emphasisColor: AppColors.accent) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("No practice material yet.")
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Add a song or video in Library, then carve out the phrases you want to repeat.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private func tint(for filter: TodayPhraseFilter) -> Color {
        switch filter {
        case .active:
            return AppColors.accent
        case .needsWork:
            return AppColors.progress
        case .mastered:
            return AppColors.success
        }
    }

    private func emptyMessage(for filter: TodayPhraseFilter) -> String {
        switch filter {
        case .active:
            return "Your active phrase list is clear right now. Add a new phrase from Library when you are ready."
        case .needsWork:
            return "Nothing is currently flagged as needing work. Nice."
        case .mastered:
            return "No mastered phrases yet. Keep stacking stable reps."
        }
    }

    private func resumeHint(for summary: TodayViewModel.FocusPhrase) -> String {
        if let latestResult = summary.latestPracticeRecord?.resultType {
            switch latestResult {
            case .failed:
                return "Last rep slipped. Tighten this phrase while it is still fresh."
            case .barely:
                return "You were close last time. One more steady pass should help."
            case .stable:
                return "This phrase is holding together. Keep the momentum warm."
            }
        }
        return "No saved practice yet. Start building the phrase from the loop."
    }

    private func summaryRangePill(_ summary: TodayViewModel.FocusPhrase) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "repeat")
                .font(.system(size: 11, weight: .semibold))
            Text("\(Formatting.duration(summary.phrase.startTimeSec)) - \(Formatting.duration(summary.phrase.endTimeSec))")
                .monospacedDigit()
        }
        .font(AppTypography.captionStrong)
        .foregroundStyle(AppColors.textPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AppColors.surfaceMuted)
        )
        .overlay(
            Capsule()
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    private func summarySignalPill(_ summary: TodayViewModel.FocusPhrase) -> some View {
        let tint = summary.isNeedsWork ? AppColors.progress : AppColors.success

        return HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)
            Text(summary.isNeedsWork ? "Needs attention" : "In motion")
        }
        .font(AppTypography.captionStrong)
        .foregroundStyle(tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(tint.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(tint.opacity(0.32), lineWidth: 1)
        )
    }
}

private struct FocusPhraseCard: View {
    let summary: TodayViewModel.FocusPhrase
    let tint: Color

    var body: some View {
        StudioCard(emphasisColor: tint) {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                HStack(alignment: .top, spacing: AppSpacing.small) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(summary.phrase.name)
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(2)

                        Text(summary.song.title)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppColors.accent)
                }

                HStack(spacing: 10) {
                    phraseStatusPill
                    if summary.weeklyPracticeMinutes > 0 {
                        infoPill(
                            icon: "clock",
                            text: "\(summary.weeklyPracticeMinutes)m this week",
                            tint: AppColors.progress
                        )
                    }
                }

                HStack {
                    Text(rangeText)
                        .font(AppTypography.captionStrong)
                        .foregroundStyle(AppColors.textPrimary)
                        .monospacedDigit()

                    Spacer(minLength: 10)

                    Text(activityText)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                        .lineLimit(1)
                }
            }
        }
    }

    private var rangeText: String {
        "\(Formatting.duration(summary.phrase.startTimeSec)) - \(Formatting.duration(summary.phrase.endTimeSec))"
    }

    private var activityText: String {
        if let lastActivityDate = summary.lastActivityDate {
            return "Last activity \(Formatting.relativeDate(lastActivityDate))"
        }
        return "No activity yet"
    }

    private var phraseStatusPill: some View {
        let tint = statusTint

        return infoPill(
            icon: "circle.fill",
            text: summary.phrase.status == .mastered ? "Mastered" : "Ready",
            tint: tint
        )
    }

    private var statusTint: Color {
        switch summary.phrase.status {
        case .active:
            return summary.isNeedsWork ? AppColors.progress : AppColors.accent
        case .mastered:
            return AppColors.success
        case .archived:
            return AppColors.warning
        }
    }

    private func infoPill(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
        }
        .font(AppTypography.captionStrong)
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
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
}

private struct RecentSourceCard: View {
    let source: TodayViewModel.RecentSource

    var body: some View {
        StudioCard(emphasisColor: source.song.sourceType == .micRecorded ? AppColors.recording : AppColors.accent) {
            HStack(spacing: AppSpacing.medium) {
                sourceArtwork

                VStack(alignment: .leading, spacing: 6) {
                    Text(source.song.title)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)

                    Text(sourceSubtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)

                    Text("\(source.phraseCount) phrases | \(source.activePhraseCount) active")
                        .font(AppTypography.captionStrong)
                        .foregroundStyle(AppColors.textMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textMuted)
            }
        }
    }

    @ViewBuilder
    private var sourceArtwork: some View {
        if let thumbnailURL = source.song.thumbnailFileURL,
           let image = UIImage(contentsOfFile: thumbnailURL.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppColors.borderStrong, lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            source.song.sourceType == .micRecorded ? AppColors.recordingSoft : AppColors.accentSoft,
                            AppColors.surfaceInteractive
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: source.song.sourceType == .micRecorded ? "mic.fill" : "music.note")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                }
        }
    }

    private var sourceSubtitle: String {
        let leading = source.song.artistName?.isEmpty == false
            ? source.song.artistName ?? source.song.sourceType.label
            : source.song.sourceType.label
        return "\(leading) | \(Formatting.relativeDate(source.song.updatedAt))"
    }
}
