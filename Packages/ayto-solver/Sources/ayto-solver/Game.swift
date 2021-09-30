import Foundation
import Logging

public class Game {
    
    public enum ConstrainsError: Error {
        case personsGenderNotBalanced(male: Int, female: Int)
    }
    
    public enum SolveError: Error {
        case conflictingMatches(pair: Pair)
        case contradictoryMatches(matches: [Match])
        case matchingNightNotUnique(night: MatchingNight, person: Person)
        case matchingNightExceedsHits(night: MatchingNight)
        case matchingNightExceedsNoHits(night: MatchingNight)
    }
    
    public let title: String
    
    public let persons: [Person]
    private(set) public var knownMatches: [Match]
    public let matchingNights: [MatchingNight]
    
    public init(title: String, persons: [Person], knownMatches: [Match], nights: [MatchingNight]) throws {
        self.title = title
        self.persons = persons
        self.knownMatches = knownMatches
        self.matchingNights = nights
        
        let femalePersons = self.persons.with(gender: .female).with(role: .regular)
        let malePersons = self.persons.with(gender: .male).with(role: .regular)
        
        guard femalePersons.count == malePersons.count else {
            throw Game.ConstrainsError.personsGenderNotBalanced(male: malePersons.count, female: femalePersons.count)
        }
    }
    
    public var personsWithMatch: [Person] { knownMatches.safeMatches().persons() }
    public var personsWithoutMatch: [Person] { persons.without(personsWithMatch) }
    
    public func solve(logger: Logger? = nil, extendedCalculations: Bool = true) throws -> Solution {
        let solution = try singleSolve(logger: logger)
        
        let expectedNumberOfMatches = max(persons.with(gender: .female).count, persons.with(gender: .male).count)
        if solution.matches.count >= expectedNumberOfMatches {
            return solution
        }

        let personsWithoutMatch = personsWithoutMatch
        if personsWithoutMatch.count == 1 {
            let person = personsWithoutMatch.first!
            if person.role == .extra {
                // only the exta person is left
                let solutionCandidates: [SolutionCandidate] = try self.persons.with(gender: person.gender.other).compactMap {
                    if self.knownMatches.matches(with: person, and: $0).count > 0 { return nil }
                    return try SolutionCandidate(game: self, assumedPairs: [Pair($0, person)])
                }

                let solutions: [Solution] = solutionCandidates.compactMap { $0.solve(logger: logger) }
                if solutions.count == 1 {
                    return solution
                } else if solutions.count > 1 {
                    let matches = solutions.reduce([]) { result, solution in result + solution.allMatches }.filter { !($0.contains(person) && $0.isMatch) }
                    if let combinedMatches = try? matches.unique(),
                       let finalGame = try? Game(title: self.title, persons: self.persons, knownMatches: combinedMatches, nights: self.matchingNights),
                       let finalSolution = try? finalGame.singleSolve(logger: logger)
                    {
                        return finalSolution
                    }
                }
            }
        }
        
        return solution
    }
    
    fileprivate func singleSolve(logger: Logger? = nil) throws -> Solution {
        
        var loops = 0
        var didDeduceSomething: Bool = false
        repeat {
            didDeduceSomething = false
            loops += 1
            
            do {
                let eliminatedMatches = try eliminatePersons(logger: logger)
                if eliminatedMatches.count > 0 {
                    didDeduceSomething = true
                }
                
                
                let nominatedMatches = try nominateSingleLeftOver(logger: logger)
                if nominatedMatches.count > 0 {
                    didDeduceSomething = true
                }
                
                for night in self.matchingNights.sorted(by: { $0.hits < $1.hits }) {
                    do {
                        let deducedMatches = try night.deducedMatches(by: self.knownMatches, logger: logger)
                        if deducedMatches.count > knownMatches.count {
                            self.knownMatches = try deducedMatches.unique()
                            didDeduceSomething = true
                        }
                    } catch {
                        if let error = error as? MatchingNight.DeduceError {
                            switch error {
                            case .matchesExceedHits: throw SolveError.matchingNightExceedsHits(night: night)
                            case .noMatchesExceedNoHits: throw SolveError.matchingNightExceedsNoHits(night: night)
                            case .personInMultipePairs(let person): throw SolveError.matchingNightNotUnique(night: night, person: person)
                            }
                        } else {
                            throw error
                        }
                    }
                }
                
                if try self.matchLastPair().count > 0 {
                    didDeduceSomething = true
                }
                
            } catch {
                if let error = error as? Match.UniqueError {
                    switch error {
                    case .conflictingResult(let pair): throw SolveError.conflictingMatches(pair: pair)
                    case .contradictory(let matches): throw SolveError.contradictoryMatches(matches: matches)
                    }
                } else {
                    throw error
                }
            }
            
            
        } while didDeduceSomething && loops <= 100
        
        return Game.Solution(allMatches: knownMatches, calculationLoops: loops)
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
                        if self.knownMatches.matches(with: person, and: noMatchPerson).count > 0 { continue }
                        logger?.debug("Creating no match", metadata: ["for": "\(noMatchPerson.name)", "from": "\(person.name)"])
                        eliminatedMatches.append(Match.noMatch(person, noMatchPerson))
                    }
                }
            }
        }
        
        self.knownMatches = try (eliminatedMatches + self.knownMatches).unique()
        return eliminatedMatches
    }
    
    @discardableResult
    internal func nominateSingleLeftOver(logger: Logger? = nil) throws -> [Match] {
        var nominatedLeftOverMatches: [Match] = []
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
                let newMatch = Match.match(person, leftOverPerson)
                matches.append(newMatch)
                nominatedLeftOverMatches.append(newMatch)
            }                        
        }
        
        self.knownMatches = try matches.unique()
        return nominatedLeftOverMatches
    }
    
    @discardableResult
    public func matchLastPair() throws -> [Match] {
        var matches = self.knownMatches
        var lastPairMatches: [Match] = []
        
        var femalePersons = self.persons.with(gender: .female).with(role: .regular)
        var malePersons = self.persons.with(gender: .male).with(role: .regular)
        
        for safeMatch in matches.safeMatches() {
            let femalePerson = safeMatch.pair.person(with: .female)
            let malePerson = safeMatch.pair.person(with: .male)
            femalePersons = femalePersons.filter { $0 != femalePerson }
            malePersons = malePersons.filter { $0 != malePerson }
        }
        
        if femalePersons.count == 1 && malePersons.count == 1 {
            let newMatch = Match.match(femalePersons.first!, malePersons.first!)
            matches.append(newMatch)
            lastPairMatches.append(newMatch)
        }
        
        self.knownMatches = try matches.unique()
        return lastPairMatches
    }
}

public extension Game {
    
    struct Solution {
        public let allMatches: [Match]
        public var matches: [Match] { allMatches.filter { $0.isMatch } }
        public let calculationLoops: Int
    }
    
}

private class SolutionCandidate {
    let game: Game
    let assumedPairs: [Pair]
    
    private(set) var solution: Game.Solution?
    
    init(game: Game, assumedPairs: [Pair]) throws {
        var knownMatches = game.knownMatches
        for pair in assumedPairs {
            knownMatches.append(Match.match(pair.person1, pair.person2))
        }
        self.game = try Game(title: game.title, persons: game.persons, knownMatches: knownMatches, nights: game.matchingNights)
        self.assumedPairs = assumedPairs
    }
    
    func solve(logger: Logger?) -> Game.Solution? {
        if let solution = try? self.game.singleSolve(logger: logger) {
            self.solution = solution
        }
        
        return self.solution
    }
}
