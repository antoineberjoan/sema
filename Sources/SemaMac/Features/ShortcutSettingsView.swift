// Présente les deux accès globaux modifiables et rappelle la navigation clavier de Focus.
import AppKit
import SwiftUI
import MarketCore

struct ShortcutSettingsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Form {
            Section("Depuis n’importe quelle app") {
                shortcutRow(.ribbon, title: "Bandeau", subtitle: "Afficher ou masquer vos favoris.")
                shortcutRow(.workspace, title: "Hub", subtitle: "Ouvrir votre repère dans Focus.")
                if let error = store.shortcutError {
                    Text(error).font(.system(size: 12)).foregroundStyle(.red)
                        .accessibilityLabel("Raccourci indisponible : " + error)
                }
            }
            Section("Dans Focus") {
                LabeledContent("Repère précédent ou suivant", value: "↑  ↓")
                LabeledContent("Choisir à vue", value: "⌘ ↑  ⌘ ↓")
                Text("Maintenez ⌘ pour parcourir, relâchez pour ouvrir. Entrée valide aussi ; Échap annule.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                LabeledContent("Rechercher", value: "⌘ K")
                LabeledContent("Réglages", value: "⌘ ,")
            }
        }
        .formStyle(.grouped)
    }

    private func shortcutRow(_ action: ShortcutAction, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            Button { store.setShortcut(ShortcutPreferences.standard[action], for: action) } label: {
                Image(systemName: "arrow.counterclockwise").font(.system(size: 11))
            }
            .buttonStyle(.borderless).help("Rétablir le raccourci du " + title.lowercased())
            .accessibilityLabel("Rétablir le raccourci du " + title.lowercased())
            .disabled(store.shortcuts[action] == ShortcutPreferences.standard[action])
            ShortcutRecorder(shortcut: store.shortcuts[action], title: title,
                begin: { store.shortcutError = nil; store.globalShortcuts.suspend() },
                finish: { store.activateShortcuts() },
                save: { store.setShortcut($0, for: action) })
                .frame(width: 142, height: 30)
        }.padding(.vertical, 5)
    }
}

private struct ShortcutRecorder: NSViewRepresentable {
    let shortcut: AppShortcut?
    let title: String
    let begin: () -> Void
    let finish: () -> Void
    let save: (AppShortcut?) -> Void

    func makeNSView(context: Context) -> ShortcutButton {
        let button = ShortcutButton()
        button.bezelStyle = .rounded; button.font = .systemFont(ofSize: 12, weight: .medium)
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
                if event.keyCode == 49 || event.keyCode == 36 { startRecording() }
                else { super.keyDown(with: event) }
                return
            }
            if event.keyCode == 53 { stopRecording(); return }
            if event.keyCode == 48, event.modifierFlags.intersection([.command, .control, .option]).isEmpty {
                stopRecording(); super.keyDown(with: event); return
            }
            if [51, 117].contains(event.keyCode), event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty {
                complete(nil); return
            }
            let labels: [UInt16: String] = [36: "↩", 48: "⇥", 49: "espace", 51: "⌫", 53: "⎋", 76: "⌤",
                115: "↖", 116: "⇞", 117: "⌦", 119: "↘", 121: "⇟", 123: "←", 124: "→", 125: "↓", 126: "↑"]
            let key = labels[event.keyCode] ?? event.charactersIgnoringModifiers?.uppercased() ?? ""
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
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                let consumed = MainActor.assumeIsolated {
                    guard let self, self.isRecording, event.window === self.window,
                          self.window?.isKeyWindow == true else { return false }
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
