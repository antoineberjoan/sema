// Vérifie le déplacement des repères suivis et le regroupement des équivalents.
import Foundation
import Testing
@testable import MarketCore

struct FollowedOrderTests {
    private func item(_ id: String) -> MarketSeries {
        MarketSeries(id: id, name: id, subtitle: "", category: .markets, unit: .percent, source: "Test", observations: [])
    }

    private var three: [MarketSeries] { ["a", "b", "c"].map(item) }

    @Test func movingByOneSwapsNeighboursAndRefusesTheEdges() {
        #expect(FollowedOrder.moving(three, id: "a", by: 1)?.map(\.id) == ["b", "a", "c"])
        #expect(FollowedOrder.moving(three, id: "a", by: -1) == nil)
        #expect(FollowedOrder.moving(three, id: "z", by: 1) == nil)
    }

    @Test func movingAGroupFollowsTheSwiftUIDestinationConvention() {
        #expect(FollowedOrder.moving(three, from: [0], to: 3)?.map(\.id) == ["b", "c", "a"])
        #expect(FollowedOrder.moving(three, from: [2], to: 0)?.map(\.id) == ["c", "a", "b"])
        #expect(FollowedOrder.moving(three, from: [5], to: 0) == nil)
    }

    @Test func idsKeepUnknownIdentifiersAtTheEnd() {
        let ids = FollowedOrder.ids(ordered: [item("b"), item("a")], stored: three, followedIDs: ["a", "b", "c", "gone"])
        #expect(ids == ["b", "a", "c", "gone"])
    }

    @Test func equivalentIDsAreEmptyWithoutAnItem() {
        #expect(FollowedOrder.equivalentIDs(of: nil, among: three).isEmpty)
        #expect(FollowedOrder.equivalentIDs(of: item("b"), among: three) == ["b"])
    }
}
