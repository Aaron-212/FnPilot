import SwiftUI

struct SettingsView: View {
    private static let minimumTabSize = CGSize(width: 320, height: 320)

    var body: some View {
        TabView {
            Tab {
                FluorRebornAppSettings()
            } label: {
                Label("Main", systemImage: "gear")
            }

            Tab {
                Text("Hello")
                    .frame(
                        minWidth: Self.minimumTabSize.width,
                        minHeight: Self.minimumTabSize.height
                    )
            } label: {
                Label("Per App", systemImage: "app.badge")
            }
        }
        .formStyle(.grouped)
    }
}
