import SwiftUI

struct PhraseEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PhraseEditorViewModel

    init(song: Song, phrase: Phrase? = nil, dependencies: AppDependencies) {
        _viewModel = State(initialValue: PhraseEditorViewModel(song: song, phrase: phrase, dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                StudioSectionHeader("Phrase を切り出し", subtitle: "A/B を決めて、そのまま練習フレーズとして保存")

                WaveformPlaceholderView(
                    values: viewModel.waveformValues,
                    selection: viewModel.startRatio ... viewModel.endRatio
                )
                .frame(height: 220)

                StudioCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("範囲調整")
                            .font(AppTypography.cardTitle)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("開始位置")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                            Slider(value: $viewModel.startRatio, in: 0 ... max(viewModel.endRatio - 0.02, 0.01))
                                .tint(AppColors.accent)

                            HStack {
                                Button("-0.1s") {
                                    viewModel.nudgeStart(by: -0.1)
                                }
                                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceRaised))

                                Button("+0.1s") {
                                    viewModel.nudgeStart(by: 0.1)
                                }
                                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceRaised))
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("終了位置")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                            Slider(value: $viewModel.endRatio, in: min(viewModel.startRatio + 0.02, 0.99) ... 1)
                                .tint(AppColors.accent)

                            HStack {
                                Button("-0.1s") {
                                    viewModel.nudgeEnd(by: -0.1)
                                }
                                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceRaised))

                                Button("+0.1s") {
                                    viewModel.nudgeEnd(by: 0.1)
                                }
                                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceRaised))
                            }
                        }
                    }
                }

                StudioCard {
                    VStack(alignment: .leading, spacing: 14) {
                        textField(title: "フレーズ名", text: $viewModel.name)
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

                Button("Phrase を保存") {
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
        .navigationTitle("Phrase Editor")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "保存エラー",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.errorMessage = nil
                    }
                }
            )
        ) {
            Button("閉じる", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "不明なエラー")
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
                        .fill(AppColors.backgroundSecondary)
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
                .fill(AppColors.surfaceRaised)
        )
    }
}
