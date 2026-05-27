import Foundation
import IOKit.hid
import Observation

enum FKeyMode: Int, CaseIterable, Identifiable {
    case media = 0
    case fn

    var id: Self { self }
}

enum AppFKeyMode: Int, CaseIterable, Codable, Identifiable {
    case media = 0
    case fn
    case `default`

    var id: Self { self }
}

enum FKeyManagerError: LocalizedError {
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

extension FKeyMode {
    static let pickerCases: [Self] = [.fn, .media]

    var title: String {
        switch self {
        case .media:
            "Media"
        case .fn:
            "Fn"
        }
    }

    var systemImageName: String {
        switch self {
        case .media:
            "sun.min"
        case .fn:
            "fn"
        }
    }
}

extension AppFKeyMode {
    static let pickerCases: [Self] = [.default, .fn, .media]

    var title: String {
        switch self {
        case .media:
            "Media"
        case .fn:
            "Fn"
        case .default:
            "Default"
        }
    }
}

@Observable
final class FKeyManager {
    var currentMode: FKeyMode {
        didSet {
            do {
                try FKeyManager.setCurrentFKeyMode(currentMode)
            } catch {
                print("Error: \(error)")
            }
        }
    }

    init() {
        do {
            self.currentMode = try FKeyManager.currentFKeyMode()
        } catch {
            print("Error: \(error)")
            self.currentMode = .media
        }
    }

    static func setCurrentFKeyMode(_ mode: FKeyMode) throws {
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
            throw FKeyManagerError.cannotSetParameter(result)
        }
    }

    static func currentFKeyMode() throws -> FKeyMode {
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
            throw FKeyManagerError.cannotGetParameter
        }

        guard
            let dictionary = property as? [String: Any],
            let mode = dictionary["HIDFKeyMode"] as? Int,
            let fKeyMode = FKeyMode(rawValue: mode)
        else {
            throw FKeyManagerError.cannotGetParameter
        }

        return fKeyMode
    }

    // MARK: - Private

    private static func ioRegistryEntry() throws -> io_registry_entry_t {
        var mainPort: mach_port_t = .zero

        let kr = IOMainPort(mach_port_t(MACH_PORT_NULL), &mainPort)

        guard kr == KERN_SUCCESS else {
            throw FKeyManagerError.cannotCreateMainPort(kr)
        }

        let entry = IORegistryEntryFromPath(
            mainPort,
            "IOService:/IOResources/IOHIDSystem"
        )

        guard entry != IO_OBJECT_NULL else {
            throw FKeyManagerError.invalidRegistryEntry
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
            throw FKeyManagerError.cannotOpenService(kr)
        }

        return connection
    }
}
