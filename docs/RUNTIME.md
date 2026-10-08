# Runtime integration

## Java

Java 8, 17, and 21 are separate runtime profiles. A compatible unpacked OpenJDK runtime can be imported into the app's private Application Support directory. The expected layout is a runtime folder containing `bin/java`.

The runtime manager validates `bin/java` before accepting a runtime. It does not download proprietary distributions or game files.

## Windows

Windows EXE execution is designed around an in-process compatibility backend. On iOS, the Windows layer cannot rely on an ordinary child-process model, so the Wine/FEX implementation must be integrated into the app process.

## Next stages

1. Add runtime-folder import UI.
2. Validate ARM64-compatible Java runtime binaries.
3. Add an in-process Java VM/native bridge.
4. Add the Wine/FEX backend as a separate build target.
5. Add launch logs and per-profile environment settings.
