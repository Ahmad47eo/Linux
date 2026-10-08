import Foundation

enum RuntimeKind: String, Codable, CaseIterable {
    case java8 = "Java 8"
    case java17 = "Java 17"
    case java21 = "Java 21"
    case windows = "Windows EXE"
}

struct RuntimeProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var kind: RuntimeKind
    var fileName: String
    var arguments: String
    var workingDirectory: String

    init(
        id: UUID = UUID(),
        name: String,
        kind: RuntimeKind,
        fileName: String,
        arguments: String = "",
        workingDirectory: String = ""
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.fileName = fileName
        self.arguments = arguments
        self.workingDirectory = workingDirectory
    }
}
