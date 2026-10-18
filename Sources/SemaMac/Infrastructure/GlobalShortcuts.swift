// Enregistre uniquement les deux combinaisons globales choisies et préserve les réglages en cas de conflit.
import AppKit
import Carbon
import MarketCore

@MainActor
final class GlobalShortcuts {
    private var handler: EventHandlerRef?
    private var registrations: [ShortcutAction: (shortcut: AppShortcut, reference: EventHotKeyRef)] = [:]
    var perform: (ShortcutAction) -> Void = { _ in }
    private static let signature: OSType = 0x73656D61

    enum RegistrationError: Error, LocalizedError {
        case invalid, duplicate, reserved, unavailable, handler
        var errorDescription: String? {
            switch self {
            case .invalid: "Ajoutez ⌃, ⌥ ou ⌘ à votre raccourci."
            case .duplicate: "Ce raccourci est déjà utilisé dans sema."
            case .reserved: "Ce raccourci est déjà utilisé par sema ou macOS."
            case .unavailable: "Ce raccourci est réservé par macOS ou une autre app. Choisissez une autre combinaison."
            case .handler: "Les raccourcis globaux ne sont pas disponibles pour cette session."
            }
        }
    }

    func apply(_ preferences: ShortcutPreferences) throws {
        let actions = ShortcutAction.allCases
        let shortcuts = actions.compactMap { preferences[$0] }
        guard shortcuts.allSatisfy(\.isValid) else { throw RegistrationError.invalid }
        if let first = preferences.ribbon, let second = preferences.workspace, first.matches(second) {
            throw RegistrationError.duplicate
        }
        for shortcut in shortcuts where isReserved(shortcut) { throw RegistrationError.reserved }
        try installHandler()

        // Acquire replacements before removing previous keys. A failed registration leaves them intact.
        var acquired: [ShortcutAction: (shortcut: AppShortcut, reference: EventHotKeyRef)] = [:]
        do {
            for (index, action) in actions.enumerated() {
                guard let shortcut = preferences[action], registrations[action]?.shortcut.matches(shortcut) != true else { continue }
                var reference: EventHotKeyRef?
                let status = RegisterEventHotKey(UInt32(shortcut.keyCode), shortcut.modifiers.carbon,
                    EventHotKeyID(signature: Self.signature, id: UInt32(index + 1)),
                    GetApplicationEventTarget(), OptionBits(kEventHotKeyExclusive), &reference)
                guard status == noErr, let reference else { throw RegistrationError.unavailable }
                acquired[action] = (shortcut, reference)
            }
        } catch {
            for value in acquired.values { UnregisterEventHotKey(value.reference) }
            throw error
        }
        for action in actions {
            if let previous = registrations[action], preferences[action]?.matches(previous.shortcut) != true {
                UnregisterEventHotKey(previous.reference); registrations[action] = nil
            }
            if let replacement = acquired[action] { registrations[action] = replacement }
        }
    }

    func suspend() {
        for registration in registrations.values { UnregisterEventHotKey(registration.reference) }
        registrations.removeAll()
    }

    func tearDown() {
        suspend()
        if let handler { RemoveEventHandler(handler) }; handler = nil
    }

    private func installHandler() throws {
        guard handler == nil else { return }
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            var key = EventHotKeyID()
            guard GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                nil, MemoryLayout<EventHotKeyID>.size, nil, &key) == noErr,
                key.signature == GlobalShortcuts.signature else { return OSStatus(eventNotHandledErr) }
            let controller = Unmanaged<GlobalShortcuts>.fromOpaque(context).takeUnretainedValue()
            let id = key.id
            // End the Carbon callback before opening a SwiftUI window or changing the key panel.
            Task { @MainActor in
                let actions = ShortcutAction.allCases
                if id > 0, id <= actions.count { controller.perform(actions[Int(id) - 1]) }
            }
            return noErr
        }, 1, &type, Unmanaged.passUnretained(self).toOpaque(), &handler)
        guard status == noErr else { throw RegistrationError.handler }
    }

    private func isReserved(_ shortcut: AppShortcut) -> Bool {
        if shortcut.modifiers == .command, [kVK_UpArrow, kVK_DownArrow, kVK_LeftArrow, kVK_RightArrow].contains(Int(shortcut.keyCode)) { return true }
        if isReserved(in: NSApplication.shared.mainMenu, shortcut: shortcut) { return true }
        var symbolicKeys: Unmanaged<CFArray>?
        if CopySymbolicHotKeys(&symbolicKeys) == noErr,
           let keys = symbolicKeys?.takeRetainedValue() as? [[String: Any]] {
            return keys.contains { key in
                (key[kHISymbolicHotKeyEnabled] as? Bool) == true
                    && (key[kHISymbolicHotKeyCode] as? NSNumber)?.uint16Value == shortcut.keyCode
                    && (key[kHISymbolicHotKeyModifiers] as? NSNumber)?.uint32Value == shortcut.modifiers.carbon
            }
        }
        return false
    }

    private func isReserved(in menu: NSMenu?, shortcut: AppShortcut) -> Bool {
        guard let menu else { return false }
        let equivalent: String
        switch Int(shortcut.keyCode) {
        case kVK_UpArrow: equivalent = String(UnicodeScalar(NSUpArrowFunctionKey)!)
        case kVK_DownArrow: equivalent = String(UnicodeScalar(NSDownArrowFunctionKey)!)
        case kVK_LeftArrow: equivalent = String(UnicodeScalar(NSLeftArrowFunctionKey)!)
        case kVK_RightArrow: equivalent = String(UnicodeScalar(NSRightArrowFunctionKey)!)
        case kVK_Space: equivalent = " "
        case kVK_Return: equivalent = "\r"
        case kVK_Tab: equivalent = "\t"
        default: equivalent = shortcut.key.lowercased()
        }
        return menu.items.contains { item in
            (!item.keyEquivalent.isEmpty && item.keyEquivalent.lowercased() == equivalent
                && AppShortcut.Modifiers(item.keyEquivalentModifierMask) == shortcut.modifiers)
                || isReserved(in: item.submenu, shortcut: shortcut)
        }
    }
}

extension AppShortcut.Modifiers {
    init(_ flags: NSEvent.ModifierFlags) {
        self = []
        if flags.contains(.control) { insert(.control) }
        if flags.contains(.option) { insert(.option) }
        if flags.contains(.shift) { insert(.shift) }
        if flags.contains(.command) { insert(.command) }
    }

    fileprivate var carbon: UInt32 {
        var result: UInt32 = 0
        if contains(.control) { result |= UInt32(controlKey) }
        if contains(.option) { result |= UInt32(optionKey) }
        if contains(.shift) { result |= UInt32(shiftKey) }
        if contains(.command) { result |= UInt32(cmdKey) }
        return result
    }

    var symbols: String {
        (contains(.control) ? "⌃" : "") + (contains(.option) ? "⌥" : "")
            + (contains(.shift) ? "⇧" : "") + (contains(.command) ? "⌘" : "")
    }
}
