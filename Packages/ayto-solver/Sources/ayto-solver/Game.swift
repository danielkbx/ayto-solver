import Foundation
import Logging

public class Game {
    
    public enum ConstrainsError: Error {
        case personsGenderNotBalanced
    }
    
    public let title: String
    
    public let persons: [Person]
    private(set) public var knownMatches: [Match]
    public let matchingNights: [MatchingNight]
    
    public init(title: String, persons: [Person], knownMatches: [Match], nights: [MatchingNight]) {
        self.title = title
        self.persons = persons
        self.knownMatches = knownMatches
        self.matchingNights = nights
    }
    
    public func solve(logger: Logger? = nil) throws -> Solution {
        
        var didDeduceSomething: Bool = false
        repeat {
            didDeduceSomething = false
            
            let eliminatedMatches = try eliminatePersons(logger: logger)
            if eliminatedMatches.count > self.knownMatches.count {
                didDeduceSomething = true
                continue
            }
            
            let nominatedMatches = try nomateSingleLeftOver(logger: logger)
            if nominatedMatches.count > self.knownMatches.count {
                didDeduceSomething = true
                continue
            }
            
            for night in self.matchingNights.sorted(by: { $0.hits < $1.hits }) {
                let deducedMatches = try night.deducedMatches(by: self.knownMatches, logger: logger)
                if deducedMatches.count > knownMatches.count {
                    self.knownMatches = deducedMatches
                    didDeduceSomething = true
                    continue
                }
            }
                                                
        } while didDeduceSomething
        
        try self.matchLastPair()
        
        return Game.Solution(allMatches: knownMatches)
    }
    
    @discardableResult
    internal func eliminatePersons(logger: Logger? = nil) throws -> [Match] {
        let matches = knownMatches.filter { $0.isMatch }
        
        var eliminatedMatches: [Match] = []
        for match in matches {
            logger?.debug("Deducing no matches from match", metadata: ["person1": "\(match.pair.person1.name)", "persons2": "\(match.pair.person2.name)"])
            
            for person in match.pair.persons {
                let partner = try match.pair.not(person: person)
                if partner.role != .extra {
                    for noMatchPerson in self.persons.filter({ $0.gender == person.gender.other && $0.role == .regular }) {
                        guard !match.contains(noMatchPerson) else { continue }
                        logger?.debug("Creating no match", metadata: ["for": "\(noMatchPerson.name)", "from": "\(person.name)"])
                        eliminatedMatches.append(Match.noMatch(person, noMatchPerson))
                    }
                }
            }
        }
        
        self.knownMatches = try (eliminatedMatches + knownMatches).unique()
        return self.knownMatches
    }
    
    @discardableResult
    internal func nomateSingleLeftOver(logger: Logger? = nil) throws -> [Match] {
        guard self.persons.with(gender: .male).with(role: .regular).count == self.persons.with(gender: .female).with(role: .regular).count else {
            throw Game.ConstrainsError.personsGenderNotBalanced
        }
        
        var matches = knownMatches
        
        for person in self.persons {
            // get all the matches of the person
            let matchesForPerson = try matches.matches(with: person).unique()
            // get the known matches with rehular persons
            let regularMatches = try matchesForPerson.safeMatches().filter{ try $0.pair.not(person: person).role == .regular }
            // if we know of a regular match we can stop here
            if regularMatches.count == 1 {
                continue
            }
            
            // get all persons of the other gender
            let otherPersons = self.persons.with(gender: person.gender.other)
            // and the regular persons of those
            let othersRegular = otherPersons.filter { $0.role == .regular }
            // and than all the no matches with them
            let othersRegularNoMatches = matchesForPerson.filter { !$0.isMatch }
            // get the persons the we do not have a negative match for
            let leftOverPersons = othersRegular.filter { candidate in
                othersRegularNoMatches.matches(with: person, and: candidate).count == 0
            }
            // if there is only one left, create the match
            if leftOverPersons.count == 1 {
                let leftOverPerson = leftOverPersons.first!
                logger?.debug("Only one person left to match", metadata: ["person": "\(leftOverPerson.name)", "for": "\(person.name)"])
                matches.append(Match.match(person, leftOverPerson))
            }                        
        }
              
        self.knownMatches = try matches.unique()
        return self.knownMatches
    }
    
    @discardableResult
    public func matchLastPair() throws -> [Match] {
        var matches = self.knownMatches
        
        var femalePersons = self.persons.with(gender: .female).with(role: .regular)
        var malePersons = self.persons.with(gender: .male).with(role: .regular)
        
        guard femalePersons.count == malePersons.count else {
            throw Game.ConstrainsError.personsGenderNotBalanced
        }
        
        for safeMatch in matches.safeMatches() {
            let femalePerson = safeMatch.pair.person(with: .female)
            let malePerson = safeMatch.pair.person(with: .male)
            femalePersons = femalePersons.filter { $0 != femalePerson }
            malePersons = malePersons.filter { $0 != malePerson }
        }
        
        if femalePersons.count == 1 && malePersons.count == 1 {
            matches.append(Match.match(femalePersons.first!, malePersons.first!))
        }
        
        self.knownMatches = try matches.unique()
        return self.knownMatches
    }
}

public extension Game {
    
    struct Solution {
        public let allMatches: [Match]
        
        public var matches: [Match] { allMatches.filter { $0.isMatch } }
    }
    
}
