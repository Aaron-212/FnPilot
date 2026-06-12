import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            Tab {
                GeneralSettingsView()
            } label: {
                Label("Main", systemImage: "gear")
            }

            Tab {
                ApplicationFunctionKeyPreferencesView()
            } label: {
                Label("Per App", systemImage: "app.badge")
            }
        }
        .formStyle(.grouped)
    }
}
