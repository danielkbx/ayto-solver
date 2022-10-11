import XCTest
@testable import ayto_solver

final class MatchesTests: XCTestCase {
    
    func test_matches_withPerson() {
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personA3 = Person(regularPerson: "A3", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        let matches = [
            Match.noMatch(personA1, personB1),
            Match.noMatch(personA1, personB2),
            Match.noMatch(personA2, personB1),
            Match.match(personA3, personB1)
        ]
        
        XCTAssertEqual(matches.matches(with: personA1).count, 2)
        XCTAssertEqual(matches.matches(with: personA2).count, 1)
        XCTAssertEqual(matches.matches(with: personA3).count, 1)
        XCTAssertEqual(matches.matches(with: personB1).count, 3)
        XCTAssertEqual(matches.matches(with: personB2).count, 1)
    }
    
    func test_matches_pair() {
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personA3 = Person(regularPerson: "A3", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        let matches = [
            Match.noMatch(personA1, personB1),
            Match.noMatch(personA1, personB2),
            Match.noMatch(personA2, personB1),
            Match.match(personA3, personB1)
        ]
        
        XCTAssertEqual(matches.matches(containingPersonsOf: Pair(personA1, personB1)).count, 4)
        XCTAssertEqual(matches.matches(containingPersonsOf: Pair(personA1, personB2)).count, 2)
        XCTAssertEqual(matches.matches(containingPersonsOf: Pair(personA2, personB1)).count, 3)
        XCTAssertEqual(matches.matches(containingPersonsOf: Pair(personA3, personB1)).count, 3)
        XCTAssertEqual(matches.matches(containingPersonsOf: Pair(personA2, personB1)).count, 3)
    }
    
    func test_containsAnyOf() {
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personA3 = Person(regularPerson: "A3", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        let personB3 = Person(regularPerson: "B3", gender: .male)
        let matches = [
            Match.noMatch(personA1, personB1),
            Match.noMatch(personA2, personB1),
            Match.noMatch(personA3, personB1),
            Match.noMatch(personA1, personB2),
            Match.noMatch(personA2, personB2),
        ]
        
        XCTAssertEqual(matches.matches(with: [personA1, personA2, personA3]).count, 5)
        XCTAssertEqual(matches.matches(with: [personA3]).count, 1)
        XCTAssertEqual(matches.matches(with: [personB3]).count, 0)
    }
    
    func test_safeMatches() {
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        let matches = [
            Match.match(personA1, personB1),
            Match.match(personA2, personB2),
            Match.noMatch(personA1, personB2),
            Match.noMatch(personA1, personB1),
        ]
        
        let safeMatches = matches.safeMatches()
        
        XCTAssertEqual(safeMatches.count, 2)
        XCTAssertTrue(safeMatches.first!.contains(personA1))
        XCTAssertTrue(safeMatches.first!.contains(personB1))
        XCTAssertTrue(safeMatches.last!.contains(personA2))
        XCTAssertTrue(safeMatches.last!.contains(personB2))
    }
    
    func test_unique_makesUnique() {
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        let matches = [
            Match.noMatch(personA1, personB1),
            Match.noMatch(personA2, personB2),
            Match.noMatch(personA1, personB1),
        ]
        
        do {
            let unique = try matches.unique()
            XCTAssertEqual(unique.count, 2)
        } catch {
            XCTAssertTrue(false) // there is an error
        }
    }
    
    func test_unique_detectsConflicts_aboutPair() {
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        let matches = [
            Match.match(personA1, personB1),
            Match.noMatch(personA1, personB1),
            
            Match.match(personA2, personB2),
        ]
        
        do {
            let _ = try matches.unique()
            XCTAssertTrue(false) // this should have thrown an error
        } catch {
            let error = error as? Match.UniqueError
            XCTAssertNotNil(error)
            
            switch error {
            case .conflictingResult(let pair):
                XCTAssertTrue(pair.contains(personA1))
                XCTAssertTrue(pair.contains(personB1))
            default:
                XCTAssertTrue(false)
            }
        }
    }
    
    func test_unique_detectsConflicts_contradictoryMatches() {
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        let matches = [
            Match.match(personA1, personB1),
            Match.noMatch(personA1, personB2),
            Match.match(personA2, personB1),
        ]
        
        do {
            let _ = try matches.unique()
            XCTAssertTrue(false) // this should have thrown an error
        } catch {
            let error = error as? Match.UniqueError
            XCTAssertNotNil(error)
            
            switch error {
            case .contradictory(let matches):
                XCTAssertEqual(matches.count, 2)
                XCTAssertEqual(matches.matches(with: personA1).count, 1)
                XCTAssertEqual(matches.matches(with: personB1).count, 2)
                XCTAssertEqual(matches.matches(with: personA2).count, 1)
            default:
                XCTAssertTrue(false)
            }
        }
    }
    
    func test_unique_detectsConflicts_contradictoryMatches_withExtra() {
        let personA1 = Person(extraPerson: "A1", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        let matches = [
            Match.match(personA1, personB1),
            Match.match(personA1, personB2),
        ]
        
        do {
            let _ = try matches.unique()
            XCTAssertTrue(false) // this should have thrown an error
        } catch {
            let error = error as? Match.UniqueError
            XCTAssertNotNil(error)
            
            switch error {
            case .contradictory(let matches):
                XCTAssertEqual(matches.count, 2)
            default:
                XCTAssertTrue(false)
            }
        }
    }
    
    func test_unique_doesNotDetectsConflicts_contradictoryMatches_withExtra() {
        let personA1 = Person(extraPerson: "A1", gender: .female)
        let personB1 = Person(regularPerson: "B1", gender: .male)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personB2 = Person(regularPerson: "B2", gender: .male)
        // an extra person can be an additional match for one person of the other gender
        let matches = [
            Match.match(personA1, personB1),
            Match.match(personA2, personB1),
            
            Match.noMatch(personA2, personB2)
        ]
        
        do {
            let unique = try matches.unique()
            XCTAssertEqual(unique.count, 3)
        } catch {
            XCTAssertTrue(false) // there is an error
        }
    }
    
    
}

