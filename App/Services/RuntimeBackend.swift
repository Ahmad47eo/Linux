import Foundation

enum RuntimeLaunchError: LocalizedError {
    case unavailable(String)

    var errorDescription: String? {
        switch self {
        case .unavailable(let message): return message
        }
    }
}

protocol RuntimeBackend {
    var kind: RuntimeKind { get }
    func launch(profile: RuntimeProfile) async throws
}

struct JavaBackend: RuntimeBackend {
    let kind: RuntimeKind

    func launch(profile: RuntimeProfile) async throws {
        guard let runtime = JavaRuntimeManager.shared.runtimeDirectory(for: kind) else {
            throw RuntimeLaunchError.unavailable("Install the selected OpenJDK runtime before launching this profile.")
        }

        let imports = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RuntimeApp/Imports", isDirectory: true)
        let jar = imports.appendingPathComponent(profile.fileName)
        guard FileManager.default.fileExists(atPath: jar.path) else {
            throw RuntimeLaunchError.unavailable("The imported JAR could not be found.")
        }

        try JavaVMService.shared.start(runtime: runtime, classPath: jar)
    }
}

struct WindowsBackend: RuntimeBackend {
    let kind: RuntimeKind = .windows

    func launch(profile: RuntimeProfile) async throws {
        throw RuntimeLaunchError.unavailable("The Windows compatibility backend is not integrated yet. This profile is ready for the Wine/FEX backend.")
    }
}
