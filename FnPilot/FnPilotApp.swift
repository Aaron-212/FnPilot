import SwiftUI

@main
struct FnPilotApp: App {
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

        MenuBarExtra("FnPilot Menu", systemImage: modeController.currentMode.systemImageName) {
            MenuBarView()
                .environment(modeController)
        }
    }
}
