import XCTest
@testable import ayto_solver

final class GameTests: XCTestCase {
    
    func test_unbalancedGame_throwsInBalanceError() throws {
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personA3 = Person(regularPerson: "A3", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        XCTAssertThrowsError(try Game(title: "Test Game",
                       persons: [personA1, personA2, personA3, personB1],
                       knownMatches: [Match.noMatch(personB1, personA1), Match.noMatch(personB1, personA2)],
                       nights: []))
    }
        
    func test_nomination_leftOvers() throws {
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personA3 = Person(regularPerson: "A3", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        let personB3 = Person(regularPerson: "B3", gender: .male)
        let sut = try Game(title: "Test Game",
                       persons: [personA1, personA2, personA3, personB1, personB2, personB3],
                       knownMatches: [Match.noMatch(personB1, personA1), Match.noMatch(personB1, personA2)],
                       nights: [])
        
        
        try sut.nominateSingleLeftOver()
        let matches = sut.knownMatches
        
        XCTAssertEqual(matches.count, 3)
        
        let match = matches.matches(with: personB1, and: personA3).first
        XCTAssertNotNil(match)
        XCTAssertTrue(match!.isMatch)
    }
    
    func test_nomination_leftOvers_withExtra() throws {
        let personA1 = Person(extraPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personA3 = Person(regularPerson: "A3", gender: .female)
        let personA4 = Person(regularPerson: "A4", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        let personB3 = Person(regularPerson: "B3", gender: .male)
        let sut = try Game(title: "Test Game",
                       persons:
                        [personA1, personA2, personA3, personA4, personB1, personB2, personB3],
                       knownMatches:
                        // personB1 must match with personA4
                        [Match.noMatch(personB1, personA2), Match.noMatch(personB1, personA3)],
                       nights: [])
        
        // there is only one regular person left, so it must be nominated
        // The now only left-over is an extra, so it can be nominated too
        
        try sut.nominateSingleLeftOver()
        let matches = sut.knownMatches
        
        // there is only one additional match
        XCTAssertEqual(matches.count, 3)
        // which is the deducted nomination of the only regular left over
        let safeMatches = matches.safeMatches()
        XCTAssertEqual(matches.safeMatches().count, 1)
        let B1A4match = safeMatches.matches(with: personB1, and: personA4).first
        XCTAssertNotNil(B1A4match)
    }
    
    func test_nomination_leftOvers_forExtra() throws {
        let personA1 = Person(extraPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personA3 = Person(regularPerson: "A3", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        let sut = try Game(title: "Test Game",
                       persons:
                        [personA1, personA2, personA3, personB1, personB2],
                       knownMatches:
                        // personA1 must match with personB2 although A1 is an extra
                        [Match.noMatch(personA1, personB1)],
                       nights: [])
        
        try sut.nominateSingleLeftOver()
        let matches = sut.knownMatches
        
        // there is only one additional match
        XCTAssertEqual(matches.count, 2)
        // which is the deducted nomination of the only regular left over
        let safeMatches = matches.safeMatches()
        XCTAssertEqual(matches.safeMatches().count, 1)
        let A1B2match = safeMatches.matches(with: personA1, and: personB2).first
        XCTAssertNotNil(A1B2match)
    }
    
    func test_eliminatePersons() throws {
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        let sut = try Game(title: "Test Game",
                       persons: [personA1, personA2, personB1, personB2],
                       knownMatches: [Match.match(personA1, personB1)],
                       nights: [])
        
        try sut.eliminatePersons()
        let matches = sut.knownMatches
        
        XCTAssertEqual(matches.count, 3)
        XCTAssertTrue(matches.matches(with: personA1, and: personB1).first!.isMatch)
        XCTAssertFalse(matches.matches(with: personA1, and: personB2).first!.isMatch)
        XCTAssertFalse(matches.matches(with: personA2, and: personB1).first!.isMatch)
        
        try sut.nominateSingleLeftOver()
        let finalMatches = sut.knownMatches
        XCTAssertEqual(finalMatches.count, 4)
    }
    
    func test_eliminatePersons_withExtra() throws {
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personA3 = Person(extraPerson: "A3", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        let sut = try Game(title: "Test Game",
                       persons: [personA1, personA2, personA3, personB1, personB2],
                       knownMatches: [Match.match(personA1, personB1)],
                       nights: [])
        
        try sut.eliminatePersons()
        let matches = sut.knownMatches
        
        XCTAssertEqual(matches.count, 3)
        XCTAssertTrue(matches.matches(with: personA1, and: personB1).first!.isMatch)
        XCTAssertFalse(matches.matches(with: personA1, and: personB2).first!.isMatch)
        XCTAssertFalse(matches.matches(with: personA2, and: personB1).first!.isMatch)
        
        try sut.nominateSingleLeftOver()
        let finalMatches = sut.knownMatches
        XCTAssertEqual(finalMatches.count, 4)
    }
    
    func test_eliminatePersons_forExtra() throws {
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personA3 = Person(extraPerson: "A3", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        let sut = try Game(title: "Test Game",
                       persons: [personA1, personA2, personA3, personB1, personB2],
                       knownMatches: [Match.match(personA3, personB1)],
                       nights: [])
        
        try sut.eliminatePersons()
        let matches = sut.knownMatches
        
        XCTAssertEqual(matches.count, 2)
        XCTAssertTrue(matches.matches(with: personA3, and: personB1).first!.isMatch)
        XCTAssertFalse(matches.matches(with: personA3, and: personB2).first!.isMatch)
                
        try sut.nominateSingleLeftOver()
        let finalMatches = sut.knownMatches
        XCTAssertEqual(finalMatches.count, 2) // there is no new data in here
    }
    
    func test_complex() throws {
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personA3 = Person(regularPerson: "A3", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        let personB3 = Person(regularPerson: "B3", gender: .male)
        let sut = try Game(title: "Test Game",
                       persons: [personA1, personA2, personA3, personB1, personB2, personB3],
                       knownMatches: [Match.match(personA1, personB1), Match.noMatch(personA2, personB3), Match.noMatch(personA3, personB2)],
                       nights: [])
        
        try sut.eliminatePersons()
        try sut.nominateSingleLeftOver()
        let matches = sut.knownMatches
                
        XCTAssertEqual(matches.count, 9)
        XCTAssertTrue(matches.matches(with: personA1, and: personB1).first!.isMatch)
        XCTAssertTrue(matches.matches(with: personA2, and: personB2).first!.isMatch)
        XCTAssertTrue(matches.matches(with: personA3, and: personB3).first!.isMatch)
    }
    
    func test_matchLastPair() throws {
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        
        let sut = try Game(title: "Test Game",
                       persons: [personA1, personA2, personB1, personB2],
                       knownMatches: [Match.match(personA1, personB1)],
                       nights: [])
        
        try sut.matchLastPair()
        let safeMatches = sut.knownMatches.safeMatches()
        
        XCTAssertEqual(safeMatches.count, 2)
        
        let A2B2Match = safeMatches.matches(with: personA2, and: personB2).first
        XCTAssertNotNil(A2B2Match)
        XCTAssertTrue(A2B2Match?.isMatch ?? false)
    }
    
}
