import AppKit
import Observation

@Observable
final class FrontmostAppObserver {
    var app: NSRunningApplication?

    private var frontmostApplicationObservation: NSKeyValueObservation?

    init() {
        frontmostApplicationObservation = NSWorkspace.shared.observe(
            \.frontmostApplication,
            options: [.initial, .new]
        ) { [weak self] _, change in
            guard let app = change.newValue as? NSRunningApplication else {
                self?.app = nil
                return
            }

            DispatchQueue.main.async {
                self?.app = app
            }
        }
    }

    deinit {
        frontmostApplicationObservation?.invalidate()
    }
}
