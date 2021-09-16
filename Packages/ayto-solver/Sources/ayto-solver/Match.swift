import Foundation

public struct Match: Identifiable, Equatable, Hashable {
    
    public static func == (lhs: Match, rhs: Match) -> Bool { lhs.id == rhs.id }
        
    public var id: String { "\(pair.person1.name.lowercased())-\(pair.person2.name.lowercased())-\(isMatch)" }
                
    public let pair: Pair
    public let isMatch: Bool
    
    private init(_ person1: Person, _ person2: Person, isMatch: Bool) {
        self.pair = Pair(person1, person2)
        self.isMatch = isMatch
    }
    
    public static func match(_ person1: Person, _ person2: Person) -> Match {
        Match(person1, person2, isMatch: true)
    }
    
    public static func noMatch(_ person1: Person, _ person2: Person) -> Match {
        Match(person1, person2, isMatch: false)
    }
    
    public func contains(_ person: Person) -> Bool {
        pair.contains(person)
    }
}

public extension Sequence where Element == Match {
    
    func match(with person1: Person, and person2: Person) -> Match? {
        self.first(where: { $0.contains(person1) && $0.contains(person2) })
    }
    
}
