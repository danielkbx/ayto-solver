import Foundation

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
    
    public enum Role: String, Codable {
        case regular
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
    
    func person(withName name: String) -> Person? {
        self.first(where: {$0.name == name})
    }
    
    func unique() -> [Person] {
        Array(Set(self))
    }
    
    func with(role: Person.Role) -> [Person] {
        filter { $0.role == role }
    }
    
    func with(gender: Person.Gender) -> [Person] {
        filter{ $0.gender == gender }
    }
    
    func numberOfPersons(withRole role: Person.Role) -> Int {
        with(role: role).count
    }
    
    func without(_ persons: [Person]) -> [Person] {
        filter { !persons.contains($0) }
    }
    
}
