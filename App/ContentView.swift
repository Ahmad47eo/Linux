import SwiftUI

struct ContentView: View {
    @State private var selectedRuntime = "Java 8"
    @State private var importedFiles: [String] = []
    @State private var status = "Ready"

    private let runtimes = ["Java 8", "Java 17", "Java 21"]

    var body: some View {
        NavigationStack {
            List {
                Section("Runtime") {
                    Picker("Java runtime", selection: $selectedRuntime) {
                        ForEach(runtimes, id: \.self) { Text($0) }
                    }
                    LabeledContent("Status", value: status)
                }

                Section("Files") {
                    Button("Import EXE or JAR") {
                        status = "Use the Files picker in the next build"
                    }
                    ForEach(importedFiles, id: \.self) { Text($0) }
                }

                Section("JIT") {
                    LabeledContent("JIT", value: "Use StikDebug")
                    Text("This app does not bypass iOS security or app ownership checks.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Runtime")
        }
    }
}
