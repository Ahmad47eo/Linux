import Foundation

struct RuntimeStatus {
    let java8Installed: Bool
    let java17Installed: Bool
    let java21Installed: Bool

    static func current() -> RuntimeStatus {
        let manager = JavaRuntimeManager.shared
        return RuntimeStatus(java8Installed: manager.isInstalled(.java8), java17Installed: manager.isInstalled(.java17), java21Installed: manager.isInstalled(.java21))
    }
}
