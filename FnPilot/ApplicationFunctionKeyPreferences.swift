import Foundation
import Observation

@Observable
final class ApplicationFunctionKeyPreferences {
    private static let storageKey = "personal.aaron212.fnpilot.perappsettings"

    @ObservationIgnored var onChange: () -> Void = { }

    private let defaults: UserDefaults
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    var items: [ForegroundTargetID: ApplicationFunctionKeyMode] = [:] {
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
           let decoded = try? decoder.decode([ForegroundTargetID: ApplicationFunctionKeyMode].self, from: data) {
            items = decoded
        }
    }

    func mode(for targetID: ForegroundTargetID) -> ApplicationFunctionKeyMode {
        items[targetID, default: .useGlobalSetting]
    }

    func set(_ mode: ApplicationFunctionKeyMode, for targetID: ForegroundTargetID) {
        items[targetID] = mode
    }

    func remove(targetID: ForegroundTargetID) {
        items.removeValue(forKey: targetID)
    }

    private func save() {
        guard let data = try? encoder.encode(items) else {
            return
        }

        defaults.set(data, forKey: Self.storageKey)
    }
}
