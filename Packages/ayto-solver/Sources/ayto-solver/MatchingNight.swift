import Foundation
import Logging

public struct MatchingNight {
    
    public let pairs: [Pair]
    public let hits: Int
    
    public init(pairs: [Pair], hits: Int) {
        self.pairs = pairs
        self.hits = hits
    }
    
    public func deducedMatches(by knownMatches: [Match], logger: Logger? = nil) -> [Match] {
        logger?.debug("Deducing from matching night", metadata: ["hits": "\(self.hits)", "matches": "\(knownMatches.count)"])
        var matches = knownMatches
        
        var impossibleMatches: [Match] = []
        var safeMatches: [Match] = []
        
        for pair in pairs {
            if pair.isImpossible(by: knownMatches) {
                impossibleMatches.append(Match.noMatch(pair.person1, pair.person2))
                logger?.debug("Creating no match since it is impossible", metadata: ["person1": "\(pair.person1.name)", "person2": "\(pair.person2.name)"])
            } else if pair.isMatch(by: knownMatches) {
                safeMatches.append(Match.match(pair.person1, pair.person2))
            }
        }
        
        if safeMatches.count < hits, impossibleMatches.count + hits == pairs.count {
            // all not impossible matches must be hits
            let newHitPairs = pairs.filter { !impossibleMatches.map({ $0.pair }) .contains($0) }
            for pair in newHitPairs {
                logger?.info("Pair must be a hit to meet matching nights hits", metadata: ["person1": "\(pair.person1.name)", "person2": "\(pair.person2.name)"])
                safeMatches.append(Match.match(pair.person1, pair.person2))
            }
        }
        
        matches = Array(Set(knownMatches + impossibleMatches + safeMatches))
        return matches
    }
}
