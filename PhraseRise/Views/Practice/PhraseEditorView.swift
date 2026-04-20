import SwiftUI

struct PhraseEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let dependencies: AppDependencies
    private let song: Song
    @State private var viewModel: PhraseEditorViewModel

    init(song: Song, phrase: Phrase? = nil, dependencies: AppDependencies) {
        self.dependencies = dependencies
        self.song = song
        _viewModel = State(initialValue: PhraseEditorViewModel(song: song, phrase: phrase, dependencies: dependencies))
    }

    var body: some View {
        VStack(spacing: 0) {
            heroSection

            waveformBlock
                .padding(.top, AppSpacing.medium)

            Spacer(minLength: AppSpacing.medium)

            detailsBlock

            Spacer(minLength: AppSpacing.medium)

            saveButton
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, AppSpacing.medium)
        }
        .frame(maxHeight: .infinity)
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
        .onDisappear {
            viewModel.stopPlayback()
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PHRASE EDITOR")
                .font(AppTypography.eyebrow)
                .tracking(2)
                .foregroundStyle(AppColors.textMuted)

            Text("練習区間を作成")
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
                    AppColors.accent.opacity(0.22),
                    Color.clear
                ],
                center: UnitPoint(x: 0.1, y: 0.0),
                startRadius: 10,
                endRadius: 320
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - Sections

    private var waveformBlock: some View {
        VStack(spacing: AppSpacing.small) {
            if let videoURL = song.videoFileURL {
                VideoPlaybackDisplayView(
                    videoURL: videoURL,
                    durationSec: song.durationSec,
                    headPosition: viewModel.isPlaying ? viewModel.playheadRatio : nil
                )
                .frame(height: 140)
            }

            WaveformPlaceholderView(
                values: viewModel.waveformValues,
                selection: viewModel.startRatio ... viewModel.endRatio,
                headPosition: viewModel.isPlaying ? viewModel.playheadRatio : nil,
                onSelectionChange: { range in
                    let lower = min(max(range.lowerBound, 0), 0.98)
                    let upper = max(min(range.upperBound, 1), lower + 0.02)
                    viewModel.startRatio = lower
                    viewModel.endRatio = upper
                }
            )
            .frame(height: song.videoFileURL != nil ? 76 : 120)

            HStack {
                ProgressPlayButton(
                    isPlaying: viewModel.isPlaying,
                    progress: selectionProgress,
                    size: 40,
                    activeFill: AppColors.accent
                ) {
                    viewModel.togglePlayback()
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.isPlaying ? "A/B 区間を再生中" : "A/B 区間を再生")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("A \(Formatting.duration(viewModel.startTimeSec))  B \(Formatting.duration(viewModel.endTimeSec))")
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .monospacedDigit()
                }

                Spacer()
            }
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }

    private var selectionProgress: Double {
        guard viewModel.isPlaying else { return 0 }
        let span = max(viewModel.endRatio - viewModel.startRatio, 0.0001)
        return min(max((viewModel.playheadRatio - viewModel.startRatio) / span, 0), 1)
    }

    private var detailsBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            TextField("練習区間名", text: $viewModel.name)
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

            TextField("メモ", text: $viewModel.memo)
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

}
