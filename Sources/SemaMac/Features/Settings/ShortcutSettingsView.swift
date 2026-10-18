// Présente les deux accès globaux modifiables et rappelle la navigation clavier du hub.
import AppKit
import Carbon
import SwiftUI
import MarketCore

struct ShortcutSettingsView: View {
    private static let rowSpacing: CGFloat = 14
    private static let recorderWidth: CGFloat = 142
    private static let recorderHeight: CGFloat = 30
    @Environment(AppStore.self) private var store

    var body: some View {
        Form {
            Section("Accès globaux") {
                shortcutRow(.ribbon, title: "Bandeau")
                shortcutRow(.workspace, title: "Hub")
                if let error = store.shortcutError {
                    Text(error).font(.callout).foregroundStyle(.red)
                        .accessibilityLabel("Raccourci indisponible : " + error)
                }
            }
            Section("Navigation") {
                LabeledContent("Repère précédent / suivant", value: "↑ ↓  ← →")
                LabeledContent("Choisir à vue", value: "⌘ ↑ ↓  ← →")
                LabeledContent("Rechercher", value: "⌘ K")
                LabeledContent("Réglages", value: "⌘ ,")
            }
        }
        .formStyle(.grouped)
    }

    private func shortcutRow(_ action: ShortcutAction, title: String) -> some View {
        HStack(spacing: Self.rowSpacing) {
            Text(title)
            Spacer()
            Button { store.setShortcut(ShortcutPreferences.standard[action], for: action) } label: {
                Image(systemName: "arrow.counterclockwise").font(.subheadline)
            }
            .buttonStyle(.borderless).help("Rétablir le raccourci du " + title.lowercased())
            .accessibilityLabel("Rétablir le raccourci du " + title.lowercased())
            .disabled(store.shortcuts[action] == ShortcutPreferences.standard[action])
            ShortcutRecorder(shortcut: store.shortcuts[action], title: title,
                begin: { store.shortcutError = nil; store.globalShortcuts.suspend() },
                finish: { store.activateShortcuts() },
                save: { store.setShortcut($0, for: action) })
                .frame(width: Self.recorderWidth, height: Self.recorderHeight)
        }.padding(.vertical, SemaTheme.settingsRowPadding)
    }
}

private struct ShortcutRecorder: NSViewRepresentable {
    private static let fontSize: CGFloat = 12
    let shortcut: AppShortcut?
    let title: String
    let begin: () -> Void
    let finish: () -> Void
    let save: (AppShortcut?) -> Void

    func makeNSView(context: Context) -> ShortcutButton {
        let button = ShortcutButton()
        button.bezelStyle = .rounded; button.font = .systemFont(ofSize: Self.fontSize, weight: .medium)
        return button
    }

    func updateNSView(_ button: ShortcutButton, context: Context) {
        button.begin = begin; button.finish = finish; button.save = save
        button.shortcut = shortcut
        button.setAccessibilityLabel("Raccourci du " + title.lowercased())
        button.toolTip = "Cliquez puis pressez une combinaison. Effacement retire le raccourci ; Échap annule."
        button.refreshTitle()
    }

    static func dismantleNSView(_ button: ShortcutButton, coordinator: ()) { button.stopRecording() }

    @MainActor final class ShortcutButton: NSButton {
        var shortcut: AppShortcut?
        var begin: () -> Void = {}
        var finish: () -> Void = {}
        var save: (AppShortcut?) -> Void = { _ in }
        private var isRecording = false
        private var keyMonitor: Any?
        override var acceptsFirstResponder: Bool { true }

        override func mouseDown(with event: NSEvent) { startRecording() }

        override func keyDown(with event: NSEvent) {
            guard isRecording else {
                if [kVK_Space, kVK_Return].contains(Int(event.keyCode)) { startRecording() }
                else { super.keyDown(with: event) }
                return
            }
            if Int(event.keyCode) == kVK_Escape { stopRecording(); return }
            if Int(event.keyCode) == kVK_Tab, event.modifierFlags.intersection([.command, .control, .option]).isEmpty {
                stopRecording()
                if event.modifierFlags.contains(.shift) { window?.selectPreviousKeyView(self) }
                else { window?.selectNextKeyView(self) }
                return
            }
            if [kVK_Delete, kVK_ForwardDelete].contains(Int(event.keyCode)), event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty {
                complete(nil); return
            }
            let labels: [Int: String] = [kVK_Return: "↩", kVK_Tab: "⇥", kVK_Space: "espace", kVK_Delete: "⌫",
                kVK_Escape: "⎋", kVK_ANSI_KeypadEnter: "⌤", kVK_Home: "↖", kVK_PageUp: "⇞", kVK_ForwardDelete: "⌦",
                kVK_End: "↘", kVK_PageDown: "⇟", kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_DownArrow: "↓", kVK_UpArrow: "↑"]
            let key = labels[Int(event.keyCode)] ?? event.charactersIgnoringModifiers?.uppercased() ?? ""
            let candidate = AppShortcut(keyCode: event.keyCode, modifiers: AppShortcut.Modifiers(event.modifierFlags), key: key)
            guard candidate.isValid else { NSSound.beep(); return }
            complete(candidate)
        }

        override func resignFirstResponder() -> Bool { stopRecording(); return super.resignFirstResponder() }
        override func viewWillMove(toWindow newWindow: NSWindow?) {
            NotificationCenter.default.removeObserver(self, name: NSWindow.didResignKeyNotification, object: window)
            if newWindow == nil { stopRecording() }
            super.viewWillMove(toWindow: newWindow)
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window {
                NotificationCenter.default.addObserver(self, selector: #selector(windowResigned),
                    name: NSWindow.didResignKeyNotification, object: window)
            }
        }

        @objc private func windowResigned() { stopRecording() }

        override func accessibilityPerformPress() -> Bool { startRecording(); return true }

        func refreshTitle() {
            title = isRecording ? "Votre raccourci…" : shortcut.map { $0.modifiers.symbols + " " + $0.key } ?? "Enregistrer…"
            setAccessibilityValue(title)
        }

        private func startRecording() {
            guard !isRecording else { return }
            window?.makeFirstResponder(self)
            isRecording = true; begin(); refreshTitle()
            // Capture before menu key equivalents, only while this field records in its own window.
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown]) { [weak self] event in
                let consumed = MainActor.assumeIsolated {
                    guard let self, self.isRecording, event.window === self.window,
                          self.window?.isKeyWindow == true else { return false }
                    if event.type == .leftMouseDown {
                        if !self.bounds.contains(self.convert(event.locationInWindow, from: nil)) { self.stopRecording() }
                        return false
                    }
                    self.keyDown(with: event)
                    return true
                }
                return consumed ? nil : event
            }
        }

        private func complete(_ shortcut: AppShortcut?) {
            isRecording = false
            removeKeyMonitor()
            save(shortcut)
            // Save restores registrations on success or failure, without clearing a conflict message.
            refreshTitle()
        }

        func stopRecording() {
            guard isRecording else { return }
            isRecording = false; removeKeyMonitor(); finish(); refreshTitle()
        }

        private func removeKeyMonitor() {
            if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }; keyMonitor = nil
        }
    }
}
