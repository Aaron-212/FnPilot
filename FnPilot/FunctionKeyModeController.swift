import AppKit
import OSLog
import Observation

@Observable
final class FunctionKeyModeController {
    private static let logger = Logger(subsystem: AppIdentity.bundleIdentifier, category: "ModeController")

    @ObservationIgnored private var modeManager: FunctionKeyModeManager
    @ObservationIgnored private var applicationPreferences: ApplicationFunctionKeyPreferences
    @ObservationIgnored private var foregroundTargetObserver: ForegroundTargetObserver
    @ObservationIgnored private var workspaceObservations: [NSObjectProtocol] = []
    @ObservationIgnored private var isSessionActive =
        (CGSessionCopyCurrentDictionary() as? [String: Any])?[kCGSessionOnConsoleKey as String] as? Bool ?? false
    @ObservationIgnored private var isSleeping = false

    var globalMode: FunctionKeyMode {
        didSet {
            Self.logger.info("Global mode changed: \(oldValue.rawValue) -> \(self.globalMode.rawValue)")
            modeManager.recordPreferredMode(globalMode)
            applyEffectiveMode(reason: "global mode changed")
        }
    }

    private(set) var currentMode: FunctionKeyMode
    private(set) var frontmostTarget: ForegroundTarget?
    private(set) var currentTargetMode: ApplicationFunctionKeyMode

    init(
        modeManager: FunctionKeyModeManager = FunctionKeyModeManager(),
        applicationPreferences: ApplicationFunctionKeyPreferences = ApplicationFunctionKeyPreferences(),
        foregroundTargetObserver: ForegroundTargetObserver = ForegroundTargetObserver()
    ) {
        self.modeManager = modeManager
        self.applicationPreferences = applicationPreferences
        self.foregroundTargetObserver = foregroundTargetObserver
        self.globalMode = modeManager.preferredMode
        self.currentMode = modeManager.currentMode
        self.frontmostTarget = nil
        self.currentTargetMode = .useGlobalSetting

        self.foregroundTargetObserver.onTargetChange = { [weak self] target in
            self?.setFrontmostTarget(target)
        }
        self.applicationPreferences.onChange = { [weak self] in
            self?.refreshCurrentTargetMode(reason: "per-app preferences changed")
        }

        observeWorkspaceChanges()
        foregroundTargetObserver.refresh()
    }

    deinit {
        for observation in workspaceObservations {
            NSWorkspace.shared.notificationCenter.removeObserver(observation)
        }
    }

    private func observeWorkspaceChanges() {
        let center = NSWorkspace.shared.notificationCenter
        for name in [
            NSWorkspace.willSleepNotification,
            NSWorkspace.didWakeNotification,
            NSWorkspace.sessionDidResignActiveNotification,
            NSWorkspace.sessionDidBecomeActiveNotification,
        ] {
            workspaceObservations.append(
                center.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
                    MainActor.assumeIsolated {
                        self?.handleWorkspaceChange(notification.name)
                    }
                }
            )
        }
    }

    private func handleWorkspaceChange(_ name: Notification.Name) {
        switch name {
        case NSWorkspace.willSleepNotification:
            isSleeping = true
        case NSWorkspace.didWakeNotification:
            isSleeping = false
        case NSWorkspace.sessionDidResignActiveNotification:
            isSessionActive = false
        case NSWorkspace.sessionDidBecomeActiveNotification:
            isSessionActive = true
        default:
            return
        }

        guard isSessionActive, !isSleeping else { return }
        // Resolve the foreground app again; the pre-sleep/session target may be stale.
        modeManager.requireModeReapplication()
        foregroundTargetObserver.refresh()
    }

    func setCurrentTargetMode(_ mode: ApplicationFunctionKeyMode) {
        guard let targetID = frontmostTarget?.id else {
            Self.logger.info("Ignored per-app mode selection: no foreground target")
            return
        }

        Self.logger.info(
            "Per-app mode selected: \(mode.rawValue), target=\(targetID.id, privacy: .private(mask: .hash))")
        applicationPreferences.set(mode, for: targetID)
        currentTargetMode = mode
        applyEffectiveMode(reason: "per-app mode selected")
    }

    private func setFrontmostTarget(_ target: ForegroundTarget?) {
        Self.logger.info("Foreground target changed: \(target?.displayName ?? "none", privacy: .public)")
        frontmostTarget = target
        refreshCurrentTargetMode(reason: "foreground target changed")
    }

    private func refreshCurrentTargetMode(reason: String) {
        currentTargetMode = mode(for: frontmostTarget)
        applyEffectiveMode(reason: reason)
    }

    private func mode(for target: ForegroundTarget?) -> ApplicationFunctionKeyMode {
        guard let targetID = target?.id else {
            return .useGlobalSetting
        }

        return applicationPreferences.mode(for: targetID)
    }

    private func applyEffectiveMode(reason: String) {
        guard isSessionActive, !isSleeping else {
            Self.logger.info("Deferred mode reconciliation: session inactive or sleeping")
            return
        }

        let mode = currentTargetMode.explicitMode ?? globalMode

        Self.logger.info(
            "Resolve mode: reason=\(reason, privacy: .public), target=\(self.frontmostTarget?.displayName ?? "none", privacy: .public), rule=\(self.currentTargetMode.rawValue), global=\(self.globalMode.rawValue), effective=\(mode.rawValue), cached=\(self.modeManager.currentMode.rawValue)"
        )

        modeManager.reconcile(with: mode)
        currentMode = modeManager.currentMode
    }
}
