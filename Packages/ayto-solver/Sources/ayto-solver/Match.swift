import Foundation

public struct Match {
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
