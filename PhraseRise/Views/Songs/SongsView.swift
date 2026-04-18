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
            VStack(spacing: 0) {
                heroSection

                if viewModel.songs.isEmpty {
                    emptyState
                } else {
                    songList
                }
            }
            .padding(.bottom, 120)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PRACTICE SOURCES")
                .font(AppTypography.eyebrow)
                .tracking(2)
                .foregroundStyle(AppColors.textMuted)

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text("\(viewModel.songs.count)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                Text("件")
                    .font(.system(.title3, design: .rounded).weight(.regular))
                    .foregroundStyle(AppColors.textMuted)
            }

            if !viewModel.songs.isEmpty {
                Text("合計 \(totalDurationLabel)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
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
                endRadius: 360
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    private var songList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(viewModel.songs.enumerated()), id: \.element.id) { index, song in
                NavigationLink {
                    SongDetailView(song: song, dependencies: dependencies)
                } label: {
                    songRow(song)
                }
                .buttonStyle(.plain)

                if index < viewModel.songs.count - 1 {
                    Rectangle()
                        .fill(AppColors.border)
                        .frame(height: 0.5)
                        .padding(.leading, AppSpacing.screenHorizontal + 22)
                }
            }
        }
        .padding(.top, AppSpacing.small)
    }

    private func songRow(_ song: Song) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(song.sourceType == .micRecorded ? AppColors.recording : AppColors.accent)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(song.title)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                Text(subtitleLine(for: song))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private func subtitleLine(for song: Song) -> String {
        var parts: [String] = []
        if let artist = song.artistName, !artist.isEmpty {
            parts.append(artist)
        } else {
            parts.append(song.sourceType.label)
        }
        parts.append(Formatting.duration(song.durationSec))
        parts.append(Formatting.relativeDate(song.updatedAt))
        return parts.joined(separator: " · ")
    }

    private var totalDurationLabel: String {
        let total = Int(viewModel.songs.reduce(0.0) { $0 + $1.durationSec }.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("まだ練習音源がありません。")
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
            Text("右上の + から Files またはマイク録音で追加できます。")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.large)
    }
}
