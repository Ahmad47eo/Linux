import Foundation

enum RuntimeLaunchError: LocalizedError {
    case unavailable(String)

    var errorDescription: String? {
        switch self {
        case .unavailable(let message):
            return message
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
        throw RuntimeLaunchError.unavailable(
            "The selected Java runtime is not bundled yet. Import a compatible OpenJDK runtime in a future build."
        )
    }
}

struct WindowsBackend: RuntimeBackend {
    let kind: RuntimeKind = .windows

    func launch(profile: RuntimeProfile) async throws {
        throw RuntimeLaunchError.unavailable(
            "The Windows compatibility backend is not integrated yet. This profile is ready for the Wine/FEX backend."
        )
    }
}
