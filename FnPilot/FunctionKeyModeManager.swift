import Foundation
import IOKit.hid
import OSLog
import Observation
import SwiftUI

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
    private static let logger = Logger(subsystem: AppIdentity.bundleIdentifier, category: "FunctionKeyMode")

    private static let preferredModeStorageKey = "\(AppIdentity.bundleIdentifier.lowercased()).globalmode"
    static let terminationModeStorageKey = "\(AppIdentity.bundleIdentifier.lowercased()).terminationmode"

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private(set) var preferredMode: FunctionKeyMode

    var currentMode: FunctionKeyMode {
        didSet {
            Self.logger.info("Cached mode changed: \(oldValue.rawValue) -> \(self.currentMode.rawValue)")
            do {
                try FunctionKeyModeManager.setCurrentMode(currentMode)
            } catch {
                Self.logModeChangeError(error, context: "Mode change")
            }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let preferredMode =
            FunctionKeyMode(
                rawValue: defaults.integer(forKey: Self.preferredModeStorageKey)
            ) ?? .mediaControls
        self.preferredMode = preferredMode
        self.currentMode = preferredMode

        Self.logger.info("Startup: applying saved global mode=\(preferredMode.rawValue)")
        do {
            try FunctionKeyModeManager.setCurrentMode(preferredMode)
        } catch {
            Self.logModeChangeError(error, context: "Startup mode change")
        }
    }

    func recordPreferredMode(_ mode: FunctionKeyMode) {
        Self.logger.info("Saving global preference: mode=\(mode.rawValue)")
        preferredMode = mode
        defaults.set(mode.rawValue, forKey: Self.preferredModeStorageKey)
    }

    static func logModeChangeError(_ error: Error, context: String) {
        if let modeError = error as? FunctionKeyModeManagerError,
            case .cannotSetParameter(let code) = modeError,
            code == kIOReturnNotPermitted
        {
            // The event-system write can take effect even when the subsequent registry write is denied.
            logger.debug(
                "\(context, privacy: .public): IOKit returned kIOReturnNotPermitted; runtime mode may still have changed"
            )
        } else {
            logger.error("\(context, privacy: .public) failed: \(String(describing: error), privacy: .public)")
        }
    }

    static func applyTerminationMode(defaults: UserDefaults = .standard) throws {
        let mode =
            FunctionKeyMode(
                rawValue: defaults.integer(forKey: terminationModeStorageKey)
            ) ?? .mediaControls

        logger.info("Termination: applying configured mode=\(mode.rawValue)")
        try setCurrentMode(mode)
    }

    static func setCurrentMode(_ mode: FunctionKeyMode) throws {
        let requestID = UUID().uuidString
        logger.info("[\(requestID, privacy: .public)] IOKit write requested: mode=\(mode.rawValue)")
        let connect = try serviceConnection()
        defer { IOServiceClose(connect) }

        logModeReadback(connection: connect, phase: "before", requestID: requestID)

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

        logger.info(
            "[\(requestID, privacy: .public)] IOHIDSetCFTypeParameter returned \(result) (\(hexCode(result), privacy: .public)), requested=\(mode.rawValue)"
        )
        logModeReadback(connection: connect, phase: "after", requestID: requestID)

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

    // Read both sources for diagnostics without changing how write results are handled.
    private static func logModeReadback(connection: io_connect_t, phase: String, requestID: String) {
        var parameter: Unmanaged<CFTypeRef>?
        let result = IOHIDCopyCFTypeParameter(connection, kIOHIDFKeyModeKey as CFString, &parameter)
        let parameterMode = (parameter?.takeRetainedValue() as? NSNumber).map { String($0.intValue) } ?? "unavailable"
        logger.info(
            "[\(requestID, privacy: .public)] \(phase, privacy: .public) write: HID parameter readback (registry-first)=\(parameterMode, privacy: .public), result=\(result) (\(hexCode(result), privacy: .public))"
        )

        do {
            let registryMode = try currentMode()
            logger.info(
                "[\(requestID, privacy: .public)] \(phase, privacy: .public) write: registry mode=\(registryMode.rawValue)"
            )
        } catch {
            logger.info(
                "[\(requestID, privacy: .public)] \(phase, privacy: .public) write: registry read failed: \(String(describing: error), privacy: .public)"
            )
        }
    }

    private static func hexCode(_ code: kern_return_t) -> String {
        String(format: "0x%08X", UInt32(bitPattern: code))
    }

    private static func ioRegistryEntry() throws -> io_registry_entry_t {
        var mainPort: mach_port_t = .zero

        let kr = IOMainPort(mach_port_t(MACH_PORT_NULL), &mainPort)

        guard kr == KERN_SUCCESS else {
            logger.error("IOMainPort failed: \(kr) (\(hexCode(kr), privacy: .public))")
            throw FunctionKeyModeManagerError.cannotCreateMainPort(kr)
        }

        let entry = IORegistryEntryFromPath(
            mainPort,
            "IOService:/IOResources/IOHIDSystem"
        )

        guard entry != IO_OBJECT_NULL else {
            logger.error("IORegistryEntryFromPath failed: IOHIDSystem not found")
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
            logger.error("IOServiceOpen failed: \(kr) (\(hexCode(kr), privacy: .public))")
            throw FunctionKeyModeManagerError.cannotOpenService(kr)
        }

        return connection
    }
}
