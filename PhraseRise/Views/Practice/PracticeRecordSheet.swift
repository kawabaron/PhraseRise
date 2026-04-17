import SwiftUI

struct PracticeRecordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PracticeRecordSheetViewModel

    init(phrase: Phrase, initialBpm: Int, dependencies: AppDependencies) {
        _viewModel = State(initialValue: PracticeRecordSheetViewModel(phrase: phrase, initialBpm: initialBpm, dependencies: dependencies))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("達成 BPM") {
                    Stepper(value: $viewModel.bpm, in: 40 ... 240) {
                        Text("\(viewModel.bpm) BPM")
                    }
                }

                Section("結果") {
                    Picker("結果", selection: $viewModel.resultType) {
                        ForEach(PracticeResultType.allCases) { result in
                            Text(result.label).tag(result)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("練習時間") {
                    Stepper(value: $viewModel.durationMinutes, in: 1 ... 120) {
                        Text("\(viewModel.durationMinutes) 分")
                    }
                }

                Section("演奏録音") {
                    Toggle("最新録音を紐付ける", isOn: $viewModel.linkLatestRecording)
                    Text(viewModel.latestRecordingSummary)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Section("メモ") {
                    TextField("メモ", text: $viewModel.memo, axis: .vertical)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.screenGradient)
            .navigationTitle("練習記録")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        if viewModel.saveRecord() != nil {
                            dismiss()
                        }
                    }
                }
            }
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
    }
}
