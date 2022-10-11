import Foundation

extension Transport {
    
    struct MatchingNightPair: Codable {
        let person1: String
        let person2: String
    }
    
    struct MatchingNight: Codable {
        let title: String?
        let pairs: [MatchingNightPair]
        let hits: Int
    }
    
}
