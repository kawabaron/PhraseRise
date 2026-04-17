import SwiftUI
import UniformTypeIdentifiers

private enum SourceSheetRoute: String, Identifiable {
    case methodPicker
    case micRecorder
    case saveConfirm

    var id: String { rawValue }
}

struct SongsView: View {
    let dependencies: AppDependencies
    @State private var viewModel: SongsViewModel
    @State private var route: SourceSheetRoute?
    @State private var showingFileImporter = false
    @State private var importErrorMessage: String?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: SongsViewModel(dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                StudioSectionHeader("練習音源", subtitle: "Files またはマイク録音から追加")

                ForEach(viewModel.songs, id: \.id) { song in
                    NavigationLink {
                        SongDetailView(song: song, dependencies: dependencies)
                    } label: {
                        StudioCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(song.title)
                                            .font(AppTypography.cardTitle)
                                        Text(song.artistName ?? song.sourceType.label)
                                            .font(AppTypography.caption)
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                    Spacer()
                                    Label(song.sourceType == .micRecorded ? "mic" : "file", systemImage: song.sourceType == .micRecorded ? "mic.fill" : "folder")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(song.sourceType == .micRecorded ? AppColors.recording : AppColors.accent)
                                }

                                HStack {
                                    Label(Formatting.duration(song.durationSec), systemImage: "clock")
                                    Spacer()
                                    Label(Formatting.date(song.updatedAt), systemImage: "calendar")
                                }
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, 120)
        }
        .navigationTitle("Songs")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    route = .methodPicker
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AppColors.accent)
                }
            }
        }
        .sheet(item: $route) { currentRoute in
            switch currentRoute {
            case .methodPicker:
                SourceAddMethodSheet(
                    onPickFiles: {
                        route = nil
                        DispatchQueue.main.async {
                            showingFileImporter = true
                        }
                    },
                    onPickMicRecording: { route = .micRecorder }
                )
                .presentationDetents([.medium])
            case .micRecorder:
                MicSourceRecordView {
                    route = .saveConfirm
                }
            case .saveConfirm:
                SourceSaveConfirmView {
                    route = nil
                    viewModel.refresh()
                }
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            do {
                let urls = try result.get()
                guard let url = urls.first else { return }
                _ = try dependencies.fileImportService.importSong(from: url)
                viewModel.refresh()
            } catch {
                importErrorMessage = error.localizedDescription
            }
        }
        .alert("読み込みエラー", isPresented: Binding(
            get: { importErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    importErrorMessage = nil
                }
            }
        )) {
            Button("閉じる", role: .cancel) { }
        } message: {
            Text(importErrorMessage ?? "不明なエラー")
        }
        .task {
            viewModel.refresh()
        }
    }
}
