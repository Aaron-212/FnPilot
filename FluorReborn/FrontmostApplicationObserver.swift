import AppKit
import Observation

@Observable
final class FrontmostApplicationObserver {
    var application: NSRunningApplication?

    @ObservationIgnored var onApplicationChange: (NSRunningApplication?) -> Void = { _ in }

    private var observation: NSKeyValueObservation?

    init() {
        observation = NSWorkspace.shared.observe(
            \.frontmostApplication,
            options: [.initial, .new]
        ) { [weak self] _, change in
            let application = change.newValue as? NSRunningApplication

            DispatchQueue.main.async {
                self?.application = application
                self?.onApplicationChange(application)
            }
        }
    }

    deinit {
        observation?.invalidate()
    }
}
