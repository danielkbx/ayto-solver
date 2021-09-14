import Foundation

public struct Person: Equatable, Identifiable {
    
    public var id: String { return self.name.lowercased() }
        
    public enum Gender {
        case male
        case female
    }
    
    public enum Role {
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
    
}
