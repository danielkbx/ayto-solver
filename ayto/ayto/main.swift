import Foundation
import ayto_solver
import Logging

var logger = Logger(label: "com.danielkbx.ayto")
logger.logLevel = .debug

let kathleen = Person(regularPerson: "Kathleen", gender: .female)
let aurelia = Person(regularPerson: "Aurelia", gender: .female)
let steffi = Person(regularPerson: "Steffi", gender: .female)
let jacky = Person(regularPerson: "Jacky", gender: .female)
let walentina = Person(regularPerson: "Walentina", gender: .female)
let sara = Person(regularPerson: "Sara", gender: .female)
let jill = Person(regularPerson: "Jill", gender: .female)
let finnja = Person(regularPerson: "Finnja", gender: .female)
let jules = Person(regularPerson: "Jules", gender: .female)
let melina = Person(regularPerson: "Melina", gender: .female)
let vanessa = Person(extraPerson: "Vanessa", gender: .female)
let diogo = Person(regularPerson: "Diogo", gender: .male)
let salvatore = Person(regularPerson: "Salvatore", gender: .male)
let tommy = Person(regularPerson: "Tommy", gender: .male)
let manuel = Person(regularPerson: "Manuel", gender: .male)
let josua = Person(regularPerson: "Josua", gender: .male)
let alex = Person(regularPerson: "Alex", gender: .male)
let eugen = Person(regularPerson: "Eugen", gender: .male)
let danilo = Person(regularPerson: "Danilo", gender: .male)
let francesco = Person(regularPerson: "Francesco", gender: .male)
let jamy = Person(regularPerson: "Jamy", gender: .male)

let persons: [Person] = [kathleen, aurelia, steffi, jacky, walentina, sara, jill, finnja, jules, melina, vanessa,
                         diogo, salvatore, tommy, manuel, josua, alex, eugen, danilo, francesco, jamy]

var knownMatches: [Match] = [
    Match.match(jules, francesco),
    Match.match(josua, aurelia),
    Match.noMatch(melina, tommy)
]

let nights: [MatchingNight] = [
    MatchingNight(pairs: [
        Pair(kathleen, manuel),
        Pair(aurelia, diogo),
        Pair(steffi, danilo),
        Pair(jacky, salvatore),
        Pair(walentina, eugen),
        Pair(sara, josua),
        Pair(jill, jamy),
        Pair(finnja, francesco),
        Pair(jules, alex),
        Pair(melina, tommy)
    ], hits: 3)
]

let game = Game(persons: persons, knownMatches: knownMatches, nights: nights)

let solution = game.solve(logger: logger)

for i in 0 ..< nights.count {
    let night = nights[i]
    print("Night \(i+1)")
    print("---------------------")
    night.pairs.forEach {
        let indicator: String
        if $0.isImpossible(by: solution.matches) {
            indicator = "❌"
        } else if $0.isMatch(by: solution.matches) {
            indicator = "✅"
        } else {
            indicator = "🔵"
        }
        print(" \(indicator) \($0.person1.name) - \($0.person2.name)")
    }
    print("---------------------")
    print("\(night.hits) hits\n\n")
}

print("Solution:")
for match in solution.matches.filter({ $0.isMatch }) {
    print("- \(match.pair.person1.name) & \(match.pair.person2.name)")
}
