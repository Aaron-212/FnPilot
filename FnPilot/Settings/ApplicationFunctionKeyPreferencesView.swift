import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ApplicationFunctionKeyPreferencesView: View {
    @Environment(ApplicationFunctionKeyPreferences.self) private
        var applicationPreferences
    @State private var selectedItems = Set<ApplicationFunctionKeyPreference.ID>()

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
                List(entries, selection: $selectedItems) { entry in
                    appRow(for: entry)
                }
                .listStyle(.inset)
            }

            Divider()

            HStack {
                Button {
                    addApplication()
                } label: {
                    Label("Add App", systemImage: "plus")
                }

                Button {
                    addExecutable()
                } label: {
                    Label("Add Executable", systemImage: "plus")
                }

                Spacer()
                
                Button(role: .destructive) {
                    deleteItems(at: selectedItems)
                } label: {
                    Label("Remove Item", systemImage: "minus")
                }
                .disabled(selectedItems.isEmpty)
            }
            .padding()
        }
    }

    private var entries: [ApplicationFunctionKeyPreference] {
        applicationPreferences.items
            .map { targetID, _ in
                preference(for: targetID)
            }
            .sorted {
                let nameComparison = $0.displayName
                    .localizedCaseInsensitiveCompare($1.displayName)
                if nameComparison != .orderedSame {
                    return nameComparison == .orderedAscending
                }

                return $0.sortFallback.localizedCaseInsensitiveCompare(
                    $1.sortFallback
                ) == .orderedAscending
            }
    }

    private func appRow(for entry: ApplicationFunctionKeyPreference)
        -> some View
    {
        HStack {
            entry.icon
                .resizable()
                .frame(width: Self.iconSize, height: Self.iconSize)

            VStack(alignment: .leading) {
                Text(entry.displayName)

                Text(entry.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .truncationMode(.middle)
            }
            .lineLimit(1)

            Spacer()

            Picker("Mode", selection: binding(for: entry.id)) {
                ForEach(ApplicationFunctionKeyMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .labelsHidden()
        }
    }

    private func deleteItems(at ids: Set<ApplicationFunctionKeyPreference.ID>) {
        for id in ids {
            applicationPreferences.remove(targetID: id)
        }
    }

    private func binding(for targetID: ForegroundTargetID) -> Binding<
        ApplicationFunctionKeyMode
    > {
        Binding {
            applicationPreferences.mode(for: targetID)
        } set: { mode in
            applicationPreferences.set(mode, for: targetID)
        }
    }

    private func addApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.applicationBundle]

        guard panel.runModal() == .OK,
            let url = panel.url,
            let bundleIdentifier = Bundle(url: url)?.bundleIdentifier
        else {
            return
        }

        applicationPreferences.set(
            .useGlobalSetting,
            for: .bundleIdentifier(bundleIdentifier)
        )
    }

    private func addExecutable() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK,
            let url = panel.url
        else {
            return
        }

        applicationPreferences.set(
            .useGlobalSetting,
            for: .executablePath(url.path)
        )
    }

    private func preference(for targetID: ForegroundTargetID)
        -> ApplicationFunctionKeyPreference
    {
        switch targetID {
        case .bundleIdentifier(let bundleIdentifier):
            guard
                let url = NSWorkspace.shared.urlForApplication(
                    withBundleIdentifier: bundleIdentifier
                )
            else {
                return ApplicationFunctionKeyPreference(
                    id: targetID,
                    displayName: bundleIdentifier,
                    detail: bundleIdentifier,
                    icon: Image(systemName: "app"),
                    sortFallback: bundleIdentifier
                )
            }

            return ApplicationFunctionKeyPreference(
                id: targetID,
                displayName: FileManager.default.displayName(atPath: url.path),
                detail: bundleIdentifier,
                icon: Image(
                    nsImage: NSWorkspace.shared.icon(forFile: url.path)
                ),
                sortFallback: bundleIdentifier
            )
        case .executablePath(let path):
            return ApplicationFunctionKeyPreference(
                id: targetID,
                displayName: FileManager.default.displayName(atPath: path),
                detail: path,
                icon: Image(nsImage: NSWorkspace.shared.icon(forFile: path)),
                sortFallback: path
            )
        }
    }
}

private struct ApplicationFunctionKeyPreference: Identifiable {
    let id: ForegroundTargetID
    let displayName: String
    let detail: String
    let icon: Image
    let sortFallback: String
}
