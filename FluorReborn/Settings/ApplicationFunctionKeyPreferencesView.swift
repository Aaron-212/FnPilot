import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ApplicationFunctionKeyPreferencesView: View {
    @Environment(ApplicationFunctionKeyPreferences.self) private var applicationPreferences

    private static let iconSize: CGFloat = 28

    var body: some View {
        VStack(spacing: 0) {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No Per-App Settings",
                    systemImage: "app.badge"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(entries) { entry in
                        appRow(for: entry)
                    }
                }
                .padding(.horizontal)
            }

            Divider()

            HStack {
                Button {
                    addApplication()
                } label: {
                    Label("Add App", systemImage: "plus")
                }

                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 440, minHeight: 320)
    }

    private var entries: [ApplicationFunctionKeyPreference] {
        applicationPreferences.items
            .map { bundleIdentifier, _ in
                ApplicationFunctionKeyPreference(
                    bundleIdentifier: bundleIdentifier
                )
            }
            .sorted {
                appName(for: $0.bundleIdentifier)
                    .localizedCaseInsensitiveCompare(appName(for: $1.bundleIdentifier)) == .orderedAscending
            }
    }

    private func appRow(for entry: ApplicationFunctionKeyPreference) -> some View {
        HStack(spacing: 10) {
            appIcon(for: entry.bundleIdentifier)
                .resizable()
                .frame(width: Self.iconSize, height: Self.iconSize)

            VStack(alignment: .leading, spacing: 2) {
                Text(appName(for: entry.bundleIdentifier))
                    .lineLimit(1)
                Text(entry.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Picker("Mode", selection: binding(for: entry.bundleIdentifier)) {
                ForEach(ApplicationFunctionKeyMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .labelsHidden()
            .frame(width: 120)

            Button {
                applicationPreferences.remove(bundleIdentifier: entry.bundleIdentifier)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }

    private func binding(for bundleIdentifier: String) -> Binding<ApplicationFunctionKeyMode> {
        Binding {
            applicationPreferences.mode(forBundleIdentifier: bundleIdentifier)
        } set: { mode in
            applicationPreferences.set(mode, forBundleIdentifier: bundleIdentifier)
        }
    }

    private func addApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        guard panel.runModal() == .OK,
              let url = panel.url,
              let bundleIdentifier = Bundle(url: url)?.bundleIdentifier
        else {
            return
        }

        applicationPreferences.set(.useGlobalSetting, forBundleIdentifier: bundleIdentifier)
    }

    private func appName(for bundleIdentifier: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return bundleIdentifier
        }

        return FileManager.default.displayName(atPath: url.path)
    }

    private func appIcon(for bundleIdentifier: String) -> Image {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return Image(systemName: "app")
        }

        return Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
    }
}

private struct ApplicationFunctionKeyPreference: Identifiable {
    let bundleIdentifier: String

    var id: String { bundleIdentifier }
}
