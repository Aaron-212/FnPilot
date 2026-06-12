import AppKit
import Observation

@Observable
final class FunctionKeyModeController {
    @ObservationIgnored private var modeManager: FunctionKeyModeManager
    @ObservationIgnored private var applicationPreferences: ApplicationFunctionKeyPreferences
    @ObservationIgnored private var foregroundTargetObserver: ForegroundTargetObserver

    var globalMode: FunctionKeyMode {
        didSet {
            applyEffectiveMode()
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
        self.globalMode = modeManager.currentMode
        self.currentMode = modeManager.currentMode
        self.frontmostTarget = nil
        self.currentTargetMode = .useGlobalSetting

        self.foregroundTargetObserver.onTargetChange = { [weak self] target in
            self?.setFrontmostTarget(target)
        }
        self.applicationPreferences.onChange = { [weak self] in
            self?.refreshCurrentTargetMode()
        }

        setFrontmostTarget(foregroundTargetObserver.target)
    }

    func setCurrentTargetMode(_ mode: ApplicationFunctionKeyMode) {
        guard let targetID = frontmostTarget?.id else {
            return
        }

        applicationPreferences.set(mode, for: targetID)
        currentTargetMode = mode
        applyEffectiveMode()
    }

    private func setFrontmostTarget(_ target: ForegroundTarget?) {
        frontmostTarget = target
        refreshCurrentTargetMode()
    }

    private func refreshCurrentTargetMode() {
        currentTargetMode = mode(for: frontmostTarget)
        applyEffectiveMode()
    }

    private func mode(for target: ForegroundTarget?) -> ApplicationFunctionKeyMode {
        guard let targetID = target?.id else {
            return .useGlobalSetting
        }

        return applicationPreferences.mode(for: targetID)
    }

    private func applyEffectiveMode() {
        let mode = currentTargetMode.explicitMode ?? globalMode
        currentMode = mode

        guard modeManager.currentMode != mode else {
            return
        }

        modeManager.currentMode = mode
    }
}
