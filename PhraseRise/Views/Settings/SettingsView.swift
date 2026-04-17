import SwiftUI

struct SettingsView: View {
    let dependencies: AppDependencies
    @State private var viewModel: SettingsViewModel
    @State private var showingPaywall = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: SettingsViewModel(dependencies: dependencies))
    }

    var body: some View {
        List {
            Section("マイク権限") {
                HStack {
                    Label("録音権限", systemImage: "mic.circle")
                    Spacer()
                    Text(viewModel.microphonePermissionLabel)
                        .foregroundStyle(permissionTint)
                }

                switch viewModel.microphonePermission {
                case .undetermined:
                    Button("マイクを許可する") {
                        Task {
                            await viewModel.requestMicrophonePermission()
                        }
                    }
                case .denied:
                    Button("設定アプリを開く") {
                        viewModel.openSystemSettings()
                    }
                    Text("練習音源録音と演奏録音にはマイク権限が必要です。")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                case .granted:
                    Text("練習音源録音と演奏録音を利用できます。")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Section("練習設定") {
                Toggle("デフォルトでループを有効", isOn: Binding(
                    get: { viewModel.settings.defaultLoopEnabled },
                    set: { viewModel.updateLoopDefault($0) }
                ))
                Toggle("リマインダー", isOn: Binding(
                    get: { viewModel.settings.reminderEnabled },
                    set: { viewModel.updateReminder($0) }
                ))
                Toggle("イヤホン推奨ヒントを表示", isOn: Binding(
                    get: { viewModel.settings.showHeadphoneHint },
                    set: { viewModel.updateHeadphoneHint($0) }
                ))
                Stepper(value: Binding(
                    get: { viewModel.settings.defaultTempoStep },
                    set: { viewModel.updateTempoStep($0) }
                ), in: 1 ... 10) {
                    Text("テンポ刻み: \(viewModel.settings.defaultTempoStep)")
                }
            }

            Section("録音品質") {
                Picker("録音品質", selection: Binding(
                    get: { viewModel.settings.recordingQualityPreset },
                    set: { viewModel.updateRecordingQuality($0) }
                )) {
                    Text("standard").tag("standard")
                    Text("high").tag("high")
                    Text("lossless").tag("lossless")
                }
                Text("練習音源録音と演奏録音の保存品質に使われます。")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Section("Premium") {
                HStack {
                    Text("現在の状態")
                    Spacer()
                    Text(viewModel.premiumStatusLabel)
                        .foregroundStyle(viewModel.subscription.isPremium ? AppColors.success : AppColors.textSecondary)
                }

                if viewModel.subscription.isPremium {
                    Button("無料版に戻す") {
                        viewModel.restoreFree()
                    }
                } else {
                    Button("Premium の内容を見る") {
                        showingPaywall = true
                    }
                    Button("Premium を有効化") {
                        viewModel.enablePremium()
                    }
                }
            }

            Section("情報") {
                Text("利用規約")
                Text("プライバシー")
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.screenGradient)
        .navigationTitle("Settings")
        .sheet(isPresented: $showingPaywall) {
            PaywallView(dependencies: dependencies)
        }
        .onAppear {
            viewModel.refreshPermissionState()
        }
    }

    private var permissionTint: Color {
        switch viewModel.microphonePermission {
        case .undetermined:
            return AppColors.warning
        case .denied:
            return AppColors.recording
        case .granted:
            return AppColors.success
        }
    }
}
