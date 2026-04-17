import SwiftUI
import UniformTypeIdentifiers

private enum SourceSheetRoute: Identifiable, Equatable {
    case methodPicker
    case micRecorder
    case saveConfirm(UUID)

    var id: String {
        switch self {
        case .methodPicker:
            return "methodPicker"
        case .micRecorder:
            return "micRecorder"
        case let .saveConfirm(draftID):
            return "saveConfirm-\(draftID.uuidString)"
        }
    }
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
                StudioSectionHeader("練習音源", subtitle: "Files またはマイク録音から追加できます。")

                if viewModel.songs.isEmpty {
                    emptyCard
                } else {
                    ForEach(viewModel.songs, id: \.id) { song in
                        NavigationLink {
                            SongDetailView(song: song, dependencies: dependencies)
                        } label: {
                            StudioCard(emphasisColor: song.sourceType == .micRecorded ? AppColors.recording : AppColors.accent) {
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

                                        Label(
                                            song.sourceType == .micRecorded ? "mic" : "file",
                                            systemImage: song.sourceType == .micRecorded ? "mic.fill" : "folder"
                                        )
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
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, 120)
        }
        .navigationTitle("Songs")
        .studioScreen()
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
                    onPickMicRecording: {
                        route = .micRecorder
                    }
                )
                .presentationDetents([.medium])

            case .micRecorder:
                MicSourceRecordView(dependencies: dependencies) { draftID in
                    route = .saveConfirm(draftID)
                }

            case let .saveConfirm(draftID):
                SourceSaveConfirmView(draftID: draftID, dependencies: dependencies) { _ in
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
        .alert(
            "読み込みエラー",
            isPresented: Binding(
                get: { importErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        importErrorMessage = nil
                    }
                }
            )
        ) {
            Button("閉じる", role: .cancel) { }
        } message: {
            Text(importErrorMessage ?? "不明なエラーです。")
        }
        .task {
            viewModel.refresh()
        }
        .onAppear {
            viewModel.refresh()
        }
    }

    private var emptyCard: some View {
        StudioCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("まだ練習音源がありません。")
                    .font(AppTypography.cardTitle)
                Text("右上の追加ボタンから、Files または練習音源を録音して始められます。")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
