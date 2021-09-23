import Foundation

public struct Match: Identifiable, Equatable, Hashable {
    
    enum UniqueError: Error {
        case conflictingResult(pair: Pair)
        case contradictory(matches: [Match])
    }
    
    public static func == (lhs: Match, rhs: Match) -> Bool { lhs.id == rhs.id }
        
    public var id: String { "\(pair.person1.name.lowercased())-\(pair.person2.name.lowercased())-\(isMatch)" }
                
    public let pair: Pair
    public let isMatch: Bool
    
    private init(_ person1: Person, _ person2: Person, isMatch: Bool) {
        self.pair = Pair(person1, person2)
        self.isMatch = isMatch
    }
    
    public static func match(_ person1: Person, _ person2: Person) -> Match {
        Match(person1, person2, isMatch: true)
    }
    
    public static func noMatch(_ person1: Person, _ person2: Person) -> Match {
        Match(person1, person2, isMatch: false)
    }
    
    public func contains(_ person: Person) -> Bool {
        pair.contains(person)
    }
    
    public func contains(anyOf persons: [Person]) -> Bool {
        for person in persons {
            if contains(person) { return true }
        }
        return false
    }
}

public extension Sequence where Element == Match {
                
    /// Returns all matches that contain both provided persons.
    func matches(with person1: Person, and person2: Person) -> [Match] {
        self.filter { $0.contains(person1) && $0.contains(person2) }
    }
    
    /// Returns all  matches that contain the given pair.
    func matches(with pair: Pair) -> [Match] {
        matches(with: pair.person1, and: pair.person2)
    }
    
    /// Returns all matches than contain the given person.
    func matches(with person: Person) -> [Match] {
        self.filter { $0.contains(person) }
    }
    
    func matches(containingPersonsOf pair: Pair) -> [Match] {
        self.filter { $0.contains(pair.person1) || $0.contains(pair.person2) }
    }
    
    func matches(with persons: [Person]) -> [Match] {
        self.filter { $0.contains(anyOf: persons) }        
    }
    
    func safeMatches() -> [Match] {
        filter { $0.isMatch }
    }
    
    func persons() -> [Person] {
        let persons = self.reduce([]) { persons, match in
            persons + [match.pair.person1, match.pair.person2]
        }
        return persons.unique()
    }
    
    func unique() throws -> [Match] {
        var matches: [Match] = []
        
        // make them unique
        for candidate in self {
            if let existingMatch = matches.matches(with: candidate.pair.person1, and: candidate.pair.person2).first {
                if existingMatch.isMatch != candidate.isMatch {
                    matches.append(candidate)
                }
            } else {
                matches.append(candidate)
            }
        }
        
        // check for contradictory matches for the exact same pair
        for candidate in matches {
            let contradictoryMatches = matches.matches(with: candidate.pair.person1, and: candidate.pair.person2)
            if contradictoryMatches.count == 2 {
                throw Match.UniqueError.conflictingResult(pair: candidate.pair)
            }
        }
        
        // check for contradictory matches because other matches rule them out
        let safeMatches = matches.safeMatches()
        let safePersons = safeMatches.persons()
        
        for person in safePersons {
            let personSafeMatches = safeMatches.matches(with: person)
            let participatingPerson = personSafeMatches.persons()
            
            if participatingPerson.numberOfPersons(withRole: .extra) == 0 {
                // if no extra person is part of the matches, there can only be one
                if personSafeMatches.count > 1 {
                    throw Match.UniqueError.contradictory(matches: personSafeMatches)
                }
                continue
            }
            
            if person.role == .extra {
                // the extra person can only have one match
                if personSafeMatches.count > 1 {
                    throw Match.UniqueError.contradictory(matches: personSafeMatches)
                }
            } else {
                // if the person in regular, it can have two matches if one contains an extra person
                let otherParticipatingPersons = participatingPerson.filter { $0 != person }
                if otherParticipatingPersons.numberOfPersons(withRole: .extra) != 1 {
                    throw Match.UniqueError.contradictory(matches: personSafeMatches)
                }
            }
        }                
        
        return matches        
    }
    
}
