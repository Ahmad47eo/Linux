import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selectedRuntime: RuntimeKind = .java8
    @State private var importedFiles: [RuntimeProfile] = []
    @State private var status = "Ready"
    @State private var showingImporter = false
    @State private var showingError = false
    @State private var errorMessage = ""

    private let profileStore = ProfileStore.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Runtime") {
                    Picker("Runtime", selection: $selectedRuntime) {
                        ForEach(RuntimeKind.allCases, id: \.self) { runtime in
                            Text(runtime.rawValue).tag(runtime)
                        }
                    }
                    LabeledContent("Status", value: status)
                }

                Section("Files") {
                    Button {
                        showingImporter = true
                    } label: {
                        Label("Import EXE, JAR, or file", systemImage: "square.and.arrow.down")
                    }

                    if importedFiles.isEmpty {
                        Text("No imported apps yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(importedFiles) { profile in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(profile.name)
                                    Text(profile.kind.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Run") {
                                    launch(profile)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }

                Section("JIT") {
                    LabeledContent("JIT", value: "Use StikDebug")
                    Text("JIT support is reported here for compatible sideloaded builds. It does not bypass ownership or platform security checks.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Runtime")
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            handleImport(result)
        }
        .alert("Runtime App", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            importedFiles = profileStore.load()
            status = importedFiles.isEmpty ? "Ready" : "(importedFiles.count) profile(s) loaded"
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            var newProfiles: [RuntimeProfile] = []
            var failures = 0

            for url in urls {
                do {
                    let importedURL = try FileImporterService.shared.importFile(from: url)
                    let kind = runtimeKind(for: importedURL)
                    let profile = RuntimeProfile(
                        name: importedURL.deletingPathExtension().lastPathComponent,
                        kind: kind,
                        fileName: importedURL.lastPathComponent
                    )
                    newProfiles.append(profile)
                } catch {
                    failures += 1
                }
            }

            importedFiles.append(contentsOf: newProfiles)
            do {
                try profileStore.save(importedFiles)
                status = "(newProfiles.count) imported" + (failures > 0 ? ", (failures) failed" : "")
            } catch {
                errorMessage = "The files imported, but profiles could not be saved: \(error.localizedDescription)"
                showingError = true
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func runtimeKind(for url: URL) -> RuntimeKind {
        switch url.pathExtension.lowercased() {
        case "exe":
            return .windows
        case "jar":
            return selectedRuntime
        default:
            return selectedRuntime
        }
    }

    private func launch(_ profile: RuntimeProfile) {
        status = "Launching (profile.name)…"
        let backend: RuntimeBackend = profile.kind == .windows
            ? WindowsBackend()
            : JavaBackend(kind: profile.kind)

        Task {
            do {
                try await backend.launch(profile: profile)
                await MainActor.run { status = "Running (profile.name)" }
            } catch {
                await MainActor.run {
                    status = "Backend not ready"
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}
