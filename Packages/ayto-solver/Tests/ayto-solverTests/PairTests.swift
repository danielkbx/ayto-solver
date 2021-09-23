    import XCTest
    @testable import ayto_solver

    final class PairTests: XCTestCase {
        
        func test_contains() {
            let personA1 = Person(regularPerson: "personA1", gender: .female)
            let personB1 = Person(regularPerson: "personB1", gender: .male)
            let personC1 = Person(regularPerson: "personC1", gender: .male)
            let pair = Pair(personA1, personB1)
            
            XCTAssertTrue(pair.contains(personA1))
            XCTAssertTrue(pair.contains(personB1))
            XCTAssertFalse(pair.contains(personC1))
        }
        
        func test_isImpossible() {
            let personA1 = Person(regularPerson: "personA1", gender: .female)
            let personA2 = Person(regularPerson: "personA2", gender: .female)
            let personB1 = Person(regularPerson: "personB1", gender: .male)
            let personB2 = Person(regularPerson: "personB2", gender: .male)
            
            let matches = [Match.noMatch(personA1, personB1), Match.match(personA2, personB2)]
            
            XCTAssertTrue(Pair(personA1, personB1).isImpossible(by: matches))
            XCTAssertTrue(Pair(personA1, personB2).isImpossible(by: matches))
            XCTAssertTrue(Pair(personA2, personB1).isImpossible(by: matches))
            
            XCTAssertFalse(Pair(personA2, personB2).isImpossible(by: matches))
        }
        
        func test_isMatch() {
            let personA1 = Person(regularPerson: "personA1", gender: .female)
            let personA2 = Person(regularPerson: "personA2", gender: .female)
            let personB1 = Person(regularPerson: "personB1", gender: .male)
            let personB2 = Person(regularPerson: "personB2", gender: .male)
            
            let matches = [Match.noMatch(personA1, personB1), Match.match(personA2, personB2)]
            
            XCTAssertFalse(Pair(personA1, personB1).isMatch(by: matches))
            XCTAssertFalse(Pair(personA1, personB2).isMatch(by: matches))
            XCTAssertFalse(Pair(personA2, personB1).isMatch(by: matches))
            
            XCTAssertTrue(Pair(personA2, personB2).isMatch(by: matches))
        }
        
        func test_otherPerson_isReturned() throws {
            let personA1 = Person(regularPerson: "personA1", gender: .female)
            let personB1 = Person(regularPerson: "personB1", gender: .male)
            let pair = Pair(personA1, personB1)
            
            XCTAssertEqual(try pair.not(person: personA1), personB1)
            XCTAssertEqual(try pair.not(person: personB1), personA1)
        }
        
        func test_otherPerson_throws() {
            let personA1 = Person(regularPerson: "personA1", gender: .female)
            let personA2 = Person(regularPerson: "personA2", gender: .female)
            let personB1 = Person(regularPerson: "personB1", gender: .male)
            let pair = Pair(personA1, personB1)
            
            XCTAssertThrowsError(try pair.not(person: personA2))
        }
        
    }
