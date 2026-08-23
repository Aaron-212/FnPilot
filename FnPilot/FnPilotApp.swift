import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        do {
            try FunctionKeyModeManager.applyTerminationMode()
        } catch {
            print("Error: \(error)")
        }
    }
}

@main
struct FnPilotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var modeController: FunctionKeyModeController
    @State private var applicationPreferences: ApplicationFunctionKeyPreferences

    init() {
        let applicationPreferencesState = ApplicationFunctionKeyPreferences()
        applicationPreferences = applicationPreferencesState
        modeController = FunctionKeyModeController(
            applicationPreferences: applicationPreferencesState
        )
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
