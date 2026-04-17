import Charts
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
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                StudioSectionHeader("上達の見える化", subtitle: "回数、時間、stable率をまとめて確認できます。")

                filtersCard

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.medium) {
                    MetricTile(title: "総練習回数", value: "\(viewModel.totalPracticeCount)", tint: AppColors.accent)
                    MetricTile(title: "総練習時間", value: "\(viewModel.totalPracticeSeconds / 60) 分", tint: AppColors.success)
                    MetricTile(title: "stable到達率", value: "\(Int(viewModel.stableRate * 100))%", tint: AppColors.warning)
                    MetricTile(title: "録音数", value: "\(viewModel.recordingCount)", tint: AppColors.recording)
                }

                StudioSectionHeader("BPM 推移")

                StudioCard {
                    if viewModel.recentStableTrend.isEmpty {
                        Text("練習記録が増えると、ここに BPM 推移が表示されます。")
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Chart(viewModel.recentStableTrend) { point in
                            AreaMark(
                                x: .value("Date", point.label),
                                y: .value("BPM", point.bpm)
                            )
                            .foregroundStyle(AppColors.accent.opacity(0.18))

                            LineMark(
                                x: .value("Date", point.label),
                                y: .value("BPM", point.bpm)
                            )
                            .foregroundStyle(AppColors.accent)

                            PointMark(
                                x: .value("Date", point.label),
                                y: .value("BPM", point.bpm)
                            )
                            .foregroundStyle(AppColors.success)
                        }
                        .frame(height: 240)
                    }
                }

                if !viewModel.isPremium {
                    StudioCard {
                        Text("全期間グラフと詳細な比較再生は Premium で利用できます。無料版でも練習記録の保存と直近の変化確認は可能です。")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, 120)
        }
        .navigationTitle("Stats")
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

    private var filtersCard: some View {
        StudioCard {
            VStack(alignment: .leading, spacing: 14) {
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

                Picker(
                    "曲",
                    selection: Binding(
                        get: { viewModel.selectedSongID },
                        set: { viewModel.selectSong($0) }
                    )
                ) {
                    Text("すべての曲").tag(Optional<UUID>.none)
                    ForEach(viewModel.songs, id: \.id) { song in
                        Text(song.title).tag(song.id as UUID?)
                    }
                }
                .pickerStyle(.menu)

                Picker(
                    "Phrase",
                    selection: Binding(
                        get: { viewModel.selectedPhraseID },
                        set: { viewModel.selectPhrase($0) }
                    )
                ) {
                    Text("すべての Phrase").tag(Optional<UUID>.none)
                    ForEach(viewModel.availablePhrases, id: \.id) { phrase in
                        Text(phrase.name).tag(phrase.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
}
