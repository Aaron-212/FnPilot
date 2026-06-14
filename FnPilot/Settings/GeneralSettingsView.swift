import OSLog
import ServiceManagement
import SwiftUI

struct GeneralSettingsView: View {
    private static let logger = Logger(
        subsystem: AppIdentity.bundleIdentifier,
        category: "Settings"
    )

    @AppStorage("launchAtLogin") private var launchAtLogin = false

    var body: some View {
        Form {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    updateLaunchAtLogin(newValue)
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
