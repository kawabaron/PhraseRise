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
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                StudioSectionHeader("練習区間を作成", subtitle: "A/B 範囲を決めて、難所を練習区間として保存します。")

                StudioCard(emphasisColor: AppColors.accent) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("波形を見ながら範囲を調整")
                            .font(AppTypography.cardTitle)

                        WaveformPlaceholderView(
                            values: viewModel.waveformValues,
                            selection: viewModel.startRatio ... viewModel.endRatio
                        )
                        .frame(height: 220)
                    }
                }

                StudioCard {
                    VStack(alignment: .leading, spacing: 14) {
                        rangeEditor(
                            title: "開始位置",
                            value: $viewModel.startRatio,
                            range: 0 ... max(viewModel.endRatio - 0.02, 0.01),
                            onMinus: { viewModel.nudgeStart(by: -0.1) },
                            onPlus: { viewModel.nudgeStart(by: 0.1) }
                        )

                        rangeEditor(
                            title: "終了位置",
                            value: $viewModel.endRatio,
                            range: min(viewModel.startRatio + 0.02, 0.99) ... 1,
                            onMinus: { viewModel.nudgeEnd(by: -0.1) },
                            onPlus: { viewModel.nudgeEnd(by: 0.1) }
                        )
                    }
                }

                StudioCard {
                    VStack(alignment: .leading, spacing: 14) {
                        textField(title: "練習区間名", text: $viewModel.name)
                        textField(title: "メモ", text: $viewModel.memo)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("目標 BPM")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                            Stepper(value: $viewModel.targetBpm, in: 40 ... 240, step: 1) {
                                Text("\(viewModel.targetBpm) BPM")
                            }
                        }

                        HStack {
                            infoPill("A", value: Formatting.duration(viewModel.startTimeSec))
                            infoPill("B", value: Formatting.duration(viewModel.endTimeSec))
                            infoPill("長さ", value: Formatting.duration(viewModel.selectedDurationSec))
                        }
                    }
                }

                Button("練習区間を保存") {
                    if viewModel.savePhrase() != nil {
                        dismiss()
                    }
                }
                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, 120)
        }
        .navigationTitle("練習区間エディタ")
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

    private func rangeEditor(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        onMinus: @escaping () -> Void,
        onPlus: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)

            Slider(value: value, in: range)
                .tint(AppColors.accent)

            HStack {
                Button("-0.1s", action: onMinus)
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceGlass))
                Button("+0.1s", action: onPlus)
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceGlass))
            }
        }
    }

    private func textField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            TextField(title, text: text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppColors.surfaceGlass.opacity(0.78))
                )
        }
    }

    private func infoPill(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surfaceGlass.opacity(0.82))
        )
    }
}
