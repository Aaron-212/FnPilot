import AppKit
import Observation

@Observable
final class FunctionKeyModeController {
    @ObservationIgnored private var modeManager: FunctionKeyModeManager
    @ObservationIgnored private var applicationPreferences: ApplicationFunctionKeyPreferences
    @ObservationIgnored private var frontmostApplicationObserver: FrontmostApplicationObserver

    var globalMode: FunctionKeyMode {
        didSet {
            applyEffectiveMode()
        }
    }

    private(set) var currentMode: FunctionKeyMode
    private(set) var frontmostApplication: NSRunningApplication?
    private(set) var currentApplicationMode: ApplicationFunctionKeyMode

    init(
        modeManager: FunctionKeyModeManager = FunctionKeyModeManager(),
        applicationPreferences: ApplicationFunctionKeyPreferences = ApplicationFunctionKeyPreferences(),
        frontmostApplicationObserver: FrontmostApplicationObserver = FrontmostApplicationObserver()
    ) {
        self.modeManager = modeManager
        self.applicationPreferences = applicationPreferences
        self.frontmostApplicationObserver = frontmostApplicationObserver
        self.globalMode = modeManager.currentMode
        self.currentMode = modeManager.currentMode
        self.frontmostApplication = nil
        self.currentApplicationMode = .useGlobalSetting

        self.frontmostApplicationObserver.onApplicationChange = { [weak self] application in
            self?.setFrontmostApplication(application)
        }
        self.applicationPreferences.onChange = { [weak self] in
            self?.refreshCurrentApplicationMode()
        }

        setFrontmostApplication(frontmostApplicationObserver.application)
    }

    func setCurrentApplicationMode(_ mode: ApplicationFunctionKeyMode) {
        guard let bundleIdentifier = frontmostApplication?.bundleIdentifier else {
            return
        }

        applicationPreferences.set(mode, forBundleIdentifier: bundleIdentifier)
        currentApplicationMode = mode
        applyEffectiveMode()
    }

    private func setFrontmostApplication(_ application: NSRunningApplication?) {
        frontmostApplication = application
        refreshCurrentApplicationMode()
    }

    private func refreshCurrentApplicationMode() {
        currentApplicationMode = mode(for: frontmostApplication)
        applyEffectiveMode()
    }

    private func mode(for application: NSRunningApplication?) -> ApplicationFunctionKeyMode {
        guard let bundleIdentifier = application?.bundleIdentifier else {
            return .useGlobalSetting
        }

        return applicationPreferences.mode(forBundleIdentifier: bundleIdentifier)
    }

    private func applyEffectiveMode() {
        let mode = currentApplicationMode.explicitMode ?? globalMode
        currentMode = mode

        guard modeManager.currentMode != mode else {
            return
        }

        modeManager.currentMode = mode
    }
}
