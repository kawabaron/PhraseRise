import SwiftUI

struct RecordingListView: View {
    let phrase: Phrase
    let song: Song
    let dependencies: AppDependencies

    private var recordings: [PerformanceRecording] {
        dependencies.performanceRecordingRepository.fetch(phraseId: phrase.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                StudioSectionHeader("録音一覧", subtitle: "比較再生は Task 14 で接続")

                ForEach(recordings, id: \.id) { recording in
                    StudioCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(recording.takeName)
                                    .font(AppTypography.cardTitle)
                                Spacer()
                                if let result = recording.resultType {
                                    Text(result.label)
                                        .font(AppTypography.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(result.tint.opacity(0.18), in: Capsule())
                                }
                            }

                            Text(song.title)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)

                            HStack {
                                Label(Formatting.date(recording.recordedAt), systemImage: "calendar")
                                Spacer()
                                Label("\(recording.bpmAtRecording ?? 0) BPM", systemImage: "metronome")
                                Spacer()
                                Label(Formatting.duration(recording.durationSec), systemImage: "clock")
                            }
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, 120)
        }
        .navigationTitle("Recordings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
