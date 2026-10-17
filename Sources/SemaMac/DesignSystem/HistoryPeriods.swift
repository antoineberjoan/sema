// Partage les cinq horizons de consultation visibles entre Focus et le bandeau.
import MarketCore

enum HistoryPeriods {
    static let visible: [HistoryPeriod] = [.quarter, .year, .threeYears, .fiveYears, .all]
}
