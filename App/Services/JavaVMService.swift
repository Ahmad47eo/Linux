import Foundation

@_silgen_name("runtime_java_vm_start")
private func runtime_java_vm_start(_ runtimeDirectory: UnsafePointer<CChar>, _ classPath: UnsafePointer<CChar>, _ options: UnsafePointer<CChar>?) -> Int32
@_silgen_name("runtime_java_vm_running")
private func runtime_java_vm_running() -> Int32
@_silgen_name("runtime_java_vm_stop")
private func runtime_java_vm_stop() -> Int32
@_silgen_name("runtime_java_vm_last_error")
private func runtime_java_vm_last_error() -> UnsafePointer<CChar>?

final class JavaVMService {
    static let shared = JavaVMService()

    var isRunning: Bool { runtime_java_vm_running() != 0 }

    func start(runtime: URL, classPath: URL, options: [String] = []) throws {
        let optionText = options.joined(separator: " ") 
        let result = runtime.path.withCString { runtimePtr in
            classPath.path.withCString { classPathPtr in
                optionText.withCString { optionsPtr in
                    runtime_java_vm_start(runtimePtr, classPathPtr, optionText.isEmpty ? nil : optionsPtr)
                }
            }
        }
        guard result == 0 else {
            let message = runtime_java_vm_last_error().map { String(cString: $0) } ?? "Java VM failed to start."
            throw RuntimeLaunchError.unavailable(message)
        }
    }

    func stop() { _ = runtime_java_vm_stop() }
}
