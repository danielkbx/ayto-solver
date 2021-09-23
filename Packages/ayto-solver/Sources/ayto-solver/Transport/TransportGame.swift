import Foundation

public extension Transport {
    
    struct Game: Codable {
        
        public enum JSONError: Error {
            case unknownPersonInMatchingNight(value: String)
            case unknownPersonInMatch(value: String)
        }
        
        let title: String
        let persons: [Transport.Person]
        let nights: [Transport.MatchingNight]
        let matches: [Transport.Match]
        
        public static func game(fromData data: Data) throws -> ayto_solver.Game {
            let decoder = JSONDecoder()
            
            let transportGame = try decoder.decode(Transport.Game.self, from: data)
            return try transportGame.game()
        }
        
        internal func game() throws -> ayto_solver.Game {
            let persons = try self.persons.map { try $0.person() }
            let matchingNights: [ayto_solver.MatchingNight] = try self.nights.map { data in
                let pairs: [Pair] = try data.pairs.map { pairData in
                    guard let person1 = persons.person(withName: pairData.person1) else {
                        throw Game.JSONError.unknownPersonInMatchingNight(value: pairData.person1)
                    }
                    
                    guard let person2 = persons.person(withName: pairData.person2) else {
                        throw Game.JSONError.unknownPersonInMatchingNight(value: pairData.person2)
                    }
                    
                    return Pair(person1, person2)
                }
                
                return ayto_solver.MatchingNight(title: data.title ?? "Matching Night",
                                                 pairs: pairs,
                                                 hits: data.hits)
            }
            
            let matches: [ayto_solver.Match] = try self.matches.map { data in
                guard let person1 = persons.person(withName: data.person1) else {
                    throw Game.JSONError.unknownPersonInMatch(value: data.person1)
                }
                
                guard let person2 = persons.person(withName: data.person2) else {
                    throw Game.JSONError.unknownPersonInMatch(value: data.person2)
                }
                
                if data.match {
                    return ayto_solver.Match.match(person1, person2)
                } else {
                    return ayto_solver.Match.noMatch(person1, person2)
            }}
            
            return ayto_solver.Game(title: self.title, persons:persons, knownMatches: matches, nights: matchingNights)
        }
    }
    
}
