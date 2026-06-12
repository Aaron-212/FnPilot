import Foundation
import Observation

@Observable
final class ApplicationFunctionKeyPreferences {
    private static let storageKey = "personal.aaron212.fluor.perappsettings"

    @ObservationIgnored var onChange: () -> Void = { }

    private let defaults: UserDefaults
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    var items: [String: ApplicationFunctionKeyMode] = [:] {
        didSet {
            save()
            onChange()
        }
    }

    init(
        defaults: UserDefaults = .standard,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.defaults = defaults
        self.decoder = decoder
        self.encoder = encoder

        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? decoder.decode([String: ApplicationFunctionKeyMode].self, from: data) {
            items = decoded
        }
    }

    func mode(forBundleIdentifier bundleIdentifier: String) -> ApplicationFunctionKeyMode {
        items[bundleIdentifier, default: .useGlobalSetting]
    }

    func set(_ mode: ApplicationFunctionKeyMode, forBundleIdentifier bundleIdentifier: String) {
        items[bundleIdentifier] = mode
    }

    func remove(bundleIdentifier: String) {
        items.removeValue(forKey: bundleIdentifier)
    }

    private func save() {
        guard let data = try? encoder.encode(items) else {
            return
        }

        defaults.set(data, forKey: Self.storageKey)
    }
}
