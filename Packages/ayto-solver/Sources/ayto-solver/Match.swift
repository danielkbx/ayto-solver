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
}

public extension Sequence where Element == Match {
            
    func match(with person1: Person, and person2: Person) -> Match? {
        self.first(where: { $0.contains(person1) && $0.contains(person2) })
    }
    
    func matches(with person1: Person, and person2: Person) -> [Match] {
        self.filter { $0.contains(person1) && $0.contains(person2) }
    }
    
    func matches(with person: Person) -> [Match] {
        self.filter { $0.contains(person) }
    }
    
    func matches(containingPersonsOf pair: Pair) -> [Match] {
        self.filter { $0.contains(pair.person1) || $0.contains(pair.person2) }
    }
    
    func unique() throws -> [Match] {
        var matches: [Match] = []
        
        // make them unique
        for candidate in self {
            if let existingMatch = matches.match(with: candidate.pair.person1, and: candidate.pair.person2) {
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
        let safeMatches = matches.filter { $0.isMatch }
        let safePersons = safeMatches.reduce([]) { persons, match in
            persons + [match.pair.person1, match.pair.person2]
        }.unique()
        
        for person in safePersons {
            let personSafeMatches = safeMatches.filter { $0.contains(person) }
            if person.role == .regular && personSafeMatches.count > 1 {
                throw Match.UniqueError.contradictory(matches: personSafeMatches)
            } else if person.role == .extra && personSafeMatches.count > 2 {
                throw Match.UniqueError.contradictory(matches: personSafeMatches)
            }
        }                
        
        return matches        
    }
    
}
