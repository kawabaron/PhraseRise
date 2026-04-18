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
        ScrollView {
            VStack(spacing: 0) {
                heroSection

                micPermissionSection
                    .padding(.top, AppSpacing.xLarge)

                practiceSettingsSection
                    .padding(.top, AppSpacing.xLarge)

                recordingQualitySection
                    .padding(.top, AppSpacing.xLarge)

                premiumSection
                    .padding(.top, AppSpacing.xLarge)

                infoSection
                    .padding(.top, AppSpacing.xLarge)
            }
            .padding(.bottom, 120)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .studioScreen()
        .tint(AppColors.accent)
        .sheet(isPresented: $showingPaywall) {
            PaywallView(dependencies: dependencies)
        }
        .onAppear {
            viewModel.refreshPermissionState()
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SUBSCRIPTION")
                .font(AppTypography.eyebrow)
                .tracking(2)
                .foregroundStyle(AppColors.textMuted)

            Text(viewModel.subscription.isPremium ? "Premium" : "Free")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            Text(viewModel.subscription.isPremium
                 ? "全期間グラフと詳細な比較再生が利用できます。"
                 : "練習の保存と直近の変化確認は無料版でも利用できます。")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.medium)
        .padding(.bottom, AppSpacing.xLarge)
        .background(
            RadialGradient(
                colors: [
                    AppColors.accent.opacity(0.22),
                    Color.clear
                ],
                center: UnitPoint(x: 0.1, y: 0.0),
                startRadius: 10,
                endRadius: 380
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - Sections

    private var micPermissionSection: some View {
        section("マイク権限") {
            row {
                rowLabel("録音権限", icon: "mic")
                Spacer()
                Text(viewModel.microphonePermissionLabel)
                    .font(AppTypography.body)
                    .foregroundStyle(permissionTint)
            }

            switch viewModel.microphonePermission {
            case .undetermined:
                hairline
                row {
                    Button("マイクを許可する") {
                        Task { await viewModel.requestMicrophonePermission() }
                    }
                    .foregroundStyle(AppColors.accent)
                    Spacer()
                }
            case .denied:
                hairline
                row {
                    Button("設定アプリを開く") {
                        viewModel.openSystemSettings()
                    }
                    .foregroundStyle(AppColors.accent)
                    Spacer()
                }
                helperText("練習音源録音と演奏録音にはマイク権限が必要です。")
            case .granted:
                helperText("練習音源録音と演奏録音を利用できます。")
            }
        }
    }

    private var practiceSettingsSection: some View {
        section("練習設定") {
            row {
                Toggle("デフォルトでループを有効", isOn: Binding(
                    get: { viewModel.settings.defaultLoopEnabled },
                    set: { viewModel.updateLoopDefault($0) }
                ))
                .tint(AppColors.accent)
            }
            hairline
            row {
                Toggle("リマインダー", isOn: Binding(
                    get: { viewModel.settings.reminderEnabled },
                    set: { viewModel.updateReminder($0) }
                ))
                .tint(AppColors.accent)
            }
            hairline
            row {
                Toggle("イヤホン推奨ヒントを表示", isOn: Binding(
                    get: { viewModel.settings.showHeadphoneHint },
                    set: { viewModel.updateHeadphoneHint($0) }
                ))
                .tint(AppColors.accent)
            }
            hairline
            row {
                Stepper(value: Binding(
                    get: { viewModel.settings.defaultTempoStep },
                    set: { viewModel.updateTempoStep($0) }
                ), in: 1 ... 10) {
                    Text("テンポ刻み: \(viewModel.settings.defaultTempoStep)")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
        }
    }

    private var recordingQualitySection: some View {
        section("録音品質") {
            row {
                Text("品質")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Picker("", selection: Binding(
                    get: { viewModel.settings.recordingQualityPreset },
                    set: { viewModel.updateRecordingQuality($0) }
                )) {
                    Text("標準").tag("standard")
                    Text("高音質").tag("high")
                    Text("ロスレス").tag("lossless")
                }
                .pickerStyle(.menu)
                .tint(AppColors.accent)
            }
            helperText("練習音源録音と演奏録音の保存品質に使われます。")
        }
    }

    private var premiumSection: some View {
        section("Premium") {
            row {
                Text("現在の状態")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text(viewModel.premiumStatusLabel)
                    .font(AppTypography.body)
                    .foregroundStyle(viewModel.subscription.isPremium ? AppColors.success : AppColors.textSecondary)
            }

            if viewModel.subscription.isPremium {
                hairline
                row {
                    Button("無料版に戻す") {
                        viewModel.restoreFree()
                    }
                    .foregroundStyle(AppColors.accent)
                    Spacer()
                }
            } else {
                hairline
                row {
                    Button("Premium の内容を見る") {
                        showingPaywall = true
                    }
                    .foregroundStyle(AppColors.accent)
                    Spacer()
                }
                hairline
                row {
                    Button("Premium を有効化") {
                        viewModel.enablePremium()
                    }
                    .foregroundStyle(AppColors.accent)
                    Spacer()
                }
            }
        }
    }

    private var infoSection: some View {
        section("情報") {
            row {
                Text("利用規約")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textMuted)
            }
            hairline
            row {
                Text("プライバシー")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textMuted)
            }
        }
    }

    // MARK: - Section helpers

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(AppTypography.eyebrow)
                .tracking(2)
                .foregroundStyle(AppColors.textMuted)
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, AppSpacing.small)

            VStack(spacing: 0) {
                content()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: AppSpacing.small) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, 14)
    }

    private func rowLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 18)
            Text(text)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
        }
    }

    private func helperText(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.bottom, AppSpacing.medium)
    }

    private var hairline: some View {
        Rectangle()
            .fill(AppColors.border)
            .frame(height: 0.5)
            .padding(.leading, AppSpacing.screenHorizontal)
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
