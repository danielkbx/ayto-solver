import XCTest
@testable import ayto_solver

final class PersonTests: XCTestCase {
    
    func test_unique() {
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personA3 = Person(regularPerson: "A3", gender: .female)
        
        let persons = [personA1, personA2, personA3, personA3].unique()
        
        XCTAssertEqual(persons.count, 3)
        XCTAssertTrue(persons.contains(personA1))
        XCTAssertTrue(persons.contains(personA2))
        XCTAssertTrue(persons.contains(personA3))
    }
    
    func test_personsWithRole() {
        
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personA3 = Person(extraPerson: "A3", gender: .female)
        
        let persons = [personA1, personA2, personA3]
        
        let regularPersons = persons.with(role: .regular)
        let extraPersons = persons.with(role: .extra)
        
        XCTAssertTrue(regularPersons.contains(personA1))
        XCTAssertTrue(regularPersons.contains(personA2))
        XCTAssertTrue(extraPersons.contains(personA3))
    }
    
    func test_countPersonsWithRole() {
        
        let personA1 = Person(regularPerson: "A1", gender: .female)
        let personA2 = Person(regularPerson: "A2", gender: .female)
        let personA3 = Person(extraPerson: "A3", gender: .female)
        
        let persons = [personA1, personA2, personA3]
        
        XCTAssertEqual(persons.numberOfPersons(withRole: .regular), 2)
        XCTAssertEqual(persons.numberOfPersons(withRole: .extra), 1)
    }
    
}
