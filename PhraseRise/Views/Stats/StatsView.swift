import SwiftUI

struct StatsView: View {
    let dependencies: AppDependencies
    @State private var viewModel: StatsViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: StatsViewModel(dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                filtersStrip
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.large)

                secondaryMetrics
                    .padding(.top, AppSpacing.xLarge)

                if !viewModel.isPremium {
                    premiumHint
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
    }

    private var filtersStrip: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Picker(
                "期間",
                selection: Binding(
                    get: { viewModel.selectedPeriod },
                    set: { _ = viewModel.selectPeriod($0) }
                )
            ) {
                ForEach(StatsPeriodFilter.allCases) { period in
                    Text(period.title).tag(period)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: AppSpacing.small) {
                filterMenu(
                    title: viewModel.songs.first(where: { $0.id == viewModel.selectedSongID })?.title ?? "すべての曲",
                    isActive: viewModel.selectedSongID != nil
                ) {
                    Button("すべての曲") { viewModel.selectSong(nil) }
                    ForEach(viewModel.songs, id: \.id) { song in
                        Button(song.title) { viewModel.selectSong(song.id) }
                    }
                }

                filterMenu(
                    title: viewModel.availablePhrases.first(where: { $0.id == viewModel.selectedPhraseID })?.name ?? "すべての区間",
                    isActive: viewModel.selectedPhraseID != nil
                ) {
                    Button("すべての区間") { viewModel.selectPhrase(nil) }
                    ForEach(viewModel.availablePhrases, id: \.id) { phrase in
                        Button(phrase.name) { viewModel.selectPhrase(phrase.id) }
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    private func filterMenu<Content: View>(
        title: String,
        isActive: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(isActive ? AppColors.accent : AppColors.textSecondary)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isActive ? AppColors.accent : AppColors.textMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(AppColors.surface.opacity(isActive ? 1.0 : 0.7))
            )
            .overlay(
                Capsule().stroke(isActive ? AppColors.accent.opacity(0.4) : AppColors.border, lineWidth: 1)
            )
        }
    }

    private var secondaryMetrics: some View {
        VStack(spacing: 0) {
            metricRow(label: "練習セッション", value: "\(viewModel.totalPracticeCount)")
            hairline
            metricRow(label: "練習時間", value: formatPracticeTime(viewModel.totalPracticeSeconds))
            hairline
            metricRow(label: "録音数", value: "\(viewModel.recordingCount)")
        }
    }

    private func metricRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, 14)
    }

    private var hairline: some View {
        Rectangle()
            .fill(AppColors.border)
            .frame(height: 0.5)
            .padding(.leading, AppSpacing.screenHorizontal)
    }

    private var premiumHint: some View {
        Text("全期間の集計と詳細な比較再生は Premium で利用できます。")
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.screenHorizontal)
    }

    private func formatPracticeTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)分"
        }
        let hours = minutes / 60
        let remainder = minutes % 60
        if remainder == 0 {
            return "\(hours)時間"
        }
        return "\(hours)時間\(remainder)分"
    }
}
