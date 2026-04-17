import Charts
import SwiftUI

struct StatsView: View {
    @State private var viewModel: StatsViewModel

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: StatsViewModel(dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                StudioSectionHeader("上達の可視化", subtitle: "MVP では全体の伸びを最初に見せる")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.medium) {
                    MetricTile(title: "総練習回数", value: "\(viewModel.totalPracticeCount)", tint: AppColors.accent)
                    MetricTile(title: "総練習時間", value: "\(viewModel.totalPracticeSeconds / 60) 分", tint: AppColors.success)
                    MetricTile(title: "stable 到達率", value: "\(Int(viewModel.stableRate * 100))%", tint: AppColors.warning)
                    MetricTile(title: "録音数", value: "\(viewModel.recordingCount)", tint: AppColors.recording)
                }

                StudioSectionHeader("最近の BPM 推移")
                StudioCard {
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
                    }
                    .frame(height: 240)
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
    }
}
