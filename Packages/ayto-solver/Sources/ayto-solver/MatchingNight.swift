import Foundation

public struct MatchingNight {
    
    public let pairs: [Pair]
    public let hits: Int
    
    public init(pairs: [Pair], hits: Int) {
        self.pairs = pairs
        self.hits = hits
    }
    
    public func deducedMatches(by knownMatches: [Match]) -> [Match] {
        return knownMatches
    }
}
