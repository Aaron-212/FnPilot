import Foundation
import SwiftUI
import IOKit.hid
import Observation

enum FunctionKeyMode: Int, CaseIterable, Identifiable {
    case mediaControls = 0
    case functionKeys

    var id: Self { self }
}

enum ApplicationFunctionKeyMode: Int, CaseIterable, Codable, Identifiable {
    case mediaControls = 0
    case functionKeys
    case useGlobalSetting

    var id: Self { self }
}

enum FunctionKeyModeManagerError: LocalizedError {
    case cannotCreateMainPort(kern_return_t)
    case cannotOpenService(kern_return_t)
    case cannotSetParameter(kern_return_t)
    case cannotGetParameter
    case invalidRegistryEntry

    var errorDescription: String? {
        switch self {
        case .cannotCreateMainPort(let code):
            return "Failed to create IOKit main port (\(code))"

        case .cannotOpenService(let code):
            return "Failed to open IOHID service (\(code))"

        case .cannotSetParameter(let code):
            return "Failed to set F-key mode (\(code))"

        case .cannotGetParameter:
            return "Failed to read F-key mode"

        case .invalidRegistryEntry:
            return "Invalid IORegistry entry"
        }
    }
}

extension FunctionKeyMode {
    var title: String {
        switch self {
        case .mediaControls:
            String(localized: "Media")
        case .functionKeys:
            String(localized: "Fn")
        }
    }

    var systemImageName: String {
        switch self {
        case .mediaControls:
            "sun.min"
        case .functionKeys:
            "fn"
        }
    }
}

extension ApplicationFunctionKeyMode {
    var explicitMode: FunctionKeyMode? {
        switch self {
        case .mediaControls:
            .mediaControls
        case .functionKeys:
            .functionKeys
        case .useGlobalSetting:
            nil
        }
    }

    var title: String {
        switch self {
        case .mediaControls:
            String(localized: "Media")
        case .functionKeys:
            String(localized: "Fn")
        case .useGlobalSetting:
            String(localized: "Default")
        }
    }
}

@Observable
final class FunctionKeyModeManager {
    private static let preferredModeStorageKey = "\(AppIdentity.bundleIdentifier.lowercased()).globalmode"
    static let terminationModeStorageKey = "\(AppIdentity.bundleIdentifier.lowercased()).terminationmode"

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private(set) var preferredMode: FunctionKeyMode

    var currentMode: FunctionKeyMode {
        didSet {
            do {
                try FunctionKeyModeManager.setCurrentMode(currentMode)
            } catch {
                print("Error: \(error)")
            }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let preferredMode = FunctionKeyMode(
            rawValue: defaults.integer(forKey: Self.preferredModeStorageKey)
        ) ?? .mediaControls
        self.preferredMode = preferredMode
        self.currentMode = preferredMode

        do {
            try FunctionKeyModeManager.setCurrentMode(preferredMode)
        } catch {
            print("Error: \(error)")
        }
    }

    func recordPreferredMode(_ mode: FunctionKeyMode) {
        preferredMode = mode
        defaults.set(mode.rawValue, forKey: Self.preferredModeStorageKey)
    }

    static func applyTerminationMode(defaults: UserDefaults = .standard) throws {
        let mode = FunctionKeyMode(
            rawValue: defaults.integer(forKey: terminationModeStorageKey)
        ) ?? .mediaControls

        try setCurrentMode(mode)
    }

    static func setCurrentMode(_ mode: FunctionKeyMode) throws {
        let connect = try serviceConnection()
        defer { IOServiceClose(connect) }

        var value = mode.rawValue
        let number = CFNumberCreate(
            kCFAllocatorDefault,
            .intType,
            &value
        )

        let result = IOHIDSetCFTypeParameter(
            connect,
            kIOHIDFKeyModeKey as CFString,
            number
        )

        guard result == KERN_SUCCESS else {
            throw FunctionKeyModeManagerError.cannotSetParameter(result)
        }
    }

    static func currentMode() throws -> FunctionKeyMode {
        let registry = try ioRegistryEntry()
        defer { IOObjectRelease(registry) }

        guard
            let property = IORegistryEntryCreateCFProperty(
                registry,
                "HIDParameters" as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue()
        else {
            throw FunctionKeyModeManagerError.cannotGetParameter
        }

        guard
            let dictionary = property as? [String: Any],
            let mode = dictionary["HIDFKeyMode"] as? Int,
            let functionKeyMode = FunctionKeyMode(rawValue: mode)
        else {
            throw FunctionKeyModeManagerError.cannotGetParameter
        }

        return functionKeyMode
    }

    // MARK: - Private

    private static func ioRegistryEntry() throws -> io_registry_entry_t {
        var mainPort: mach_port_t = .zero

        let kr = IOMainPort(mach_port_t(MACH_PORT_NULL), &mainPort)

        guard kr == KERN_SUCCESS else {
            throw FunctionKeyModeManagerError.cannotCreateMainPort(kr)
        }

        let entry = IORegistryEntryFromPath(
            mainPort,
            "IOService:/IOResources/IOHIDSystem"
        )

        guard entry != IO_OBJECT_NULL else {
            throw FunctionKeyModeManagerError.invalidRegistryEntry
        }

        return entry
    }

    private static func serviceConnection() throws -> io_connect_t {
        let service = try ioRegistryEntry()
        defer { IOObjectRelease(service) }

        var connection: io_connect_t = .zero

        let kr = IOServiceOpen(
            service,
            mach_task_self_,
            UInt32(kIOHIDParamConnectType),
            &connection
        )

        guard kr == KERN_SUCCESS else {
            throw FunctionKeyModeManagerError.cannotOpenService(kr)
        }

        return connection
    }
}
