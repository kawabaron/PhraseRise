import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @State private var showingPaywall = false

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: SettingsViewModel(dependencies: dependencies))
    }

    var body: some View {
        List {
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

            Section("録音") {
                Picker("録音品質", selection: Binding(
                    get: { viewModel.settings.recordingQualityPreset },
                    set: { viewModel.updateRecordingQuality($0) }
                )) {
                    Text("standard").tag("standard")
                    Text("high").tag("high")
                    Text("lossless").tag("lossless")
                }
                Label("権限復帰導線は Task 16 で設定アプリへ接続", systemImage: "mic.circle")
                    .foregroundStyle(AppColors.textSecondary)
            }

            Section("Premium") {
                HStack {
                    Text("状態")
                    Spacer()
                    Text(viewModel.subscription.isPremium ? "有効" : "無料版")
                        .foregroundStyle(viewModel.subscription.isPremium ? AppColors.success : AppColors.textSecondary)
                }
                Button("Paywall を表示") {
                    showingPaywall = true
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
            PaywallView()
        }
    }
}
