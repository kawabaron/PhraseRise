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
            VStack(spacing: 0) {
                heroSection

                waveformBlock
                    .padding(.top, AppSpacing.medium)

                Spacer(minLength: AppSpacing.medium)

                detailsBlock

                Spacer(minLength: AppSpacing.medium)

                actionRow
                    .padding(.horizontal, AppSpacing.screenHorizontal)

                Button("破棄") {
                    viewModel.discardDraftIfNeeded()
                    dismiss()
                }
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.top, AppSpacing.small)
                .padding(.bottom, AppSpacing.medium)
            }
            .frame(maxHeight: .infinity)
            .navigationTitle("")
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

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SAVE SOURCE")
                .font(AppTypography.eyebrow)
                .tracking(2)
                .foregroundStyle(AppColors.recording)

            Text("練習音源を保存")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.small)
        .padding(.bottom, AppSpacing.medium)
        .background(
            RadialGradient(
                colors: [
                    AppColors.recording.opacity(0.20),
                    Color.clear
                ],
                center: UnitPoint(x: 0.1, y: 0.0),
                startRadius: 10,
                endRadius: 320
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    private var waveformBlock: some View {
        WaveformPlaceholderView(
            values: viewModel.waveformValues,
            headPosition: viewModel.isPreviewPlaying ? viewModel.previewRatio : nil,
            showHead: viewModel.isPreviewPlaying
        )
        .frame(height: 110)
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }

    private var detailsBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(spacing: 10) {
                detailPill(label: "録音時間", value: Formatting.duration(viewModel.draft?.durationSec ?? 0))
                Spacer(minLength: 0)
            }

            TextField("練習音源名", text: $viewModel.title)
                .textFieldStyle(.plain)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColors.surface.opacity(0.7))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }

    private var actionRow: some View {
        HStack(spacing: AppSpacing.small) {
            Button {
                viewModel.togglePreview()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isPreviewPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(viewModel.isPreviewPlaying ? "停止" : "プレビュー")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                }
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button {
                if let song = viewModel.saveSong() {
                    onSave(song)
                    dismiss()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("保存")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                }
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppColors.accent)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func detailPill(label: String, value: String) -> some View {
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
}
