// Limite les flèches de Focus à sa fenêtre, hors saisie, contrôles natifs et feuilles.
import AppKit
import SwiftUI

struct FocusKeyboard: NSViewRepresentable {
    let handle: (NSEvent) -> Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.view = view
        context.coordinator.handle = handle
        context.coordinator.install()
        return view
    }

    func updateNSView(_ view: NSView, context: Context) { context.coordinator.handle = handle }
    static func dismantleNSView(_ view: NSView, coordinator: Coordinator) { coordinator.tearDown() }

    @MainActor final class Coordinator {
        weak var view: NSView?
        var handle: (NSEvent) -> Bool = { _ in false }
        private var monitor: Any?

        func install() {
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
                let consumed = MainActor.assumeIsolated {
                    guard let self, let window = self.view?.window,
                          NSApplication.shared.keyWindow === window, event.window === window,
                          window.attachedSheet == nil, NSApplication.shared.modalWindow == nil else { return false }
                    let responder = window.firstResponder
                    let editsControl = responder is NSControl && !(responder is NSTableView) && !(responder is NSButton)
                    guard !(responder is NSTextView), !editsControl else { return false }
                    return self.handle(event)
                }
                return consumed ? nil : event
            }
        }

        func tearDown() {
            if let monitor { NSEvent.removeMonitor(monitor) }; monitor = nil
        }
    }
}
