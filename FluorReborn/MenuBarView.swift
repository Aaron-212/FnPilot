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

        Picker(selection: currentApplicationMode) {
            ForEach(ApplicationFunctionKeyMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        } label: {
            Label {
                Text(currentAppName)
            } icon: {
                currentAppIcon
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
        }

        Divider()

        Button("Open Settings") {
            showSettings()
        }

        Button("Quit") {
            NSApp.terminate(nil)
        }
    }

    private var currentAppName: String {
        modeController.frontmostApplication?.localizedName ?? "No Localized Name"
    }

    private var currentAppIcon: Image {
        if let image = modeController.frontmostApplication?.icon {
            Image(nsImage: image)
        } else {
            Image(systemName: "app")
        }
    }

    private var currentApplicationMode: Binding<ApplicationFunctionKeyMode> {
        Binding {
            modeController.currentApplicationMode
        } set: { mode in
            modeController.setCurrentApplicationMode(mode)
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
