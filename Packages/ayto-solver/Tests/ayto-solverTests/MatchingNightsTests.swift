    import XCTest
    @testable import ayto_solver

    final class MatchingNightTests: XCTestCase {
        
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
        
    }
