# Java + EXE Runtime

A legal iOS/iPadOS runtime project for launching user-owned Java applications and Windows executables through open-source compatibility components.

## Goals
- Java 8, 17, and 21 runtime selection
- Windows EXE importing and launching through a Wine/FEX-style compatibility layer
- Per-app profiles and arguments
- JIT diagnostics/integration for compatible sideloaded builds
- Logs and crash diagnostics
- No license bypassing or pirated game distribution

## Planned layout
- `ios/` — iOS app shell
- `runtime/` — runtime management
- `profiles/` — app profiles
- `docs/` — setup and development notes

This project does not bundle proprietary games or bypass ownership checks.
