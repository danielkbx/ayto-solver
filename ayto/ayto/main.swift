import Foundation
import ayto_solver
import Logging

func indicator(forMatch match: Match?) -> String {
    guard let match = match else { return "" }
    switch match.isMatch {
    case true: return "✓"
    case false: return "-"
    }
}

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
        let nightTable = Table()
        print("\(night.title), \(night.hits) hits")
        for (index, pair) in night.pairs.enumerated() {
            let person1 = pair.person(with: .female)
            let person2 = try pair.not(person: person1)
            nightTable.set(value: person1.name, at: (x: 0, y: index))
            nightTable.set(value: person2.name, at: (x: 1, y: index))
            
            let match = game.knownMatches.matches(with: pair).first
            nightTable.set(value: indicator(forMatch: match), at: (x:2, y: index))
            
        }
        print(nightTable.stringValue())
    }
    
//    print("Solution (\(solution.matches.count) matches):")
//    for match in solution.matches {
//        print("- \(match.pair.person(with: .female).name) & \(match.pair.person(with: .male).name)")
//    }
    
    var columns = game.persons.with(gender: .male).sorted(by: { $0.name < $1.name })
    columns += game.persons.with(gender: .male).with(role: .extra).sorted(by: { $0.name < $1.name })
    var rows = game.persons.with(gender: .female).with(role: .regular).sorted(by: { $0.name < $1.name })
    rows += game.persons.with(gender: .female).with(role: .extra).sorted(by: { $0.name < $1.name })
    
    let table = Table()
        
    for (indexM, columnPerson) in columns.enumerated() {
        for (indexF, rowPerson) in rows.enumerated() {
            if let match = game.knownMatches.matches(with: columnPerson, and: rowPerson).first {
                table.set(value: match.isMatch ? "✓" : "-", at: (x: indexM, y: indexF))
            }
        }
    }
    
    let columnCaptions = columns.map { $0.role == .extra ? "\($0.name) (E)" : $0.name }
    let rowCaptions = rows.map { $0.role == .extra ? "\($0.name) (E)" : $0.name }
    print("\nFinal Matrix:")
    print(table.stringValue(header: Table.Captions(columns: columnCaptions, rows: rowCaptions)))
    
    print("\nSolution (\(solution.matches.count) matches), took \(solution.calculationLoops) loops:")
    let matchesTable = Table()
    for (index, match) in solution.matches.enumerated() {
        let person1 = match.pair.person(with: .female)
        let person2 = try match.pair.not(person: person1)
        matchesTable.set(value: person1.name, at: (x:0, y: index))
        matchesTable.set(value: person2.name, at: (x:1, y: index))
    }
    print(matchesTable.stringValue())
    
} catch {
    
}


