import Foundation
import ayto_solver
import Logging

var logger = Logger(label: "com.danielkbx.ayto")
logger.logLevel = .debug

//let kathleen = Person(regularPerson: "Kathleen", gender: .female)
//let aurelia = Person(regularPerson: "Aurelia", gender: .female)
//let steffi = Person(regularPerson: "Steffi", gender: .female)
//let jacky = Person(regularPerson: "Jacky", gender: .female)
//let walentina = Person(regularPerson: "Walentina", gender: .female)
//let sara = Person(regularPerson: "Sara", gender: .female)
//let jill = Person(regularPerson: "Jill", gender: .female)
//let finnja = Person(regularPerson: "Finnja", gender: .female)
//let jules = Person(regularPerson: "Jules", gender: .female)
//let melina = Person(regularPerson: "Melina", gender: .female)
//let vanessa = Person(extraPerson: "Vanessa", gender: .female)
//let diogo = Person(regularPerson: "Diogo", gender: .male)
//let salvatore = Person(regularPerson: "Salvatore", gender: .male)
//let tommy = Person(regularPerson: "Tommy", gender: .male)
//let manuel = Person(regularPerson: "Manuel", gender: .male)
//let josua = Person(regularPerson: "Josua", gender: .male)
//let alex = Person(regularPerson: "Alex", gender: .male)
//let eugen = Person(regularPerson: "Eugen", gender: .male)
//let danilo = Person(regularPerson: "Danilo", gender: .male)
//let francesco = Person(regularPerson: "Francesco", gender: .male)
//let jamy = Person(regularPerson: "Jamy", gender: .male)
//
//let persons: [Person] = [kathleen, aurelia, steffi, jacky, walentina, sara, jill, finnja, jules, melina, vanessa,
//                         diogo, salvatore, tommy, manuel, josua, alex, eugen, danilo, francesco, jamy]
//
//var knownMatches: [Match] = [
//    Match.match(jules, francesco),
//]
//
//let nights: [MatchingNight] = [
//    MatchingNight(pairs: [
//        Pair(steffi, danilo),
//        Pair(jill, jamy),
//        Pair(melina, tommy),
//        Pair(aurelia, diogo),
//        Pair(walentina, eugen),
//        Pair(kathleen, manuel),
//        Pair(finnja, francesco),
//        Pair(jacky, salvatore),
//        Pair(sara, josua),
//        Pair(jules, alex)
//    ], hits: 3)
//]
//
//let game = Game(persons: persons, knownMatches: knownMatches, nights: nights)

let fileUrl = URL(fileURLWithPath: "/Users/daniel/Projekte/ayto/ayto/ayto/season2.json")
let data = try Data(contentsOf: fileUrl)

let game = try Transport.Game.game(fromData: data)

do {
    let solution = try game.solve(logger: logger)
    
    for night in game.matchingNights {
        print(night.title)
        print("---------------------")
        night.pairs.forEach {
            let indicator: String
            if let match = game.knownMatches.matches(with: $0).first {
                indicator = match.isMatch ? "✅" : "❌"
            } else {
                indicator = "🔵"
            }
            print(" \(indicator) \($0.person1.name) - \($0.person2.name)")
        }
        print("---------------------")
        print("\(night.hits) hits\n\n")
    }
    
    print("Solution (\(solution.matches.count) matches):")
    for match in solution.matches {
        print("- \(match.pair.person(with: .female).name) & \(match.pair.person(with: .male).name)")
    }
    
} catch {
    
}

