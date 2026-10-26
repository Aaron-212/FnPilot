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
    static let settingsWindowID = "settings"

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
        Window("FnPilot Settings", id: Self.settingsWindowID) {
            SettingsView()
                .environment(applicationPreferences)
        }
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
        .defaultSize(width: 700, height: 500)
        .commands {
            SettingsCommands()
        }

        MenuBarExtra {
            MenuBarView()
                .environment(modeController)
        } label: {
            MenuBarIcon(modeController: modeController)
        }
    }
}

private struct MenuBarIcon: View {
    let modeController: FunctionKeyModeController

    var body: some View {
        Image(systemName: modeController.currentMode.systemImageName)
            .accessibilityLabel("FnPilot Menu")
    }
}

private struct SettingsCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Settings…") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: FnPilotApp.settingsWindowID)
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
