import Foundation
import Logging
import Algorithms

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
           
    public func solve(logger: Logger? = nil, extendedCalculations: Bool = true, afterEachLoop: ((_ loop: Int, _ game: Game, _ nights: [MatchingNight]) -> Bool)? = nil) throws -> Solution {
        
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
                            if unknownPairs.count > 0 {
                                let matchesOfNight = self.matches(of: night)
                                let safeMatchesOfNight = matchesOfNight.safeMatches()
                                let noMatchesOfNight = matchesOfNight.filter { !$0.isMatch }
                                let pairsToResolve = night.hits - safeMatchesOfNight.count
                                if pairsToResolve  == 1 {
                                    let pairCandidates = unknownPairs.uniquePermutations(ofCount: pairsToResolve)
                                    
                                    for combination in pairCandidates {
                                        if let solutionCandidate = SolutionCandidate(game: self, assumedPairs: Array(combination)) {
                                            solutionCandidates.append(solutionCandidate)
                                        }
                                    }
                                }
                            }
                            
                            for solutionCandidate in solutionCandidates {
                                let solution = solutionCandidate.solve(logger: logger, afterEachLoop: afterEachLoop)
                                if solution == nil {
                                    do {
                                        self.knownMatches = try (self.knownMatches + solutionCandidate.assumedPairs.map({ Match.noMatch($0.person1, $0.person2) })).unique()
                                        didExcludeSomething = true
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
                        }
                    }
                }
            }
            
        } while didExcludeSomething
        
        return Game.Solution(allMatches: knownMatches, calculationLoops: loops, exclusionTries: extendedTries)
    }
    
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
        public var exclusionTries: Int
    }
    
}

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
        do {
            let solution = try self.game.solve(logger: logger, extendedCalculations: false, afterEachLoop: afterEachLoop)
            self.solution = solution
        } catch {
//            var meta: Logger.Metadata = [:]
//            for (index, pair) in assumedPairs.enumerated() {
//                meta["pair\(index)"] = "\(pair.person1.name)+\(pair.person2.name)"
//            }
//            logger?.info("solution candidate did produce conflict", metadata: meta)
//            print(error)
        }
        
        return self.solution
    }
}
