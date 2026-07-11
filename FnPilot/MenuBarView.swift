import SwiftUI

struct MenuBarView: View {
    @Environment(\.openSettings) private var openSettings
    @Environment(FunctionKeyModeController.self) private var modeController

    var body: some View {
        @Bindable var modeController = modeController

        Label {
            Text("Current mode: \(modeController.currentMode.title)")
        } icon: {
            Image(systemName: modeController.currentMode.systemImageName)
        }

        Picker(selection: currentTargetMode) {
            ForEach(ApplicationFunctionKeyMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        } label: {
            Label {
                Text(currentTargetName)
            } icon: {
                currentTargetIcon
            }
        }

        Picker(selection: $modeController.globalMode) {
            ForEach(FunctionKeyMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        } label: {
            Label {
                Text("Global mode")
            } icon: {
                Image(systemName: "macwindow.on.rectangle")
            }
            .labelStyle(.titleAndIcon)
        }

        Divider()

        Button("Open Settings") {
            showSettings()
        }

        Button("Quit") {
            NSApp.terminate(nil)
        }
    }

    private var currentTargetName: String {
        modeController.frontmostTarget?.displayName ?? "No Foreground Target"
    }

    private var currentTargetIcon: Image {
        if let image = modeController.frontmostTarget?.icon {
            Image(nsImage: image)
        } else if case .executablePath = modeController.frontmostTarget?.id {
            Image(systemName: "terminal")
        } else {
            Image(systemName: "app")
        }
    }

    private var currentTargetMode: Binding<ApplicationFunctionKeyMode> {
        Binding {
            modeController.currentTargetMode
        } set: { mode in
            modeController.setCurrentTargetMode(mode)
        }
    }

    private func showSettings() {
        NSApp.activate(ignoringOtherApps: true)
        openSettings()

        DispatchQueue.main.async {
            NSApp.windows.first {
                $0.identifier?.rawValue == "com.apple.SwiftUI.Settings"
            }?.makeKeyAndOrderFront(nil)
        }
    }
}
