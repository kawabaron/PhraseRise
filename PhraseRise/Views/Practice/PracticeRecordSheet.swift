import SwiftUI

struct PracticeRecordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PracticeRecordSheetViewModel

    init(phrase: Phrase, initialBpm: Int, dependencies: AppDependencies) {
        _viewModel = State(initialValue: PracticeRecordSheetViewModel(phrase: phrase, initialBpm: initialBpm, dependencies: dependencies))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection

                    bpmField
                        .padding(.top, AppSpacing.large)

                    resultField
                        .padding(.top, AppSpacing.xLarge)

                    durationField
                        .padding(.top, AppSpacing.xLarge)

                    recordingLinkField
                        .padding(.top, AppSpacing.xLarge)

                    memoField
                        .padding(.top, AppSpacing.xLarge)
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                }
                .padding(.bottom, 60)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .studioScreen()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(AppColors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        if viewModel.saveRecord() != nil {
                            dismiss()
                        }
                    }
                    .foregroundStyle(AppColors.accent)
                    .fontWeight(.semibold)
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
                Text(viewModel.errorMessage ?? "不明なエラーです。")
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PRACTICE RECORD")
                .font(AppTypography.eyebrow)
                .tracking(2)
                .foregroundStyle(AppColors.textMuted)

            Text("練習を記録する")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.medium)
        .padding(.bottom, AppSpacing.large)
        .background(
            RadialGradient(
                colors: [
                    AppColors.accent.opacity(0.20),
                    Color.clear
                ],
                center: UnitPoint(x: 0.1, y: 0.0),
                startRadius: 10,
                endRadius: 320
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    private var bpmField: some View {
        fieldGroup(eyebrow: "達成 BPM") {
            HStack {
                Text("\(viewModel.bpm) BPM")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Stepper("", value: $viewModel.bpm, in: 40 ... 240)
                    .labelsHidden()
                    .tint(AppColors.accent)
            }
            .padding(.vertical, 4)
        }
    }

    private var resultField: some View {
        fieldGroup(eyebrow: "結果") {
            Picker("結果", selection: $viewModel.resultType) {
                ForEach(PracticeResultType.allCases) { result in
                    Text(result.label).tag(result)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var durationField: some View {
        fieldGroup(eyebrow: "練習時間") {
            HStack {
                Text("\(viewModel.durationMinutes)分")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Stepper("", value: $viewModel.durationMinutes, in: 1 ... 120)
                    .labelsHidden()
                    .tint(AppColors.accent)
            }
            .padding(.vertical, 4)
        }
    }

    private var recordingLinkField: some View {
        fieldGroup(eyebrow: "演奏録音") {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("最新の演奏録音を紐付ける", isOn: $viewModel.linkLatestRecording)
                    .tint(AppColors.accent)
                    .foregroundStyle(AppColors.textPrimary)
                Text(viewModel.latestRecordingSummary)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
        }
    }

    private var memoField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MEMO")
                .font(AppTypography.eyebrow)
                .tracking(2)
                .foregroundStyle(AppColors.textMuted)
            TextField("メモ", text: $viewModel.memo, axis: .vertical)
                .textFieldStyle(.plain)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(3 ... 8)
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
    }

    private func fieldGroup<Content: View>(
        eyebrow: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow.uppercased())
                .font(AppTypography.eyebrow)
                .tracking(2)
                .foregroundStyle(AppColors.textMuted)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }
}
