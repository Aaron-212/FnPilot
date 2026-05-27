import Foundation
import Observation

@Observable
final class PerAppSettings {
    private static let storageKey = "personal.aaron212.fluor.perappsettings"

    private let defaults: UserDefaults
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    var items: [String: AppFKeyMode] = [:] {
        didSet {
            save()
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
           let decoded = try? decoder.decode([String: AppFKeyMode].self, from: data) {
            items = decoded
        }
    }

    func mode(forBundle bundle: String) -> AppFKeyMode {
        items[bundle, default: .default]
    }

    func set(_ mode: AppFKeyMode, forBundle bundle: String) {
        items[bundle] = mode
    }

    private func save() {
        guard let data = try? encoder.encode(items) else {
            return
        }

        defaults.set(data, forKey: Self.storageKey)
    }
}
