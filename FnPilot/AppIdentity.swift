import Foundation

enum AppIdentity {
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier
            ?? Bundle.main.executableURL?.deletingPathExtension().lastPathComponent
            ?? ProcessInfo.processInfo.processName
    }
}
