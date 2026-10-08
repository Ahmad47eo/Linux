import Foundation

enum FileImportError: LocalizedError {
    case copyFailed(String)

    var errorDescription: String? {
        switch self {
        case .copyFailed(let message):
            return "Import failed: \(message)"
        }
    }
}

final class FileImporterService {
    static let shared = FileImporterService()

    private let fileManager = FileManager.default

    private lazy var importsDirectory: URL = {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = base.appendingPathComponent("RuntimeApp/Imports", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }()

    func importFile(from sourceURL: URL) throws -> URL {
        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let destination = uniqueDestination(for: sourceURL.lastPathComponent)
        do {
            try fileManager.copyItem(at: sourceURL, to: destination)
            return destination
        } catch {
            throw FileImportError.copyFailed(error.localizedDescription)
        }
    }

    private func uniqueDestination(for fileName: String) -> URL {
        let original = importsDirectory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: original.path) else { return original }

        let ext = original.pathExtension
        let stem = original.deletingPathExtension().lastPathComponent
        var index = 2

        while true {
            let candidateName = ext.isEmpty ? "(stem) (index)" : "(stem) (index).(ext)"
            let candidate = importsDirectory.appendingPathComponent(candidateName)
            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
            index += 1
        }
    }
}
