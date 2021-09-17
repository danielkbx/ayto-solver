import XCTest
@testable import ayto_solver

final class GameTests: XCTestCase {
    
    func test_nomination_leftOvers() throws {
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personA3 = Person(regularPerson: "A3", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let sut = Game(persons: [personA1, personA2, personA3, personB1],
                       knownMatches: [Match.noMatch(personB1, personA1), Match.noMatch(personB1, personA2)],
                       nights: [])
        
        
        let matches = try sut.nomateSingleLeftOver()
        
        XCTAssertEqual(matches.count, 3)
        
        let match = matches.match(with: personB1, and: personA3)
        XCTAssertNotNil(match)
        XCTAssertTrue(match!.isMatch)
    }
    
    func test_eliminatePersons() throws {
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        let sut = Game(persons: [personA1, personA2, personB1, personB2],
                       knownMatches: [Match.match(personA1, personB1)],
                       nights: [])
        
        let matches = try sut.eliminatePersons()
        
        XCTAssertEqual(matches.count, 3)
        XCTAssertTrue(matches.match(with: personA1, and: personB1)!.isMatch)
        XCTAssertFalse(matches.match(with: personA1, and: personB2)!.isMatch)
        XCTAssertFalse(matches.match(with: personA2, and: personB1)!.isMatch)
        
        let finalMatches = try sut.nomateSingleLeftOver()
        XCTAssertEqual(finalMatches.count, 4)
    }
    
    func test_complex() throws {
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personA3 = Person(regularPerson: "A3", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        let personB3 = Person(regularPerson: "B3", gender: .male)
        let sut = Game(persons: [personA1, personA2, personA3, personB1, personB2, personB3],
                       knownMatches: [Match.match(personA1, personB1), Match.noMatch(personA2, personB3), Match.noMatch(personA3, personB2)],
                       nights: [])
        
        try sut.eliminatePersons()
        let matches = try sut.nomateSingleLeftOver()
                
        XCTAssertEqual(matches.count, 9)
        XCTAssertTrue(matches.match(with: personA1, and: personB1)!.isMatch)
        XCTAssertTrue(matches.match(with: personA2, and: personB2)!.isMatch)
        XCTAssertTrue(matches.match(with: personA3, and: personB3)!.isMatch)
    }
    
}
