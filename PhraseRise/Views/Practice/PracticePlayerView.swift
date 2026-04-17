import SwiftUI

struct PracticePlayerView: View {
    let phrase: Phrase
    let song: Song
    let dependencies: AppDependencies

    @State private var isPlaying = false
    @State private var isLoopEnabled = true
    @State private var isRecording = false
    @State private var bpm: Int
    @State private var isPresentingRecordSheet = false

    init(phrase: Phrase, song: Song, dependencies: AppDependencies) {
        self.phrase = phrase
        self.song = song
        self.dependencies = dependencies
        _bpm = State(initialValue: phrase.recommendedStartBpm ?? phrase.lastStableBpm ?? phrase.targetBpm ?? 88)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                StudioCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(song.title)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        Text(phrase.name)
                            .font(AppTypography.screenTitle)
                        HStack {
                            labelValue("目標 BPM", phrase.targetBpm.map { "\($0)" } ?? "--")
                            Spacer()
                            labelValue("前回 stable", phrase.lastStableBpm.map { "\($0)" } ?? "--")
                            Spacer()
                            labelValue("今日の開始", "\(bpm)")
                        }
                    }
                }

                WaveformPlaceholderView(
                    values: song.waveformOverview.isEmpty ? Array(repeating: 0.42, count: 52) : song.waveformOverview,
                    selection: 0.18 ... 0.46
                )
                .frame(height: 260)

                StudioCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("\(bpm) BPM")
                            .font(AppTypography.bpmHero)
                        Stepper("テンポを調整", value: $bpm, in: 40 ... 240, step: 1)
                            .tint(AppColors.accent)
                        HStack {
                            Label("A: \(Formatting.duration(phrase.startTimeSec))", systemImage: "arrow.left.to.line")
                            Spacer()
                            Label("B: \(Formatting.duration(phrase.endTimeSec))", systemImage: "arrow.right.to.line")
                        }
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    }
                }

                HStack(spacing: AppSpacing.medium) {
                    Button {
                        isPlaying.toggle()
                    } label: {
                        Label(isPlaying ? "一時停止" : "再生", systemImage: isPlaying ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))

                    Button {
                        isLoopEnabled.toggle()
                    } label: {
                        Label(isLoopEnabled ? "ループ中" : "ループ", systemImage: "repeat")
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: isLoopEnabled ? AppColors.accentMuted : AppColors.surfaceRaised))
                }

                HStack(spacing: AppSpacing.medium) {
                    Button { } label: {
                        Label("5秒戻る", systemImage: "gobackward.5")
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceRaised))

                    Button { } label: {
                        Label("5秒進む", systemImage: "goforward.5")
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceRaised))
                }

                HStack(spacing: AppSpacing.large) {
                    Button {
                        isRecording.toggle()
                    } label: {
                        VStack(spacing: 10) {
                            CircularRecordButton(isRecording: isRecording)
                            Text(isRecording ? "演奏録音を停止" : "演奏を録音")
                                .font(AppTypography.caption)
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        isPresentingRecordSheet = true
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("記録", systemImage: "square.and.pencil")
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                            Text("達成 BPM、結果、メモを1画面で保存")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                        .padding(AppSpacing.medium)
                        .background(
                            RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                                .fill(AppColors.accent)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, 120)
        }
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingRecordSheet) {
            PracticeRecordSheet()
        }
    }

    private func labelValue(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.semibold))
        }
    }
}
