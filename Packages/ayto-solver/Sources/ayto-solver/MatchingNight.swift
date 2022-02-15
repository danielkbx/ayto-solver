import Foundation
import Logging
import Algorithms

/// Contains the pairs and the number of correct matches of a matching night.
public struct MatchingNight: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        (["\(self.title), \(self.hits) hits"] + pairs.map({"\($0.person1.name) + \($0.person2.name)"})).joined(separator: ", ")
    }
    
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
    
    /// Returns the persons involved in the matching night.
    public var persons: [Person] {
        pairs.reduce([]) { result, pair in result + [pair.person1, pair.person2] }
    }        
          
    /// Creates match instanced by applying the number of known matches to the actual information about known matches.
    ///
    /// For example, if one match must be found in the matching night and 9 pairs are known not to be match, the left-over pair must be a match.
    internal func deducedMatches(by knownMatches: [Match], logger: Logger? = nil) throws -> [Match] {
        logger?.debug("Deducing from matching night \"\(self.title)\"", metadata: ["hits": "\(self.hits)", "matches": "\(knownMatches.count)"])
        
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
            impossibleMatches = try impossibleMatches.unique()
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
        let noMatchesWithoutExtraPersons = noMatches.filter({ $0.pair.person1.role != .extra && $0.pair.person2.role != .extra })
        if hits + noMatchesWithoutExtraPersons.count > pairs.count {
            throw DeduceError.noMatchesExceedNoHits
        }
                        
        return allMatches
    }
    
    /// Returns all matches of the given list that are paired in the matching night.
    public func relevantMatches(of knownMatches: [Match]) -> [Match] {
        knownMatches.filter { pairs.contains($0.pair) }        
    }
    
    
}
