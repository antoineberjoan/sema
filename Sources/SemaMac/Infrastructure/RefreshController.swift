// Planifie l’actualisation quotidienne pendant la vie de l’app, même sans fenêtre ouverte.
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

    private func check() {
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
                RefreshPolicy.isDue(syncedAt: $0.syncedAt, now: now)
            }.map(\.id))
            if !due.isEmpty { await store.refreshSeries(only: due) }
            task = nil
            // Une série en erreur garde son cache ; le prochain essai automatique est le lendemain.
            let completedAt = Date.now
            let dates = store.automaticRefreshSeries.map { item in
                RefreshPolicy.isDue(syncedAt: item.syncedAt, now: completedAt) ? completedAt : item.syncedAt
            }
            schedule(after: RefreshPolicy.nextDelay(syncedDates: dates, now: completedAt))
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
