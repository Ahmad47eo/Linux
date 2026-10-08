import Foundation

final class JavaRuntimeManager {
    static let shared = JavaRuntimeManager()
    private let fileManager = FileManager.default

    private lazy var runtimesDirectory: URL = {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = base.appendingPathComponent("RuntimeApp/JavaRuntimes", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }()

    func runtimeDirectory(for kind: RuntimeKind) -> URL? {
        guard let folder = folderName(for: kind) else { return nil }
        let url = runtimesDirectory.appendingPathComponent(folder, isDirectory: true)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func isInstalled(_ kind: RuntimeKind) -> Bool {
        guard let directory = runtimeDirectory(for: kind) else { return false }
        return fileManager.fileExists(atPath: directory.appendingPathComponent("bin/java").path)
    }

    func installImportedRuntime(from sourceURL: URL, kind: RuntimeKind) throws {
        guard kind != .windows, let folder = folderName(for: kind) else { return }
        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessed { sourceURL.stopAccessingSecurityScopedResource() } }
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw RuntimeLaunchError.unavailable("The selected runtime folder could not be accessed.")
        }
        let destination = runtimesDirectory.appendingPathComponent(folder)
        if fileManager.fileExists(atPath: destination.path) { try fileManager.removeItem(at: destination) }
        try fileManager.copyItem(at: sourceURL, to: destination)
        guard fileManager.fileExists(atPath: destination.appendingPathComponent("bin/java").path) else {
            try? fileManager.removeItem(at: destination)
            throw RuntimeLaunchError.unavailable("The selected folder does not contain bin/java.")
        }
    }

    private func folderName(for kind: RuntimeKind) -> String? {
        switch kind {
        case .java8: return "java8"
        case .java17: return "java17"
        case .java21: return "java21"
        case .windows: return nil
        }
    }
}
