import SwiftUI

struct MenuBarItems: View {
    @Environment(\.openSettings) private var openSettings
    @Environment(FKeyManager.self) private var fKeyManager
    @State private var frontmostAppObserver = FrontmostAppObserver()
    @State private var perAppSettings = PerAppSettings()

    var body: some View {
        @Bindable var fKeyManager = fKeyManager

        Picker(selection: currentAppMode) {
            ForEach(AppFKeyMode.pickerCases) { mode in
                Text(mode.title).tag(mode)
            }
        } label: {
            Label {
                Text(currentAppName)
            } icon: {
                currentAppIcon
            }
        }

        Picker(selection: $fKeyManager.currentMode) {
            ForEach(FKeyMode.pickerCases) { mode in
                Text(mode.title).tag(mode)
            }
        } label: {
            Label {
                Text("Global mode")
            } icon: {
                Image(systemName: "finder")
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
        frontmostAppObserver.app?.localizedName ?? "No Localized Name"
    }

    private var currentAppIcon: Image {
        if let image = frontmostAppObserver.app?.icon {
            Image(nsImage: image)
        } else {
            Image(systemName: "app")
        }
    }

    private var currentAppMode: Binding<AppFKeyMode> {
        Binding {
            guard let bundleIdentifier = frontmostAppObserver.app?.bundleIdentifier else {
                return .default
            }

            return perAppSettings.mode(forBundle: bundleIdentifier)
        } set: { mode in
            guard let bundleIdentifier = frontmostAppObserver.app?.bundleIdentifier else {
                return
            }

            perAppSettings.set(mode, forBundle: bundleIdentifier)
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
