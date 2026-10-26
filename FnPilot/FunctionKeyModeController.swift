import AppKit
import OSLog
import Observation

@Observable
final class FunctionKeyModeController {
    private static let logger = Logger(subsystem: AppIdentity.bundleIdentifier, category: "ModeController")

    @ObservationIgnored private var modeManager: FunctionKeyModeManager
    @ObservationIgnored private var applicationPreferences: ApplicationFunctionKeyPreferences
    @ObservationIgnored private var foregroundTargetObserver: ForegroundTargetObserver

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

        setFrontmostTarget(foregroundTargetObserver.target)
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
        let mode = currentTargetMode.explicitMode ?? globalMode
        currentMode = mode

        Self.logger.info(
            "Resolve mode: reason=\(reason, privacy: .public), target=\(self.frontmostTarget?.displayName ?? "none", privacy: .public), rule=\(self.currentTargetMode.rawValue), global=\(self.globalMode.rawValue), effective=\(mode.rawValue), cached=\(self.modeManager.currentMode.rawValue)"
        )

        guard modeManager.currentMode != mode else {
            Self.logger.info("Skipped IOKit write: effective mode matches cached mode")
            return
        }

        Self.logger.info("Applying effective mode through IOKit")
        modeManager.currentMode = mode
    }
}
