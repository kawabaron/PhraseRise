import SwiftUI

struct SourceSaveConfirmView: View {
    let onSave: (Song) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SourceSaveConfirmViewModel

    init(draftID: UUID, dependencies: AppDependencies, onSave: @escaping (Song) -> Void) {
        self.onSave = onSave
        _viewModel = State(
            initialValue: SourceSaveConfirmViewModel(
                draftID: draftID,
                draftRepository: dependencies.sourceCaptureDraftRepository,
                sourceSongCreationService: dependencies.sourceSongCreationService,
                waveformAnalysisService: dependencies.waveformAnalysisService,
                audioPreviewService: dependencies.audioPreviewService
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                StudioSectionHeader(
                    "練習音源を保存",
                    subtitle: "録音した練習音源を確認して Song として保存します。"
                )

                WaveformPlaceholderView(values: viewModel.waveformValues, showHead: false)
                    .frame(height: 190)

                StudioCard(emphasisColor: AppColors.recording) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            metric("録音時間", value: Formatting.duration(viewModel.draft?.durationSec ?? 0))
                            Spacer()
                            metric("保存形式", value: "micRecorded")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("音源名")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)

                            TextField("練習音源名", text: $viewModel.title)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(AppColors.surfaceGlass.opacity(0.82))
                                )
                        }
                    }
                }

                HStack(spacing: AppSpacing.medium) {
                    Button {
                        viewModel.togglePreview()
                    } label: {
                        Label(
                            viewModel.isPreviewPlaying ? "プレビュー停止" : "プレビュー再生",
                            systemImage: viewModel.isPreviewPlaying ? "stop.fill" : "play.fill"
                        )
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceGlass))

                    Button {
                        if let song = viewModel.saveSong() {
                            onSave(song)
                            dismiss()
                        }
                    } label: {
                        Label("練習音源を保存", systemImage: "square.and.arrow.down.fill")
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))
                }

                Button("破棄") {
                    viewModel.discardDraftIfNeeded()
                    dismiss()
                }
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)

                Spacer()
            }
            .padding(AppSpacing.large)
            .navigationTitle("保存確認")
            .navigationBarTitleDisplayMode(.inline)
            .studioScreen()
            .task {
                viewModel.load()
            }
            .onDisappear {
                viewModel.stopPreview()
                viewModel.discardDraftIfNeeded()
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

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.semibold))
        }
    }
}
