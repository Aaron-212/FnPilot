import SwiftUI

struct SettingsView: View {
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        TabView {
            Tab {
                GeneralSettingsView()
            } label: {
                Label("General", systemImage: "gear")
            }

            Tab {
                ApplicationFunctionKeyPreferencesView()
            } label: {
                Label("Per App", systemImage: "app.badge")
            }
            
            Tab {
                AboutView()
            } label: {
                Label("About", systemImage: "info.circle")
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .formStyle(.grouped)
        .onKeyPress(.escape) {
            dismissWindow()
            return .handled
        }
    }
}
