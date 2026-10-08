# Architecture

## App layer

SwiftUI provides the launcher, profile list, runtime selector, and Files.app import UI.

## Storage

Imported applications and runtime profiles are stored in the app's Application Support container. Profiles are JSON and point to imported filenames rather than external URLs.

## Java layer

`JavaRuntimeManager` manages Java 8/17/21 runtime directories. The runtime backend is abstract so the UI does not depend on one VM implementation.

## Windows layer

`WindowsBackend` is an abstraction for an eventual in-process Wine/FEX compatibility layer. The backend must be integrated into the app process rather than relying on a normal child-process model.

## Security and licensing

The project only imports files supplied by the user. It does not bypass ownership checks, download pirated software, or bundle proprietary games.
