import Foundation

final class ProfileStore {
    static let shared = ProfileStore()

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private lazy var profilesURL: URL = {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = base.appendingPathComponent("RuntimeApp", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("profiles.json")
    }()

    func load() -> [RuntimeProfile] {
        guard let data = try? Data(contentsOf: profilesURL),
              let profiles = try? decoder.decode([RuntimeProfile].self, from: data) else {
            return []
        }
        return profiles
    }

    func save(_ profiles: [RuntimeProfile]) throws {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(profiles)
        try data.write(to: profilesURL, options: .atomic)
    }
}
