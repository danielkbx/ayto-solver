import Foundation
import Logging
import Algorithms

/// Contains all information about a single game containing the persons, known matches and the combinations
/// of the matching nights.
///
/// By infering information from the known data, a solution is calculated (if possible).
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
    
    /// Returns a list of persons that are known  to be part of a safe match (they already found the matching person).
    public var personsWithMatch: [Person] { knownMatches.safeMatches().persons() }
    /// Returns the list of persons where no safe match is known.
    public var personsWithoutMatch: [Person] { persons.without(personsWithMatch) }
    /// Returns a list of pairs of a matching night where the match status is not yet known.
    private func unknownPairs(of night: MatchingNight) -> [Pair] {
        night.pairs.compactMap { self.knownMatches.matches(with: $0).first == nil ? $0 : nil }
    }
    
    private func matches(of night: MatchingNight) -> [Match] {
        var result: [Match] = []
        for pair in night.pairs {
            if let match = self.knownMatches.matches(with: pair.person1, and: pair.person2).first {
                result.append(match)
            }
        }
        return result
    }
    
    /// Tries to solve the game.
    ///
    /// This is done by
    /// - eliminating pairs where a single person is already part of a safe match (because a person can only have one match)
    /// - nominating a person if all other persons cannot be a match
    /// - infer mandatory pairs from matching nights (e.g. if only one pair is unknown and it is known that one safe match is missing in that night)
    ///
    ///
    /// - Parameter extendedCalculations: If true, combinations of potential pairs are build and solved. If this causes conflicts, those pairs can be eliminated.
    /// - Parameter afterEachLoop: The block to be called after each calculation loop. Useful for debugging.
    ///
    public func solve(logger: Logger? = nil, extendedCalculations: Bool = true, afterEachLoop: ((_ loop: Int, _ game: Game, _ nights: [MatchingNight]) -> Bool)? = nil) throws -> Solution {
        
        let solveQqueue = DispatchQueue(label: "candidates", qos: .default, attributes: [.concurrent])
        let writeQueue = DispatchQueue(label: "write", qos: .default)
        
        var loops = 0
        var extendedTries = 0
        
        var didExcludeSomething: Bool = false
        var nightsWithDeducedInfo: [MatchingNight] = []
        
        repeat {
            didExcludeSomething = false
            
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
                    
                    nightsWithDeducedInfo = []
                    for night in self.matchingNights.sorted(by: { $0.hits < $1.hits }) {
                        
                        let _ = afterEachLoop?(loops, self, [])
                        
                        do {
                            let deducedMatches = try night.deducedMatches(by: self.knownMatches, logger: logger)
                            let difference = deducedMatches.difference(from: self.knownMatches)
                            var newMatches: [Match] = []
                            for change in difference {
                                switch change {
                                case .insert(_, let element, _):
                                    newMatches.append(element)
                                default:
                                    break
                                }
                            }
                            
                            if newMatches.count > 0 {
                                self.knownMatches = try deducedMatches.unique()
                                nightsWithDeducedInfo.append(night)
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
                
                if (didDeduceSomething || didExcludeSomething), let continueBlock = afterEachLoop {
                    didDeduceSomething = continueBlock(loops, self, nightsWithDeducedInfo)
                }
                
            } while didDeduceSomething && loops <= 100
            
            if extendedCalculations {
                let personsWithoutMatch = self.personsWithoutMatch
                if personsWithoutMatch.count > 0 {
                    
                    if personsWithoutMatch.count == 1, let extraPerson = personsWithoutMatch.first, extraPerson.role == .extra {
                        let solutionCandidates: [SolutionCandidate] = self.persons.with(gender: extraPerson.gender.other).compactMap({ otherPerson in
                            let pair = Pair(extraPerson, otherPerson)
                            guard self.knownMatches.matches(with: pair).count == 0 else { return nil }
                            
                            return SolutionCandidate(game: self, assumedPairs: [pair])
                        })
                        for solutionCandidate in solutionCandidates {
                            extendedTries += 1
                            if solutionCandidate.solve(logger: logger) == nil {
                                didExcludeSomething = true
                                do {
                                    self.knownMatches = try self.knownMatches + solutionCandidate.assumedPairs.map({ Match.noMatch($0.person1, $0.person2) }).unique()
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
                            }
                        }
                    } else if personsWithoutMatch.count > 1 {
                        for night in matchingNights {
                            var solutionCandidates: [SolutionCandidate] = []
                            let unknownPairs = self.unknownPairs(of: night)
                            if unknownPairs.count > 0, unknownPairs.count <= 5 {
                                for pairCandidate in unknownPairs {
                                    if let solutionCandidate = SolutionCandidate(game: self, assumedPairs: [pairCandidate]) {
                                        solutionCandidates.append(solutionCandidate)
                                    }
                                }
                                                                
//                                Swift.print("Checking \(solutionCandidates.count) solution candidates")
                                var excludedPairs: [Pair] = []
                                
                                let dispatchQueue = DispatchGroup()
                                for solutionCandidate in solutionCandidates {
                                    dispatchQueue.enter()
                                    solveQqueue.async {
                                        let solution = solutionCandidate.solve(logger: logger, afterEachLoop: afterEachLoop)
                                        writeQueue.async {
                                            if solution == nil {
                                                excludedPairs.append(contentsOf: solutionCandidate.assumedPairs)
                                            }
                                            dispatchQueue.leave()
                                        }
                                    }
                                }
                                dispatchQueue.wait()
                                if excludedPairs.count > 0 {
                                    self.knownMatches += excludedPairs.map { Match.noMatch($0.person1, $0.person2) }
                                    self.knownMatches = try self.knownMatches.unique()
                                    didExcludeSomething = true
                                }
                            }
                        }
                    }
                }
            }
            
        } while didExcludeSomething
        
        if extendedCalculations {
            repeat {
                didExcludeSomething = false
                let regularPersonsWithoutMath = persons.with(role: .regular).without(personsWithMatch)
                if  regularPersonsWithoutMath.count > 0, regularPersonsWithoutMath.count <= 12 {
                    // try one last thing
                    var pairs: [Pair] = []
                    let males = regularPersonsWithoutMath.with(gender: .male)
                    let females = regularPersonsWithoutMath.with(gender: .female)
                    guard males.count == females.count else {
                        throw Game.ConstrainsError.personsGenderNotBalanced(male: males.count, female: females.count)
                    }
                    
                    for male in males { for female in females {
                        pairs.append(Pair(male, female))
                    } }
                    
                    var excludedPairs: [Pair] = []
                    let dispatchGroup = DispatchGroup()
//                    Swift.print("Checking \(pairs.count) pairs")
                    for candidate in pairs {
                        dispatchGroup.enter()
                        solveQqueue.async {
                            if let solutionCandidate = SolutionCandidate(game: self, assumedPairs: [candidate]) {
                                extendedTries += 1
                                let solution = solutionCandidate.solve(logger: logger, afterEachLoop: afterEachLoop)
                                writeQueue.async {
                                    if solution == nil {
                                        excludedPairs.append(contentsOf: solutionCandidate.assumedPairs)
                                    }
                                    dispatchGroup.leave()
                                }
                            }
                        }
                    }
                    dispatchGroup.wait()
                    if excludedPairs.count > 0 {
                        self.knownMatches += excludedPairs.map { Match.noMatch($0.person1, $0.person2) }
                        self.knownMatches = try self.knownMatches.unique()
                        didExcludeSomething = true
                    }
                }
                
                if didExcludeSomething {
                    if let eliminatedMatches = try? eliminatePersons(logger: logger), eliminatedMatches.count > 0 {
                        didExcludeSomething = true
                    }
                    if let nominatedLeftOvers = try? nominateSingleLeftOver(logger: logger), nominatedLeftOvers.count > 0 {
                        didExcludeSomething = true
                    }
                }
            } while didExcludeSomething
            
            
        }
        
        return Game.Solution(allMatches: knownMatches, calculationLoops: loops, exclusionTries: extendedTries)
    }
    /// Creates match instances for those pairs that cannot be a match because one person is already matched to another person.
    ///
    /// If this causes a conflict an error is thrown. This indicated faulty input data or a provoked conflict during extented calculation.
    @discardableResult
    internal func eliminatePersons(logger: Logger? = nil) throws -> [Match] {
        let matches = knownMatches.filter { $0.isMatch }
        
        var eliminatedMatches: [Match] = []
        for match in matches.safeMatches() {
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
    
    /// Creates a safe match for persons that have only one person as possible match.
    ///
    /// If this causes a conflict an error is thrown. This indicated faulty input data or a provoked conflict during extented calculation.
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
            // and than all no matches with them
            let othersRegularNoMatches = matchesForPerson.filter { !$0.isMatch }
            // get the persons that we do not have a negative match for
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
    
    /// Creates the match for the two last persons.
    ///
    /// If this causes a conflict an error is thrown. This indicated faulty input data or a provoked conflict during extented calculation.
    @discardableResult
    private func matchLastPair() throws -> [Match] {
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
    /// Contains the information of a solution of the game.
    struct Solution {
        /// All known match information of the game.
        public let allMatches: [Match]
        /// All safe matches of the game.
        public var matches: [Match] { allMatches.filter { $0.isMatch } }
        
        public let calculationLoops: Int
        public var exclusionTries: Int
    }
    
}

/// Contains information of a solution candidate. It is used to check if an assumed pair causes any conflicts so it can be ruled out.
private class SolutionCandidate {
    let game: Game
    let assumedPairs: [Pair]
    
    private(set) var solution: Game.Solution?
    
    init?(game: Game, assumedPairs: [Pair]) {
        var knownMatches = game.knownMatches
        for pair in assumedPairs {
            knownMatches.append(Match.match(pair.person1, pair.person2))
        }
        guard let newGame = try? Game(title: game.title, persons: game.persons, knownMatches: knownMatches, nights: game.matchingNights) else { return nil }
        self.game = newGame
        self.assumedPairs = assumedPairs
    }
    
    func solve(logger: Logger?, afterEachLoop: ((_ loop: Int, _ game: Game, _ nights: [MatchingNight]) -> Bool)? = nil) -> Game.Solution? {
        self.solution = try? self.game.solve(logger: logger, extendedCalculations: false, afterEachLoop: afterEachLoop)
        return self.solution
    }
}
