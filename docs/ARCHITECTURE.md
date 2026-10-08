# Runtime architecture

The project targets iOS/iPadOS and is intended for user-owned software.

## Layers
1. SwiftUI launcher and profile manager.
2. Java runtime manager for Java 8/17/21.
3. Windows compatibility backend based on open-source Wine/FEX-style components.
4. File importer for user-provided EXE/JAR files.
5. JIT integration through the user's supported sideloading/JIT workflow.

The first milestone is a buildable UI shell. Runtime binaries and compatibility components will be integrated separately with their licenses preserved.
