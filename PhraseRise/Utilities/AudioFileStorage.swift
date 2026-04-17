import Foundation

enum AudioFileStorage {
    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    static func songsDirectory(fileManager: FileManager = .default) throws -> URL {
        try ensureDirectory(named: "PhraseRise/Songs", fileManager: fileManager)
    }

    static func draftsDirectory(fileManager: FileManager = .default) throws -> URL {
        try ensureDirectory(named: "PhraseRise/SourceDrafts", fileManager: fileManager)
    }

    static func uniqueAudioFileURL(in directory: URL, fileExtension: String) -> URL {
        directory.appendingPathComponent("\(UUID().uuidString).\(fileExtension)")
    }

    private static func ensureDirectory(named path: String, fileManager: FileManager) throws -> URL {
        let root = try applicationSupportDirectory(fileManager: fileManager)
        let directory = root.appendingPathComponent(path, isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }
}
