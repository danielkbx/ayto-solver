import Foundation
import Logging

public struct MatchingNight {
    
    enum DeduceError: Error {
        case matchesExceedHits
        case noMatchesExceedNoHits
        case personInMultipePairs(person: Person)
    }
    
    public let title: String
    public let pairs: [Pair]
    public let hits: Int
    
    public init(title: String, pairs: [Pair], hits: Int) {
        self.title = title
        self.pairs = pairs
        self.hits = hits
    }
    
    public var persons: [Person] {
        pairs.reduce([]) { result, pair in result + [pair.person1, pair.person2] }
    }
            
    internal func deducedMatches(by knownMatches: [Match], logger: Logger? = nil) throws -> [Match] {
        logger?.debug("Deducing from matching night", metadata: ["hits": "\(self.hits)", "matches": "\(knownMatches.count)"])
        
        for person in persons {
            if pairs.filter({ $0.contains(person )}).count > 1 {
                throw DeduceError.personInMultipePairs(person: person)
            }
        }
        
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
        
        if safeMatches.count > hits {
            throw DeduceError.matchesExceedHits
        } else if safeMatches.count == hits {
            // all other pairs must be fails
            for pair in pairs {
                if safeMatches.matches(with: pair.person1, and: pair.person2).first == nil {
                    impossibleMatches.append(Match.noMatch(pair.person1, pair.person2))
                }
            }
        } else if safeMatches.count < hits, impossibleMatches.count + hits == pairs.count {
            // all not impossible matches must be hits
            let newHitPairs = pairs.filter { !impossibleMatches.map({ $0.pair }) .contains($0) }
            for pair in newHitPairs {
                logger?.debug("Pair must be a hit to meet matching nights hits", metadata: ["person1": "\(pair.person1.name)", "person2": "\(pair.person2.name)"])
                safeMatches.append(Match.match(pair.person1, pair.person2))
            }
        }
        
        
        let allMatches = try (knownMatches + impossibleMatches + safeMatches).unique()
        
        // check if there are more nomatches than allowed
        let noMatches = relevantMatches(of: allMatches).filter { !$0.isMatch }
        if hits + noMatches.count > pairs.count {
            throw DeduceError.noMatchesExceedNoHits
        }
        
        return allMatches
    }
    
    public func relevantMatches(of knownMatches: [Match]) -> [Match] {
        knownMatches.filter { pairs.contains($0.pair) }        
    }
    
    
}
