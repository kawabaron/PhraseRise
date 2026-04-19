import SwiftUI

struct MicSourceRecordView: View {
    let onSavedDraft: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MicSourceRecordViewModel

    init(dependencies: AppDependencies, onSavedDraft: @escaping (UUID) -> Void) {
        self.onSavedDraft = onSavedDraft
        _viewModel = State(
            initialValue: MicSourceRecordViewModel(
                audioSessionCoordinator: dependencies.audioSessionCoordinator,
                sourceCaptureService: dependencies.sourceCaptureService,
                draftRepository: dependencies.sourceCaptureDraftRepository,
                settingsRepository: dependencies.settingsRepository
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                heroSection

                if viewModel.permissionState == .denied {
                    permissionBlock
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                        .padding(.top, AppSpacing.medium)
                } else {
                    statusBlock
                        .padding(.top, AppSpacing.medium)

                    Spacer(minLength: AppSpacing.medium)

                    controlButtons
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                }

                Button("破棄") {
                    viewModel.discardCapture()
                    dismiss()
                }
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.top, AppSpacing.medium)
                .padding(.bottom, AppSpacing.medium)
            }
            .frame(maxHeight: .infinity)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .studioScreen()
            .interactiveDismissDisabled(viewModel.isRecording || viewModel.isPaused)
            .onDisappear {
                if viewModel.isRecording || viewModel.isPaused {
                    viewModel.discardCapture()
                }
            }
            .alert(
                "録音エラー",
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
            Text("RECORD SOURCE")
                .font(AppTypography.eyebrow)
                .tracking(2)
                .foregroundStyle(AppColors.recording)

            Text("練習音源を録音")
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

    private var statusBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("STATUS")
                        .font(AppTypography.eyebrow)
                        .tracking(2)
                        .foregroundStyle(AppColors.textMuted)
                    HStack(spacing: 8) {
                        Image(systemName: statusSymbol)
                            .foregroundStyle(statusTint)
                        Text(statusLabel)
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundStyle(statusTint)
                    }
                }

                Spacer()

                Text(Formatting.duration(viewModel.elapsedSec))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .monospacedDigit()
            }

            InputLevelMeterView(level: viewModel.inputLevel, isActive: viewModel.isRecording)
                .frame(height: 48)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }

    private var permissionBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "mic.slash.fill")
                    .foregroundStyle(AppColors.recording)
                Text("マイク権限が未許可です")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }
            Button {
                viewModel.openSettings()
            } label: {
                Text("設定を開く")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppColors.accent)
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, AppSpacing.small)
        }
    }

    private var controlButtons: some View {
        VStack(spacing: AppSpacing.small) {
            if !viewModel.isRecording && !viewModel.isPaused {
                primaryButton(
                    title: "録音開始",
                    icon: "record.circle",
                    background: AppColors.recording,
                    foreground: Color.white
                ) {
                    Task { await viewModel.startCapture() }
                }
            }

            if viewModel.isRecording {
                HStack(spacing: AppSpacing.small) {
                    secondaryButton(title: "一時停止", icon: "pause.fill") {
                        viewModel.pauseCapture()
                    }
                    primaryButton(
                        title: "停止して保存",
                        icon: "stop.circle",
                        background: AppColors.accent,
                        foreground: Color.black
                    ) {
                        if let draftID = viewModel.stopCapture() {
                            onSavedDraft(draftID)
                        }
                    }
                }
            }

            if viewModel.isPaused {
                HStack(spacing: AppSpacing.small) {
                    secondaryButton(title: "再開", icon: "record.circle") {
                        viewModel.resumeCapture()
                    }
                    primaryButton(
                        title: "停止して保存",
                        icon: "stop.circle",
                        background: AppColors.accent,
                        foreground: Color.black
                    ) {
                        if let draftID = viewModel.stopCapture() {
                            onSavedDraft(draftID)
                        }
                    }
                }
            }
        }
    }

    private func primaryButton(
        title: String,
        icon: String,
        background: Color,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(background)
            )
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(
        title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
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
    }

    private var statusLabel: String {
        if viewModel.isRecording { return "録音中" }
        if viewModel.isPaused { return "一時停止中" }
        return "準備中"
    }

    private var statusSymbol: String {
        if viewModel.isRecording { return "record.circle.fill" }
        if viewModel.isPaused { return "pause.circle.fill" }
        return "mic.circle"
    }

    private var statusTint: Color {
        if viewModel.isRecording { return AppColors.recording }
        if viewModel.isPaused { return AppColors.warning }
        return AppColors.textSecondary
    }
}
