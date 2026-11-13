// Planifie l’actualisation quotidienne, après chaque clôture pour les repères surveillés, et le brief du matin, même sans fenêtre ouverte.
import AppKit
import MarketCore

@MainActor
final class RefreshController {
    private static let busyDelay: TimeInterval = 60
    private let store: AppStore
    private var timer: Timer?
    private var task: Task<Void, Never>?
    private var observers: [NSObjectProtocol] = []
    private var isSleeping = false
    private var isStarted = false

    init(store: AppStore) { self.store = store }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.sleep() }
        })
        observers.append(center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.wake() }
        })
        check()
    }

    private func sleep() {
        isSleeping = true
        timer?.invalidate(); timer = nil
    }

    private func wake() {
        isSleeping = false
        check()
    }

    /// Appelé aussi quand les réglages du brief changent, pour qu’une nouvelle heure compte sans attendre la prochaine actualisation.
    func check() {
        guard isStarted, !isSleeping, task == nil else { return }
        timer?.invalidate(); timer = nil
        task = Task { [weak self] in
            guard let self else { return }
            await store.checkWebstatKey()
            guard !Task.isCancelled else { task = nil; return }
            if store.isLoading {
                task = nil
                schedule(after: Self.busyDelay)
                return
            }
            let now = Date.now
            let due = Set(store.automaticRefreshSeries.filter {
                RefreshPolicy.isDue(syncedAt: $0.syncedAt, now: now, followsCloses: store.followsCloses($0))
            }.map(\.id))
            if !due.isEmpty { await store.refreshSeries(only: due) }
            // Après l’actualisation, pour que le brief lise la dernière séance.
            await store.sendBriefIfDue()
            task = nil
            // Une série en erreur garde son cache ; le prochain essai automatique est le lendemain.
            let completedAt = Date.now
            let series = store.automaticRefreshSeries
            let dates = series.map { item in
                RefreshPolicy.isDue(syncedAt: item.syncedAt, now: completedAt) ? completedAt : item.syncedAt
            }
            let refreshDelay = RefreshPolicy.nextDelay(syncedDates: dates, now: completedAt,
                                                       followsCloses: series.contains(where: store.followsCloses))
            schedule(after: min(refreshDelay, store.nextBriefDelay(now: completedAt) ?? refreshDelay))
        }
    }

    private func schedule(after delay: TimeInterval) {
        guard isStarted, !isSleeping else { return }
        timer?.invalidate()
        let timer = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.check() }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func stop() {
        isStarted = false
        timer?.invalidate(); timer = nil
        task?.cancel(); task = nil
        let center = NSWorkspace.shared.notificationCenter
        observers.forEach { center.removeObserver($0) }; observers = []
    }
}
