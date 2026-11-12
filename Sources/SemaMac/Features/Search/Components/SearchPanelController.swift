// Ouvre et ferme le panneau de recherche rapide, centré dans le haut de l’écran sous le pointeur, depuis n’importe quelle app.
import AppKit
import Carbon
import SemaDesign
import SwiftUI

@MainActor
final class SearchPanelController {
    private let store: AppStore
    private let openWorkspace: () -> Void
    private let model = SearchPanelModel()
    private var isPresented = false
    private var transition = UUID()
    private lazy var hostedContent = NSHostingView(rootView: content())
    private lazy var panel: FloatingPanel = {
        let panel = FloatingPanel.make(title: "Recherche · sema", identifier: "sema-search-panel")
        panel.contentView = hostedContent
        return panel
    }()
    /// Escape first leaves the detail of a series, then closes the panel.
    private lazy var dismissal = PanelDismissal(panel: panel, dismiss: { [weak self] in self?.dismiss() },
        handleKey: { [weak self] event in
            guard let self, Int(event.keyCode) == kVK_Escape, self.model.detail != nil else { return false }
            self.model.detail = nil
            return true
        })

    init(store: AppStore, openWorkspace: @escaping () -> Void) {
        self.store = store; self.openWorkspace = openWorkspace
    }

    private func content() -> AnyView {
        AnyView(SearchScreen(model: model,
            openInHub: { [weak self] series in
                guard let self else { return }
                self.dismiss(); self.store.show(series); self.store.section = .overview; self.openWorkspace()
            },
            openCatalogues: { [weak self] query in
                guard let self else { return }
                self.dismiss(); self.store.catalogueSeed = query; self.store.isSearchPresented = true; self.openWorkspace()
            }).modifier(RibbonEnvironment(store: store)).id(transition))
    }

    func toggle() {
        if isPresented { dismiss(); return }
        guard !store.isOnboardingPresented,
              let screen = FloatingPanel.screenUnderPointer ?? NSScreen.main else { return }
        model.detail = nil
        transition = UUID(); isPresented = true
        hostedContent.rootView = content()
        let size = SearchScreen.size
        let visible = screen.visibleFrame
        let target = NSRect(x: visible.midX - size.width / 2,
                            y: visible.maxY - visible.height * CGFloat(DesignMeasure.searchPanelControllerTopInset) - size.height, width: size.width, height: size.height)
        panel.setFrame(target, display: false)
        panel.alphaValue = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 1 : 0
        panel.makeKeyAndOrderFront(nil)
        dismissal.start()
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = DesignDuration.standard
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }

    func dismiss() {
        guard isPresented else { return }
        isPresented = false; transition = UUID()
        let generation = transition
        dismissal.stop()
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            panel.orderOut(nil)
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = DesignDuration.standard * DesignMotion.exitRatio
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            Task { @MainActor in
                guard let self, self.transition == generation, !self.isPresented else { return }
                self.panel.orderOut(nil)
            }
        }
    }

    func tearDown() {
        transition = UUID(); isPresented = false
        dismissal.stop()
        panel.orderOut(nil)
    }
}
