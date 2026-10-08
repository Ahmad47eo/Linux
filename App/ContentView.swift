import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selectedRuntime: RuntimeKind = .java8
    @State private var importedFiles: [RuntimeProfile] = []
    @State private var status = "Ready"
    @State private var showingFileImporter = false
    @State private var showingRuntimeImporter = false
    @State private var showingError = false
    @State private var errorMessage = ""

    private let profileStore = ProfileStore.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Java runtime") {
                    Picker("Runtime", selection: $selectedRuntime) {
                        ForEach([RuntimeKind.java8, .java17, .java21], id: \.self) { runtime in
                            Text(runtime.rawValue).tag(runtime)
                        }
                    }

                    Button("Import OpenJDK runtime folder") {
                        showingRuntimeImporter = true
                    }

                    LabeledContent("Status", value: status)
                }

                Section("Applications") {
                    Button {
                        showingFileImporter = true
                    } label: {
                        Label("Import EXE or JAR", systemImage: "square.and.arrow.down")
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
            isPresented: $showingFileImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            handleImport(result)
        }
        .fileImporter(
            isPresented: $showingRuntimeImporter,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            handleRuntimeImport(result)
        }
        .alert("Runtime App", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            importedFiles = profileStore.load()
            status = importedFiles.isEmpty ? "Ready" : "\(importedFiles.count) profile(s) loaded"
        }
    }

    private func handleRuntimeImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else {
            if case .failure(let error) = result {
                errorMessage = error.localizedDescription
                showingError = true
            }
            return
        }

        do {
            try JavaRuntimeManager.shared.installImportedRuntime(from: url, kind: selectedRuntime)
            status = "\(selectedRuntime.rawValue) runtime installed"
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
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
                    newProfiles.append(RuntimeProfile(
                        name: importedURL.deletingPathExtension().lastPathComponent,
                        kind: kind,
                        fileName: importedURL.lastPathComponent
                    ))
                } catch {
                    failures += 1
                }
            }

            importedFiles.append(contentsOf: newProfiles)
            do {
                try profileStore.save(importedFiles)
                status = "\(newProfiles.count) imported" + (failures > 0 ? ", \(failures) failed" : "")
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
        url.pathExtension.lowercased() == "exe" ? .windows : selectedRuntime
    }

    private func launch(_ profile: RuntimeProfile) {
        status = "Launching \(profile.name)…"
        let backend: RuntimeBackend = profile.kind == .windows
            ? WindowsBackend()
            : JavaBackend(kind: profile.kind)

        Task {
            do {
                try await backend.launch(profile: profile)
                await MainActor.run { status = "Running \(profile.name)" }
            } catch {
                await MainActor.run {
                    status = "Launch failed"
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}
