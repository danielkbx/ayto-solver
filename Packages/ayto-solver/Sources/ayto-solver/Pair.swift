import Foundation

public struct Pair {
    public let person1: Person
    public let person2: Person
    
    public init(_ person1: Person, _ person2: Person) {
        self.person1 = person1
        self.person2 = person2
    }
    
    public func contains(_ person: Person) -> Bool {
        self.person1 == person || self.person2 == person
    }
    
    public func isImpossible(by match: Match) -> Bool {
        if match.isMatch {
            return match.pair.contains(person1) && !match.pair.contains(person2)
                || match.pair.contains(person2) && !match.pair.contains(person1)
        } else {
            return !(!match.pair.contains(person1) && !match.pair.contains(person2))
        }
    }
    
    public func isImpossible(by matches: [Match]) -> Bool {
        for match in matches {
            if isImpossible(by: match) {
                return true
            }
        }
        
        return false
    }
    
    public func isMatch(by match: Match) -> Bool {
        if match.isMatch {
            return match.pair.contains(person1) && match.pair.contains(person2)
        } else {
            return false
        }
    }
    
    public func isMatch(by matches: [Match]) -> Bool {
        for match in matches {
            if isMatch(by: match) {
                return true
            }
        }
        
        return false
    }
}
