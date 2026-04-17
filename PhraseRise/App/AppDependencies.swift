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
    let fileImportService: FileImportService
    let suggestionEngine: PracticeSuggestionEngine
    let subscriptionService: SubscriptionService
    let sampleDataSeeder: SampleDataSeeder

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
        audioPreviewService = AudioPreviewService(audioSessionCoordinator: audioSessionCoordinator)
        fileImportService = FileImportService(
            songRepository: songRepository,
            waveformAnalysisService: waveformAnalysisService
        )
        suggestionEngine = PracticeSuggestionEngine()
        subscriptionService = SubscriptionService(subscriptionRepository: subscriptionRepository)
        sampleDataSeeder = SampleDataSeeder(
            songRepository: songRepository,
            phraseRepository: phraseRepository,
            practiceRecordRepository: practiceRecordRepository,
            performanceRecordingRepository: performanceRecordingRepository,
            settingsRepository: settingsRepository,
            subscriptionRepository: subscriptionRepository,
            suggestionEngine: suggestionEngine
        )
    }

    func bootstrap() {
        sampleDataSeeder.seedIfNeeded()
    }
}
