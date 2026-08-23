import OSLog
import ServiceManagement
import SwiftUI

struct GeneralSettingsView: View {
    private static let logger = Logger(
        subsystem: AppIdentity.bundleIdentifier,
        category: "Settings"
    )

    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage(FunctionKeyModeManager.terminationModeStorageKey)
    private var terminationMode = FunctionKeyMode.mediaControls

    var body: some View {
        Form {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    updateLaunchAtLogin(newValue)
                }

            Picker("Mode after quitting", selection: $terminationMode) {
                ForEach(FunctionKeyMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
        }
    }

    private func updateLaunchAtLogin(_ isEnabled: Bool) {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            Self.logger.error(
                "Failed to update launch at login: \(error.localizedDescription, privacy: .public)"
            )
        }
    }
}
