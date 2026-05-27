import SwiftUI

@main
struct FluorRebornApp: App {
    @State private var fKeyManager = FKeyManager()

    var body: some Scene {
        Settings {
            SettingsView()
        }
        .defaultLaunchBehavior(.suppressed)
        .windowResizability(.contentMinSize)
        .restorationBehavior(.disabled)

        MenuBarExtra("Fluor Reborn Menu", systemImage: fKeyManager.currentMode.systemImageName) {
            MenuBarItems()
                .environment(fKeyManager)
        }
    }
}
