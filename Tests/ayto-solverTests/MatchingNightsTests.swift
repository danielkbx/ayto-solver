    import XCTest
    @testable import ayto_solver
    
    final class MatchingNightTests: XCTestCase {
        
        func test_samePerson_multipleTimes_throws() {
            let personA1 = Person(regularPerson: "personA1", gender: .female)
            let personA2 = Person(regularPerson: "personA2", gender: .female)
            let personB1 = Person(regularPerson: "personB1", gender: .male)
            let personB2 = Person(regularPerson: "personB2", gender: .male)
            let personB3 = Person(regularPerson: "personB3", gender: .male)
            
            let night = MatchingNight(title: "Test Night",
                                      pairs: [Pair(personA1, personB1), Pair(personA2, personB2), Pair(personA1, personB3)],
                                      hits: 1)
            
            do {
                let _ = try night.deducedMatches(by: [])
                XCTAssertFalse(true) // there should be an error
            } catch {
                if let error = error as? MatchingNight.DeduceError {
                    switch error {
                    case .matchesExceedHits: XCTAssertFalse(true) // this is the wrong error
                    case .noMatchesExceedNoHits: XCTAssertFalse(true) // this is the wrong error
                    case .personInMultipePairs(let person):
                        XCTAssertEqual(person, personA1)
                    }
                } else {
                    XCTAssertFalse(true) // this is the wrong error
                }
            }
        }
        
        func test_deduceHits() throws {
            let personA1 = Person(regularPerson: "personA1", gender: .female)
            let personA2 = Person(regularPerson: "personA2", gender: .female)
            let personA3 = Person(regularPerson: "personA3", gender: .female)
            let personB1 = Person(regularPerson: "personB1", gender: .male)
            let personB2 = Person(regularPerson: "personB2", gender: .male)
            let personB3 = Person(regularPerson: "personB3", gender: .male)
            
            let knownMatches = [Match.noMatch(personA1, personB1), Match.noMatch(personA2, personB2)]
            
            let night = MatchingNight(title: "Test Night",
                                      pairs: [Pair(personA1, personB1), Pair(personA2, personB2), Pair(personA3, personB3)],
                                      hits: 1)
            
            let matches = try night.deducedMatches(by: knownMatches).filter { $0.isMatch }
            
            XCTAssertEqual(matches.count, 1)
            XCTAssertTrue(matches.first!.contains(personA3))
            XCTAssertTrue(matches.first!.contains(personB3))
        }
        
        func test_deduceNoHits() throws {
            let personA1 = Person(regularPerson: "personA1", gender: .female)
            let personA2 = Person(regularPerson: "personA2", gender: .female)
            let personA3 = Person(regularPerson: "personA3", gender: .female)
            let personB1 = Person(regularPerson: "personB1", gender: .male)
            let personB2 = Person(regularPerson: "personB2", gender: .male)
            let personB3 = Person(regularPerson: "personB3", gender: .male)
            
            let knownMatches = [Match.match(personA1, personB1), Match.match(personA2, personB2)]
            
            let night = MatchingNight(title: "Test Night",
                                      pairs: [Pair(personA1, personB1), Pair(personA2, personB2), Pair(personA3, personB3)],
                                      hits: 2)
            
            let allMatches = try night.deducedMatches(by: knownMatches)
            let matches = allMatches.filter { $0.isMatch }
            XCTAssertEqual(matches.count, 2)
            
            let noMatches = allMatches.filter { !$0.isMatch }
            XCTAssertNotNil(noMatches.matches(with: personA3, and: personB3).first)
        }
        
        func test_tooManyHits_throws() throws {
            let personA1 = Person(regularPerson: "personA1", gender: .female)
            let personA2 = Person(regularPerson: "personA2", gender: .female)
            let personA3 = Person(regularPerson: "personA3", gender: .female)
            let personB1 = Person(regularPerson: "personB1", gender: .male)
            let personB2 = Person(regularPerson: "personB2", gender: .male)
            let personB3 = Person(regularPerson: "personB3", gender: .male)
            
            let knownMatches = [Match.match(personA1, personB1), Match.match(personA2, personB2)]
            
            let night = MatchingNight(title: "Test Night",
                                      pairs: [Pair(personA1, personB1), Pair(personA2, personB2), Pair(personA3, personB3)],
                                      hits: 1)
            
            do {
                let _ = try night.deducedMatches(by: knownMatches)
            } catch {
                if let error = error as? MatchingNight.DeduceError {
                    switch error {
                    case .matchesExceedHits: XCTAssertTrue(true)
                    case .noMatchesExceedNoHits: XCTAssertFalse(true) // this is the wrong error
                    case .personInMultipePairs: XCTAssertFalse(true) // this is the wrong error
                    }
                } else {
                    XCTAssertFalse(true) // this is the wrong error
                }
            }
        }
        
        func test_tooManyNoMatches_throws() throws {
            let personA1 = Person(regularPerson: "personA1", gender: .female)
            let personA2 = Person(regularPerson: "personA2", gender: .female)
            let personA3 = Person(regularPerson: "personA3", gender: .female)
            let personB1 = Person(regularPerson: "personB1", gender: .male)
            let personB2 = Person(regularPerson: "personB2", gender: .male)
            let personB3 = Person(regularPerson: "personB3", gender: .male)
            
            let knownMatches = [Match.noMatch(personA1, personB1), Match.noMatch(personA2, personB2)]
            
            let night = MatchingNight(title: "Test Night",
                                      pairs: [Pair(personA1, personB1), Pair(personA2, personB2), Pair(personA3, personB3)],
                                      hits: 2)
            
            do {
                let _ = try night.deducedMatches(by: knownMatches)
                XCTAssertFalse(true) // there should be an error
            } catch {
                if let error = error as? MatchingNight.DeduceError {
                    switch error {
                    case .noMatchesExceedNoHits: XCTAssertTrue(true)
                    case .matchesExceedHits: XCTAssertTrue(true) // this is the wrong error
                    case .personInMultipePairs: XCTAssertFalse(true) // this is the wrong error
                    }
                } else {
                    XCTAssertFalse(true) // this is the wrong error
                }
            }
        }
        
        func test_relevantMatches() {
            let personA1 = Person(regularPerson: "personA1", gender: .female)
            let personA2 = Person(regularPerson: "personA2", gender: .female)
            let personA3 = Person(regularPerson: "personA3", gender: .female)
            let personB1 = Person(regularPerson: "personB1", gender: .male)
            let personB2 = Person(regularPerson: "personB2", gender: .male)
            let personB3 = Person(regularPerson: "personB3", gender: .male)
            
            let knownMatches = [
                Match.noMatch(personA1, personB1), // +
                Match.noMatch(personB2, personA2), // +
                Match.match(personA1, personB3),   // -
                Match.noMatch(personA2, personB3), // -
                Match.noMatch(personA3, personB3), // -
            ]
            
            let night = MatchingNight(title: "Test Night",
                                      pairs: [Pair(personA1, personB1), Pair(personA2, personB2)],
                                      hits: 1)
            
            let relevantMatches = night.relevantMatches(of: knownMatches)
            
            XCTAssertEqual(relevantMatches.count, 2)
        }
        
    }
