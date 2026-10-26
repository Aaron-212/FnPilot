import AppKit
import SwiftUI

struct AboutView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 128, height: 128)
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text(verbatim: "FnPilot")
                    .font(.largeTitle.bold())

                Text("Version \(version) (\(build))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Link("Homepage", destination: URL(string: "https://aaron212.com/projects/fnpilot/")!)
                
                Link("GitHub", destination: URL(string: "https://github.com/Aaron-212/FnPilot")!)
            }

            Text(verbatim: "©Aaron212 2026 under MIT license.")
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AboutView()
}
