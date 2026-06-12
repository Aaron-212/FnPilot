import AppKit
import Observation

enum ForegroundTargetID: Hashable, Codable, Identifiable {
    case bundleIdentifier(String)
    case executablePath(String)

    var id: String {
        switch self {
        case .bundleIdentifier(let bundleIdentifier):
            return "bundleIdentifier:\(bundleIdentifier)"
        case .executablePath(let path):
            return "executablePath:\(path)"
        }
    }
}

struct ForegroundTarget {
    let id: ForegroundTargetID
    let runningApplication: NSRunningApplication?
    let displayName: String
    let icon: NSImage?
    let executableURL: URL?
}

@Observable
final class ForegroundTargetObserver {
    var target: ForegroundTarget?

    @ObservationIgnored var onTargetChange: (ForegroundTarget?) -> Void = { _ in }

    private var observation: NSKeyValueObservation?

    init() {
        observation = NSWorkspace.shared.observe(
            \.frontmostApplication,
            options: [.initial, .new]
        ) { [weak self] _, change in
            let application = change.newValue as? NSRunningApplication

            DispatchQueue.main.async {
                let target = Self.target(for: application)
                self?.target = target
                self?.onTargetChange(target)
            }
        }
    }

    deinit {
        observation?.invalidate()
    }

    private static func target(for application: NSRunningApplication?) -> ForegroundTarget? {
        guard let application else {
            return nil
        }

        if let bundleIdentifier = application.bundleIdentifier {
            return ForegroundTarget(
                id: .bundleIdentifier(bundleIdentifier),
                runningApplication: application,
                displayName: application.localizedName ?? bundleIdentifier,
                icon: application.icon,
                executableURL: application.executableURL
            )
        }

        guard let executableURL = application.executableURL else {
            return nil
        }

        return ForegroundTarget(
            id: .executablePath(executableURL.path),
            runningApplication: application,
            displayName: application.localizedName ?? FileManager.default.displayName(atPath: executableURL.path),
            icon: application.icon ?? NSWorkspace.shared.icon(forFile: executableURL.path),
            executableURL: executableURL
        )
    }
}
