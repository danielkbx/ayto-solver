import Foundation

extension Transport {
    
    struct Person: Codable {
        let name: String
        let gender: ayto_solver.Person.Gender
        let role: ayto_solver.Person.Role?
        
        internal func person() throws -> ayto_solver.Person {
            ayto_solver.Person(name: self.name, gender: self.gender, role: self.role ?? .regular)
        }
    }
}
