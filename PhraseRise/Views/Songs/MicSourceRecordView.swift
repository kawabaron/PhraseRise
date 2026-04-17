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
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                StudioSectionHeader(
                    "練習音源を録音",
                    subtitle: "ここでは Song 作成用の練習音源だけを録音します。"
                )

                if viewModel.permissionState == .denied {
                    permissionCard
                } else {
                    statusCard
                    controlButtons
                }

                Button("破棄") {
                    viewModel.discardCapture()
                    dismiss()
                }
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)

                Spacer()
            }
            .padding(AppSpacing.large)
            .navigationTitle("練習音源を録音")
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

    private var permissionCard: some View {
        StudioCard(emphasisColor: AppColors.recording) {
            VStack(alignment: .leading, spacing: 14) {
                Label("マイク権限が未許可です", systemImage: "mic.slash.fill")
                    .foregroundStyle(AppColors.recording)
                Text("練習音源を録音するには、設定アプリから PhraseRise のマイク利用を有効にしてください。")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                Button("設定を開く") {
                    viewModel.openSettings()
                }
                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))
            }
        }
    }

    private var statusCard: some View {
        StudioCard(emphasisColor: statusTint) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Label(statusLabel, systemImage: statusSymbol)
                        .foregroundStyle(statusTint)
                    Spacer()
                    Text(Formatting.duration(viewModel.elapsedSec))
                        .font(AppTypography.metric)
                }

                ProgressView(value: viewModel.inputLevel)
                    .tint(AppColors.recording)

                Text("録音中は入力レベルを見ながら、Song 作成用の練習音源として聞きやすい位置で録ってください。")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private var controlButtons: some View {
        VStack(spacing: AppSpacing.medium) {
            if !viewModel.isRecording && !viewModel.isPaused {
                Button {
                    Task {
                        await viewModel.startCapture()
                    }
                } label: {
                    Label("録音開始", systemImage: "record.circle")
                }
                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.recording))
            }

            if viewModel.isRecording {
                HStack(spacing: AppSpacing.medium) {
                    Button {
                        viewModel.pauseCapture()
                    } label: {
                        Label("一時停止", systemImage: "pause.fill")
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceGlass))

                    Button {
                        if let draftID = viewModel.stopCapture() {
                            onSavedDraft(draftID)
                        }
                    } label: {
                        Label("停止して保存へ", systemImage: "stop.circle")
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))
                }
            }

            if viewModel.isPaused {
                HStack(spacing: AppSpacing.medium) {
                    Button {
                        viewModel.resumeCapture()
                    } label: {
                        Label("再開", systemImage: "record.circle")
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.recording))

                    Button {
                        if let draftID = viewModel.stopCapture() {
                            onSavedDraft(draftID)
                        }
                    } label: {
                        Label("停止して保存へ", systemImage: "stop.circle")
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))
                }
            }
        }
    }

    private var statusLabel: String {
        if viewModel.isRecording {
            return "録音中"
        }
        if viewModel.isPaused {
            return "一時停止中"
        }
        return "準備中"
    }

    private var statusSymbol: String {
        if viewModel.isRecording {
            return "record.circle.fill"
        }
        if viewModel.isPaused {
            return "pause.circle.fill"
        }
        return "mic.circle"
    }

    private var statusTint: Color {
        if viewModel.isRecording {
            return AppColors.recording
        }
        if viewModel.isPaused {
            return AppColors.warning
        }
        return AppColors.textSecondary
    }
}
