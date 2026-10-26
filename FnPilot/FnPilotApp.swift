import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    var modeManager: FunctionKeyModeManager?

    func applicationWillTerminate(_ notification: Notification) {
        do {
            try modeManager?.applyTerminationMode()
        } catch {
            FunctionKeyModeManager.logModeChangeError(error, context: "Termination mode change")
        }
    }
}

@main
struct FnPilotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var modeController: FunctionKeyModeController
    @State private var applicationPreferences: ApplicationFunctionKeyPreferences

    init() {
        let modeManager = FunctionKeyModeManager()
        let applicationPreferencesState = ApplicationFunctionKeyPreferences()
        applicationPreferences = applicationPreferencesState
        modeController = FunctionKeyModeController(
            modeManager: modeManager,
            applicationPreferences: applicationPreferencesState
        )
        appDelegate.modeManager = modeManager
    }

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(applicationPreferences)
        }
        .defaultLaunchBehavior(.suppressed)
        .windowResizability(.contentMinSize)
        .restorationBehavior(.disabled)
        .defaultSize(width: 700, height: 500)

        MenuBarExtra("FnPilot Menu", systemImage: modeController.currentMode.systemImageName) {
            MenuBarView()
                .environment(modeController)
        }
    }
}
