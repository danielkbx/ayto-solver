import Foundation
import Logging

public class Game {
    
    public let persons: [Person]
    private(set) public var knownMatches: [Match]
    public let matchingNights: [MatchingNight]
    
    public init(persons: [Person], knownMatches: [Match], nights: [MatchingNight]) {
        self.persons = persons
        self.knownMatches = knownMatches
        self.matchingNights = nights
    }
    
    public func solve(logger: Logger? = nil) -> Solution {
                                
        var didDeduceSomething: Bool = false
        repeat {
            didDeduceSomething = false
            
            let eliminatedMatches = eliminatePersons(by: self.knownMatches, logger: logger)
            if eliminatedMatches.count > self.knownMatches.count {
                didDeduceSomething = true
                self.knownMatches = eliminatedMatches                
                continue
            }
            
            let nominatedMatches = nomateSingleLeftOver(by: self.knownMatches, logger: logger)
            if nominatedMatches.count > self.knownMatches.count {
                didDeduceSomething = true
                self.knownMatches = nominatedMatches
                continue
            }
            
            for night in self.matchingNights.sorted(by: { $0.hits < $1.hits }) {
                let deducedMatches = night.deducedMatches(by: self.knownMatches, logger: logger)
                if deducedMatches.count > knownMatches.count {
                    didDeduceSomething = true
                    self.knownMatches = deducedMatches
                    continue
                }

            }
        } while didDeduceSomething
        
        return Game.Solution(matches: knownMatches)
    }
    
    private func eliminatePersons(by knownMatches: [Match], logger: Logger? = nil) -> [Match] {
        let matches = knownMatches.filter { $0.isMatch }
        
        var eliminatedMatches: [Match] = []
        for match in matches {
            logger?.debug("Deducing no matches from match", metadata: ["person1": "\(match.pair.person1.name)", "persons2": "\(match.pair.person2.name)"])
            for person in [match.pair.person1, match.pair.person2] {
                if person.role != .extra {
                    for noMatchPerson in self.persons.filter({ $0.gender == person.gender.other }) {
                        guard !match.contains(noMatchPerson) else { continue }
                        logger?.debug("Creating no match", metadata: ["for": "\(noMatchPerson.name)", "from": "\(person.name)"])
                        eliminatedMatches.append(Match.noMatch(person, noMatchPerson))
                    }
                }
            }
        }
        
        let allMatches = eliminatedMatches + knownMatches        
        return Array(Set(allMatches))
    }
    
    private func nomateSingleLeftOver(by knownMatches: [Match], logger: Logger? = nil) -> [Match] {
        var matches = knownMatches
        for person in self.persons {
            let matchesForPerson = knownMatches.filter { $0.contains(person) }
            if let _ = matchesForPerson.first(where: { $0.isMatch }) { continue }
            
            let noMatchPairs = matchesForPerson.map { $0.pair }
            let noMatchPersons = noMatchPairs.map { $0.person(with: person.gender.other) }
            let otherPersons = persons.filter { $0.gender == person.gender.other && $0.role == .regular }
            let leftOverPersons = otherPersons.filter { !noMatchPersons.contains($0) }
            if leftOverPersons.count == 1 {
                let leftOverPerson = leftOverPersons.first!
                logger?.debug("Only one person left to match", metadata: ["person": "\(leftOverPerson.name)", "for": "\(person.name)"])
                matches.append(Match.match(person, leftOverPerson))
            }
        }
        
        return matches
    }
}

public extension Game {
    
    struct Solution {
        public let matches: [Match]
    }
    
}
