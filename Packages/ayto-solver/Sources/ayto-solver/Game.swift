import Foundation

public struct Game {
    
    public let persons: [Person]
    public let knownMatches: [Match]
    public let matchingNights: [MatchingNight]
    
    public init(persons: [Person], knownMatches: [Match], nights: [MatchingNight]) {
        self.persons = persons
        self.knownMatches = knownMatches
        self.matchingNights = nights
    }
    
    public func solve() -> Solution {
        
        var knownMatches = self.knownMatches
        
        var didDeduceSomething: Bool = false
        repeat {
            didDeduceSomething = false
            for night in self.matchingNights {
                let deducedMatches = night.deducedMatches(by: knownMatches)
                if deducedMatches.count > knownMatches.count {
                    didDeduceSomething = true
                }
                knownMatches = deducedMatches
            }
        } while didDeduceSomething
        
        return Game.Solution(matches: knownMatches.filter { $0.isMatch })
    }
}

public extension Game {
    
    struct Solution {
        public let matches: [Match]
    }
    
}
