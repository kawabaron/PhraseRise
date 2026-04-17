import SwiftUI

struct PhraseEditorView: View {
    let song: Song
    let phrase: Phrase?
    @State private var name: String
    @State private var memo: String
    @State private var targetBpm: Int
    @State private var startRatio: Double
    @State private var endRatio: Double

    init(song: Song, phrase: Phrase? = nil) {
        self.song = song
        self.phrase = phrase
        _name = State(initialValue: phrase?.name ?? "新しい Phrase")
        _memo = State(initialValue: phrase?.memo ?? "")
        _targetBpm = State(initialValue: phrase?.targetBpm ?? 96)
        _startRatio = State(initialValue: 0.18)
        _endRatio = State(initialValue: 0.42)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                StudioSectionHeader("Phrase を切り出し", subtitle: "A/B ハンドルは Task 07 で詳細実装")

                WaveformPlaceholderView(
                    values: song.waveformOverview.isEmpty ? Array(repeating: 0.4, count: 46) : song.waveformOverview,
                    selection: startRatio ... endRatio
                )
                .frame(height: 220)

                StudioCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("開始位置")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        Slider(value: $startRatio, in: 0 ... 0.8)
                            .tint(AppColors.accent)

                        Text("終了位置")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        Slider(value: $endRatio, in: max(startRatio + 0.05, 0.1) ... 1)
                            .tint(AppColors.accent)
                    }
                }

                StudioCard {
                    VStack(alignment: .leading, spacing: 14) {
                        textField(title: "フレーズ名", text: $name)
                        textField(title: "メモ", text: $memo)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("目標 BPM")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                            Stepper(value: $targetBpm, in: 40 ... 240, step: 1) {
                                Text("\(targetBpm) BPM")
                            }
                        }
                    }
                }

                Button("Phrase を保存") { }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, 120)
        }
        .navigationTitle("Phrase Editor")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func textField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            TextField(title, text: text)
                .textFieldStyle(.plain)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppColors.backgroundSecondary)
                )
        }
    }
}
