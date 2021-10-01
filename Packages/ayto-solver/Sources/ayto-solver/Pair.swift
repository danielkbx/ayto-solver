import Foundation

public struct Pair: Equatable, Hashable {        
    public enum ContainmentError: Error {
        case doesNotContain(person: Person)
    }
    
    public let person1: Person
    public let person2: Person
    public var persons: [Person] { [person1, person2] }
    
    public init(_ person1: Person, _ person2: Person) {
        guard person1.gender != person2.gender else { fatalError() }
        self.person1 = person1.gender == .female ? person1 : person2
        self.person2 = person2.gender == .male ? person2 : person1
    }
    
    public func person(with gender: Person.Gender) -> Person {
        return [self.person1, self.person2].first(where: { $0.gender == gender })!
    }
    
    public func contains(_ person: Person) -> Bool {
        self.person1 == person || self.person2 == person
    }
    
    public func not(person: Person) throws -> Person {
        guard self.contains(person) else {
            throw ContainmentError.doesNotContain(person: person)
        }
        
        return (self.person1 == person) ? person2 : person1
    }
    
    public func isImpossible(by match: Match) -> Bool {
        if !match.contains(person1) && !match.contains(person2) {
            return false
        }
        
        if match.isMatch {            
            return match.pair.contains(person1) && !match.pair.contains(person2)
                || match.pair.contains(person2) && !match.pair.contains(person1)
        } else {
            return match.pair.contains(person1) && match.pair.contains(person2)
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
