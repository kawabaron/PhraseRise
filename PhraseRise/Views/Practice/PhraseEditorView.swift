import SwiftUI

struct PhraseEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let dependencies: AppDependencies
    @State private var viewModel: PhraseEditorViewModel

    init(song: Song, phrase: Phrase? = nil, dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: PhraseEditorViewModel(song: song, phrase: phrase, dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection

                waveformBlock
                    .padding(.top, AppSpacing.xLarge)

                rangeBlock
                    .padding(.top, AppSpacing.xLarge)

                detailsBlock
                    .padding(.top, AppSpacing.xLarge)

                saveButton
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.xLarge)
            }
            .padding(.bottom, 120)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .studioScreen()
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
        .alert(
            "保存エラー",
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
        VStack(alignment: .leading, spacing: 10) {
            Text("PHRASE EDITOR")
                .font(AppTypography.eyebrow)
                .tracking(2)
                .foregroundStyle(AppColors.textMuted)

            Text("練習区間を作成")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            Text("A/B 範囲を決めて、難所を練習区間として保存します。")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.medium)
        .padding(.bottom, AppSpacing.large)
        .background(
            RadialGradient(
                colors: [
                    AppColors.accent.opacity(0.22),
                    Color.clear
                ],
                center: UnitPoint(x: 0.1, y: 0.0),
                startRadius: 10,
                endRadius: 380
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - Sections

    private var waveformBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            sectionEyebrow("WAVEFORM")

            WaveformPlaceholderView(
                values: viewModel.waveformValues,
                selection: viewModel.startRatio ... viewModel.endRatio
            )
            .frame(height: 200)
            .padding(.horizontal, AppSpacing.screenHorizontal)
        }
    }

    private var rangeBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            sectionEyebrow("RANGE")

            VStack(alignment: .leading, spacing: AppSpacing.large) {
                rangeEditor(
                    title: "開始位置 (A)",
                    valueLabel: Formatting.duration(viewModel.startTimeSec),
                    value: $viewModel.startRatio,
                    range: 0 ... max(viewModel.endRatio - 0.02, 0.01),
                    onMinus: { viewModel.nudgeStart(by: -0.1) },
                    onPlus: { viewModel.nudgeStart(by: 0.1) }
                )

                rangeEditor(
                    title: "終了位置 (B)",
                    valueLabel: Formatting.duration(viewModel.endTimeSec),
                    value: $viewModel.endRatio,
                    range: min(viewModel.startRatio + 0.02, 0.99) ... 1,
                    onMinus: { viewModel.nudgeEnd(by: -0.1) },
                    onPlus: { viewModel.nudgeEnd(by: 0.1) }
                )

                HStack(spacing: 10) {
                    rangePill(label: "A", value: Formatting.duration(viewModel.startTimeSec))
                    rangePill(label: "B", value: Formatting.duration(viewModel.endTimeSec))
                    rangePill(label: "長さ", value: Formatting.duration(viewModel.selectedDurationSec))
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
        }
    }

    private var detailsBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            sectionEyebrow("DETAILS")

            VStack(alignment: .leading, spacing: AppSpacing.large) {
                fieldGroup(title: "練習区間名") {
                    TextField("名称", text: $viewModel.name, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AppColors.surface.opacity(0.7))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                }

                fieldGroup(title: "メモ") {
                    TextField("メモを書く", text: $viewModel.memo, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(3 ... 6)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AppColors.surface.opacity(0.7))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                }

                fieldGroup(title: "目標 BPM") {
                    HStack {
                        Text("\(viewModel.targetBpm) BPM")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Stepper("", value: $viewModel.targetBpm, in: 40 ... 240, step: 1)
                            .labelsHidden()
                            .tint(AppColors.accent)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
        }
    }

    private var saveButton: some View {
        Button {
            if viewModel.savePhrase() != nil {
                dismiss()
            }
        } label: {
            Text("練習区間を保存")
                .font(.system(.headline, design: .rounded).weight(.semibold))
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

    // MARK: - Helpers

    private func sectionEyebrow(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.eyebrow)
            .tracking(2)
            .foregroundStyle(AppColors.textMuted)
            .padding(.horizontal, AppSpacing.screenHorizontal)
    }

    private func rangeEditor(
        title: String,
        valueLabel: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        onMinus: @escaping () -> Void,
        onPlus: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text(valueLabel)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }

            Slider(value: value, in: range)
                .tint(AppColors.accent)

            HStack(spacing: 6) {
                nudgeButton(label: "-0.1s", action: onMinus)
                nudgeButton(label: "+0.1s", action: onPlus)
                Spacer(minLength: 0)
            }
        }
    }

    private func nudgeButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(AppColors.surface))
                .overlay(Capsule().stroke(AppColors.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func rangePill(label: String, value: String) -> some View {
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

    private func fieldGroup<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            content()
        }
    }
}
