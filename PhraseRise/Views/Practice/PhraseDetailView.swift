import Charts
import SwiftUI

struct PhraseDetailView: View {
    let dependencies: AppDependencies
    @State private var viewModel: PhraseDetailViewModel

    init(phrase: Phrase, song: Song, dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: PhraseDetailViewModel(phrase: phrase, song: song, dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection

                practiceButton
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.large)

                suggestionNote
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.medium)

                metricsList
                    .padding(.top, AppSpacing.xLarge)

                chartSection
                    .padding(.top, AppSpacing.xLarge)

                historySection
                    .padding(.top, AppSpacing.xLarge)

                recordingsRow
                    .padding(.top, AppSpacing.xLarge)
            }
            .padding(.bottom, 120)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .studioScreen()
        .task {
            viewModel.refresh()
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.song.title.uppercased())
                    .font(AppTypography.eyebrow)
                    .tracking(2)
                    .foregroundStyle(AppColors.textMuted)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Circle()
                        .fill(viewModel.phrase.status.tint)
                        .frame(width: 10, height: 10)

                    Text(viewModel.phrase.name)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(2)
                }

                Text(viewModel.phrase.status.label)
                    .font(AppTypography.caption)
                    .foregroundStyle(viewModel.phrase.status.tint)
            }

            HStack(spacing: 12) {
                heroPill(
                    label: "範囲",
                    value: "\(Formatting.duration(viewModel.phrase.startTimeSec)) – \(Formatting.duration(viewModel.phrase.endTimeSec))"
                )
                heroPill(
                    label: "目標",
                    value: bpmText(viewModel.phrase.targetBpm)
                )
                Spacer(minLength: 0)
            }

            if let memo = viewModel.phrase.memo, !memo.isEmpty {
                Text(memo)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.medium)
        .padding(.bottom, AppSpacing.large)
        .background(
            RadialGradient(
                colors: [
                    viewModel.phrase.status.tint.opacity(0.22),
                    Color.clear
                ],
                center: UnitPoint(x: 0.1, y: 0.0),
                startRadius: 10,
                endRadius: 380
            )
            .ignoresSafeArea(edges: .top)
        )
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

    // MARK: - Practice CTA & suggestion

    private var practiceButton: some View {
        NavigationLink {
            PracticePlayerView(phrase: viewModel.phrase, song: viewModel.song, dependencies: dependencies)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("練習をはじめる")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
            }
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.accent)
            )
        }
        .buttonStyle(.plain)
    }

    private var suggestionNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "arrow.up.forward.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.accent)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text("次回提案")
                    .font(AppTypography.eyebrow)
                    .tracking(1)
                    .foregroundStyle(AppColors.textMuted)
                Text(viewModel.nextSuggestionSummary)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Metrics

    private var metricsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionEyebrow("成績")

            metricRow("前回安定 BPM", value: bpmText(viewModel.phrase.lastStableBpm), valueTint: AppColors.accent)
            hairline
            metricRow("最高安定 BPM", value: bpmText(viewModel.phrase.bestStableBpm), valueTint: AppColors.success)
            hairline
            metricRow("安定率", value: "\(viewModel.stableRate)%", valueTint: AppColors.warning)
            hairline
            metricRow("練習時間", value: "\(viewModel.totalPracticeMinutes)分", valueTint: AppColors.textPrimary)
        }
    }

    private func metricRow(_ label: String, value: String, valueTint: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(valueTint)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, 14)
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            sectionEyebrow("BPM 推移")

            if viewModel.chartPoints.isEmpty {
                Text("PracticeRecord を保存するとグラフが表示されます。")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.vertical, AppSpacing.large)
            } else {
                Chart(viewModel.chartPoints) { point in
                    AreaMark(
                        x: .value("Date", point.label),
                        y: .value("BPM", point.bpm)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.accent.opacity(0.28), AppColors.accent.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Date", point.label),
                        y: .value("BPM", point.bpm)
                    )
                    .foregroundStyle(AppColors.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    PointMark(
                        x: .value("Date", point.label),
                        y: .value("BPM", point.bpm)
                    )
                    .foregroundStyle(AppColors.accent)
                    .symbolSize(30)
                }
                .frame(height: 200)
                .padding(.horizontal, AppSpacing.screenHorizontal)
            }

            if !viewModel.isPremium && viewModel.practiceRecords.count > 8 {
                Text("無料版では直近の履歴を中心に表示しています。")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.horizontal, AppSpacing.screenHorizontal)
            }
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionEyebrow("練習履歴")

            if viewModel.practiceRecords.isEmpty {
                Text("まだ練習記録がありません。")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.vertical, AppSpacing.large)
            } else {
                let records = Array(viewModel.practiceRecords.prefix(6))
                ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                    practiceRow(record)
                    if index < records.count - 1 {
                        hairline
                    }
                }
            }
        }
    }

    private func practiceRow(_ record: PracticeRecord) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(record.resultType.tint)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(record.triedBpm) BPM")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)

                HStack(spacing: 6) {
                    Text(Formatting.date(record.practicedAt))
                    Text("·")
                    Text(record.resultType.label)
                        .foregroundStyle(record.resultType.tint)
                    Text("·")
                    Text("\(record.practiceDurationSec / 60)分")
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
                .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Recordings link

    private var recordingsRow: some View {
        NavigationLink {
            RecordingListView(phrase: viewModel.phrase, song: viewModel.song, dependencies: dependencies)
        } label: {
            HStack(spacing: 14) {
                Circle()
                    .fill(AppColors.recording)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 3) {
                    Text("演奏録音")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("\(viewModel.recordings.count) 件")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textMuted)
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sectionEyebrow(_ text: String) -> some View {
        Text(text.uppercased())
            .font(AppTypography.eyebrow)
            .tracking(2)
            .foregroundStyle(AppColors.textMuted)
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.bottom, AppSpacing.small)
    }

    private var hairline: some View {
        Rectangle()
            .fill(AppColors.border)
            .frame(height: 0.5)
            .padding(.leading, AppSpacing.screenHorizontal + 22)
    }

    private func bpmText(_ bpm: Int?) -> String {
        bpm.map { "\($0) BPM" } ?? "--"
    }
}
