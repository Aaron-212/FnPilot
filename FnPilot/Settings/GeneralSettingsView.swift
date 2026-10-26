import AppKit
import OSLog
import ServiceManagement
import SwiftUI

struct GeneralSettingsView: View {
    private static let logger = Logger(
        subsystem: AppIdentity.bundleIdentifier,
        category: "Settings"
    )

    @State private var launchAtLoginStatus = SMAppService.mainApp.status
    @State private var launchAtLoginError = ""
    @State private var showsLaunchAtLoginError = false
    @AppStorage(FunctionKeyModeManager.terminationModeStorageKey)
    private var terminationMode = TerminationFunctionKeyMode.mediaControls

    var body: some View {
        Form {
            Section {
                Toggle(
                    "Launch at login",
                    isOn: Binding(
                        get: { launchAtLoginStatus == .enabled },
                        set: { updateLaunchAtLogin($0) }
                    )
                )

                if launchAtLoginStatus == .requiresApproval {
                    LabeledContent("Launch at login requires approval.") {
                        Button("Open Login Items") {
                            SMAppService.openSystemSettingsLoginItems()
                        }
                    }
                }
            }

            Picker("Mode after quitting", selection: $terminationMode) {
                ForEach(TerminationFunctionKeyMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
        }
        .onAppear(perform: refreshLaunchAtLoginStatus)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshLaunchAtLoginStatus()
        }
        .alert("Couldn’t Update Launch at Login", isPresented: $showsLaunchAtLoginError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(launchAtLoginError)
        }
    }

    private func refreshLaunchAtLoginStatus() {
        launchAtLoginStatus = SMAppService.mainApp.status
    }

    private func updateLaunchAtLogin(_ isEnabled: Bool) {
        defer { refreshLaunchAtLoginStatus() }

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
            launchAtLoginError = error.localizedDescription
            showsLaunchAtLoginError = true
        }
    }
}
