import SwiftData

@MainActor
final class AppDependencies {
    static let shared = AppDependencies(context: AppDatabase.shared.container.mainContext)

    let songRepository: SongRepository
    let phraseRepository: PhraseRepository
    let practiceRecordRepository: PracticeRecordRepository
    let performanceRecordingRepository: PerformanceRecordingRepository
    let settingsRepository: SettingsRepository
    let subscriptionRepository: SubscriptionRepository
    let sourceCaptureDraftRepository: SourceCaptureDraftRepository

    let audioSessionCoordinator: AudioSessionCoordinator
    let waveformAnalysisService: WaveformAnalysisService
    let sourceCaptureService: SourceCaptureService
    let sourceSongCreationService: SourceSongCreationService
    let audioPreviewService: AudioPreviewService
    let audioPlaybackService: AudioPlaybackService
    let performanceRecordingService: PerformanceRecordingService
    let phraseDeletionService: PhraseDeletionService
    let songDeletionService: SongDeletionService
    let phraseLoopService: PhraseLoopService
    let fileImportService: FileImportService
    let subscriptionService: SubscriptionService

    init(context: ModelContext) {
        songRepository = SongRepository(context: context)
        phraseRepository = PhraseRepository(context: context)
        practiceRecordRepository = PracticeRecordRepository(context: context)
        performanceRecordingRepository = PerformanceRecordingRepository(context: context)
        settingsRepository = SettingsRepository(context: context)
        subscriptionRepository = SubscriptionRepository(context: context)
        sourceCaptureDraftRepository = SourceCaptureDraftRepository(context: context)
        audioSessionCoordinator = AudioSessionCoordinator()
        waveformAnalysisService = WaveformAnalysisService()
        sourceCaptureService = SourceCaptureService(audioSessionCoordinator: audioSessionCoordinator)
        sourceSongCreationService = SourceSongCreationService(
            songRepository: songRepository,
            draftRepository: sourceCaptureDraftRepository,
            waveformAnalysisService: waveformAnalysisService
        )
        subscriptionService = SubscriptionService(subscriptionRepository: subscriptionRepository)
        audioPreviewService = AudioPreviewService(audioSessionCoordinator: audioSessionCoordinator)
        audioPlaybackService = AudioPlaybackService(audioSessionCoordinator: audioSessionCoordinator)
        performanceRecordingService = PerformanceRecordingService(
            audioSessionCoordinator: audioSessionCoordinator,
            performanceRecordingRepository: performanceRecordingRepository,
            settingsRepository: settingsRepository,
            subscriptionService: subscriptionService
        )
        phraseDeletionService = PhraseDeletionService(
            phraseRepository: phraseRepository,
            practiceRecordRepository: practiceRecordRepository,
            performanceRecordingRepository: performanceRecordingRepository
        )
        songDeletionService = SongDeletionService(
            songRepository: songRepository,
            phraseRepository: phraseRepository,
            phraseDeletionService: phraseDeletionService
        )
        phraseLoopService = PhraseLoopService()
        fileImportService = FileImportService(
            songRepository: songRepository,
            waveformAnalysisService: waveformAnalysisService
        )
    }

    func bootstrap() {
        _ = settingsRepository.loadOrCreate()
        _ = subscriptionRepository.loadOrCreate()
        removeLegacySampleDataIfNeeded()
    }

    private func removeLegacySampleDataIfNeeded() {
        for song in songRepository.fetchAll() where isLegacySampleData(song) {
            songDeletionService.deleteSong(song)
        }
    }

    private func isLegacySampleData(_ song: Song) -> Bool {
        song.title == "Blue Riff Study" &&
        song.artistName == "PhraseRise Demo" &&
        song.localFileURL.path == "/tmp/blueriff-demo.m4a"
    }
}
