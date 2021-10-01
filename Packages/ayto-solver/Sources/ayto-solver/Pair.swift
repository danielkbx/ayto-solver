import Foundation

/// Combines two person to a pair.
///
/// The persons must be of opposite gender.
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
    
    /// Returns the person of the pair that ist of the given gender.
    public func person(with gender: Person.Gender) -> Person {
        return [self.person1, self.person2].first(where: { $0.gender == gender })!
    }
    
    /// Returns true if the pair contains the given person.
    public func contains(_ person: Person) -> Bool {
        self.person1 == person || self.person2 == person
    }
    
    /// Returns the person of the pair that is not given person.
    ///
    /// Throw an error, if the given person is not part of the pair.
    public func not(person: Person) throws -> Person {
        guard self.contains(person) else {
            throw ContainmentError.doesNotContain(person: person)
        }
        
        return (self.person1 == person) ? person2 : person1
    }
    
    /// Returns true if the pair cannot be a safe match because the given match contains contrary information.
    ///
    /// For example, the pair of P1 and P2 canot be a match, if a safe match of P1 and P3 is already known.
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
    
    /// Returns true if the pair cannot be a safe match because the list of given matches contains contrary information.
    public func isImpossible(by matches: [Match]) -> Bool {
        let matchesWithPair = matches.matches(with: self)
        if matchesWithPair.filter({ !$0.isMatch }).count > 0 {
            return true
        }
        
        if matchesWithPair.safeMatches().count == 1 {
            return false
        }
        
        let matchesWithPersons = matches.matches(with: self.persons)
        return matchesWithPersons.safeMatches().count > 0
    }
    
    /// Returns true if the pair is a match because the given match already contains the information about a safe match.
    public func isMatch(by match: Match) -> Bool {
        if match.isMatch {
            return match.pair.contains(person1) && match.pair.contains(person2)
        } else {
            return false
        }
    }
    
    /// Returns true if the pair is a match because the given list of match already contains the information about a safe match.
    public func isMatch(by matches: [Match]) -> Bool {
        let matchesWithPersons = matches.matches(with: self)
        return matchesWithPersons.safeMatches().count > 0
    }
}
