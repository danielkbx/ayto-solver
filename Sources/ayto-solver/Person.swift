import Foundation

/// Describes a single person of the game.
public struct Person: Equatable, Identifiable, Hashable {
    
    private(set) public var id: String
        
    public enum Gender: String, Codable {
        case male
        case female
        
        public var other: Gender {
            switch self {
            case .female: return .male
            case .male: return .female
            }
        }
    }
    
    /// Persons can have different rules being applied on them.
    public enum Role: String, Codable {
        /// A regular role person can be matched to another regular person AND to an extra person of the oppoiste gender.
        case regular
        /// An extra role person can be matched only to regular person of the opposite gender.
        case extra
    }
    
    public let name: String
    public let gender: Gender
    public let role: Role
    
    public init(name: String, gender: Gender, role: Role) {
        self.name = name
        self.gender = gender
        self.role = role
        self.id = [name.lowercased(), "\(gender)", "\(role)"].joined(separator: "-")
    }
    
    public init(regularPerson name: String, gender: Gender) {
        self.init(name: name, gender: gender, role: .regular)
    }
    
    public init(extraPerson name: String, gender: Gender) {
        self.init(name: name, gender: gender, role: .extra)
    }
}

public extension Sequence where Element == Person {
    
    /// Returns the person with the given name.
    func person(withName name: String) -> Person? {
        self.first(where: {$0.name == name})
    }
    
    /// Returns a unique list of persons.
    func unique() -> [Person] {
        Array(Set(self))
    }
    
    /// Returns all persons with the given role.
    func with(role: Person.Role) -> [Person] {
        filter { $0.role == role }
    }
    
    /// Returns all persons with the given gender.
    func with(gender: Person.Gender) -> [Person] {
        filter{ $0.gender == gender }
    }
    
    /// Returns the number of persons with the given role.
    func numberOfPersons(withRole role: Person.Role) -> Int {
        with(role: role).count
    }
    
    /// Returns a list of persons where the given list of persons is excluded.
    func without(_ persons: [Person]) -> [Person] {
        filter { !persons.contains($0) }
    }
    
}
